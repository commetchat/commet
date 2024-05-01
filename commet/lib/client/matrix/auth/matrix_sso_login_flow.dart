import 'package:commet/client/auth.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/debug/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import 'package:matrix/matrix.dart' as matrix;

class MatrixSSOLoginFlow implements SsoLoginFlow {
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
            ? MatrixMxcImage(Uri.parse(json['icon']), client.getMatrixClient())
            : null,
        brand: json['brand'],
      );

  @override
  Future<LoginResult> submit(Client client) async {
    if (client is! MatrixClient) {
      return LoginResult.error;
    }

    try {
      var mx = client.getMatrixClient();

      final url = mx.homeserver!.replace(
        path:
            '/_matrix/client/v3/login/sso/redirect${id == null ? '' : '/$id'}',
        queryParameters: {'redirectUrl': "http://localhost:3001/login"},
      );

      final result = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: "http://localhost:3001",
      );

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
