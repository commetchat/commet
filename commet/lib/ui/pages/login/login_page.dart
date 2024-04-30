import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/pages/login/login_page_view.dart';
import 'package:commet/utils/rng.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../client/client_manager.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.onSuccess, this.canNavigateBack = false});
  final bool canNavigateBack;
  final Function(Client loggedInClient)? onSuccess;

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  StreamSubscription? progressSubscription;
  double? progress;

  Future<LoginResult> login(String homeserverInput, String userNameInput,
      String passwordInput) async {
    var result = await _doLogin(userNameInput, homeserverInput, passwordInput);
    progressSubscription?.cancel();

    return result;
  }

  Future<LoginResult> _doLogin(String userNameInput, String homeserverInput,
      String passwordInput) async {
    try {
      final manager = Provider.of<ClientManager>(context, listen: false);

      if (manager.clients
          .where((element) =>
              element.self?.identifier == "@$userNameInput:$homeserverInput")
          .isNotEmpty) {
        return LoginResult.alreadyLoggedIn;
      }
      var internalId = RandomUtils.getRandomString(20);
      var client = MatrixClient(identifier: internalId);
      progressSubscription =
          client.connectionStatusChanged.stream.listen(onLoginProgressChanged);

      var result = await client.login(
          LoginType.loginPassword, userNameInput, homeserverInput.trim(),
          password: passwordInput);

      if (result == LoginResult.success) {
        manager.addClient(client);
        await client.init(false);
        widget.onSuccess?.call(client);
        return LoginResult.success;
      } else {
        return LoginResult.failed;
      }
    } catch (e, t) {
      Log.onError(e, t);
      Log.e(e.toString());
      Log.e(t.toString());
      return LoginResult.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoginPageView(
      state: this,
      canNavigateBack: widget.canNavigateBack,
      progress: progress,
    );
  }

  void onLoginProgressChanged(ClientConnectionStatusUpdate event) {
    setState(() {
      progress = event.progress;
    });
  }
}
