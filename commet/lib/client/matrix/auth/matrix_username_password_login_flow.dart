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
    if (username == null || password == null) {
      return LoginResult.failed;
    }

    if (client is! MatrixClient) {
      return LoginResult.failed;
    }

    var mx = client.getMatrixClient();
    var result = LoginResult.error;

    try {
      var response = await mx.login(matrix.LoginType.mLoginPassword,
          initialDeviceDisplayName: BuildConfig.appName,
          password: password,
          identifier: matrix.AuthenticationUserIdentifier(user: username!));

      result = response.accessToken.isNotEmpty
          ? LoginResult.success
          : LoginResult.failed;
    } catch (exception) {
      result = LoginResult.error;

      if (exception is matrix.MatrixException) {
        if (exception.errcode == "M_USER_DEACTIVATED")
          result = LoginResult.userDeactivated;
        else if (_containsWordUsernameOrPassword(exception.errorMessage))
          result = LoginResult.invalidUsernameOrPassword;
      }
    }

    return result;
  }

  /// returns true if the text contains 'username' or 'password' case insensitive
  bool _containsWordUsernameOrPassword(String? text) {
    if (text == null) return false;
    final String lowercaseText = text.toLowerCase();
    return (lowercaseText.contains('username') ||
        lowercaseText.contains('password'));
  }
}
