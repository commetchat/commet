import 'package:commet/client/auth.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/custom_uri.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import 'package:universal_html/html.dart' as html;
import 'package:matrix/matrix.dart' as matrix;

class MatrixSSOLoginFlow implements SsoLoginFlow {
  @override
  String? id;
  String? brand;

  @override
  ImageProvider<Object>? icon;

  @override
  String name;

  MatrixSSOLoginFlow({this.id, required this.name, this.icon, this.brand});

  factory MatrixSSOLoginFlow.fromJson(
          MatrixClient client, Map<String, dynamic> json) =>
      MatrixSSOLoginFlow(
        id: json['id'],
        name: json['name'],
        icon: json['icon'] != null
            ? getLoginFlowImage(
                Uri.parse(
                  json['icon'],
                ),
                client,
              )
            : null,
        brand: json['brand'],
      );

  static NetworkImage getLoginFlowImage(Uri mxc, MatrixClient client) {
    var path =
        '_matrix/media/v3/thumbnail/${Uri.encodeComponent(mxc.authority)}/${Uri.encodeComponent(mxc.pathSegments.first)}';

    var server = client.getMatrixClient().baseUri!;
    var request =
        server.replace(path: path, query: "width=96&height=96&method=crop");
    return NetworkImage(request.toString());
  }

  @override
  Future<LoginResult> submit(Client client) async {
    if (client is! MatrixClient) {
      return LoginResult.error;
    }

    try {
      var mx = client.getMatrixClient();

      String redirectUrl = SsoLoginUri().toString();

      if (PlatformUtils.isWeb) {
        redirectUrl = Uri.parse(html.window.location.href)
            .resolve("auth.html")
            .toString();
      }

      String callbackScheme = Uri.parse(redirectUrl).scheme;

      // https://github.com/ThexXTURBOXx/flutter_web_auth_2/blob/2b67cb9674c7d3228de4f5728a73b09ae6598cf9/flutter_web_auth_2/README.md#windows-and-linux
      if (PlatformUtils.isLinux || PlatformUtils.isWindows) {
        redirectUrl = "http://localhost:3001/login";
        callbackScheme = "http://localhost:3001";
      }

      final url = mx.homeserver!.replace(
        path:
            '/_matrix/client/v3/login/sso/redirect${id == null ? '' : '/$id'}',
        queryParameters: {'redirectUrl': redirectUrl},
      );

      final result = await FlutterWebAuth2.authenticate(
          url: url.toString(),
          callbackUrlScheme: callbackScheme,
          options: FlutterWebAuth2Options(useWebview: false));

      var token = Uri.parse(result).queryParameters['loginToken'];
      if (token?.isEmpty ?? false) {
        return LoginResult.failed;
      }

      var login = await mx.login(
        matrix.LoginType.mLoginToken,
        token: token,
      );

      if (login.accessToken.isNotEmpty) {
        return LoginResult.success;
      } else {
        return LoginResult.failed;
      }
    } catch (e, t) {
      Log.onError(e, t);
      // I didn't spell this wrong, its just like that in flutter_web_auth_2
      if (e is PlatformException && e.code == "CANCELED") {
        return LoginResult.cancelled;
      }
      return LoginResult.error;
    }
  }
}
