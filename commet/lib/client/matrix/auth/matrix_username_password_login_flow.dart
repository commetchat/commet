import 'package:commet/client/auth.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/config/build_config.dart';

import 'package:matrix/matrix.dart' as matrix;

class MatrixPasswordLoginFlow implements PasswordLoginFlow {
  @override
  String? password;

  @override
  String? username;

  @override
  Future<LoginResult> submit(Client client) async {
    if (username == null) {
      return LoginResultError("Enter a username");
    }

    if (password == null) {
      return LoginResultError("Enter a password");
    }

    if (client is! MatrixClient) {
      return LoginResultFailed();
    }

    var mx = client.getMatrixClient();
    LoginResult result = LoginResultError("An unknown error occurred");

    try {
      var response = await mx.login(matrix.LoginType.mLoginPassword,
          initialDeviceDisplayName: BuildConfig.appName,
          password: password,
          identifier: matrix.AuthenticationUserIdentifier(user: username!));

      if (response.accessToken.isNotEmpty) {
        result = LoginResultSuccess();
      } else {
        result = LoginResultFailed();
      }
    } on matrix.MatrixException catch (exception) {
      result = LoginResultError(exception.errorMessage);
    } catch (e) {
      result = LoginResultError(e.toString());
    }

    return result;
  }
}
