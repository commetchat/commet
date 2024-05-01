import 'dart:async';

import 'package:commet/client/auth.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/login/login_page_view.dart';
import 'package:commet/utils/debounce.dart';
import 'package:commet/utils/rng.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.onSuccess, this.canNavigateBack = false});
  final bool canNavigateBack;
  final Function(Client loggedInClient)? onSuccess;

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  String get messageLoginFailed => Intl.message("Login Failed...",
      name: "messageLoginFailed",
      desc: "Generic text to show that an attempted login has failed");

  String get messageLoginError => Intl.message("An error occured",
      name: "messageLoginError",
      desc:
          "A generic error message to convey that an error occured when attempting to login");

  String get messageAlreadyLoggedIn => Intl.message(
        "You have already logged in to this account",
        name: "messageAlreadyLoggedIn",
        desc:
            "An error message displayed when the user attempts to add an account which has already been logged in to on this device",
      );

  StreamSubscription? progressSubscription;
  double? progress;
  List<LoginFlow>? loginFlows;
  late Client loginClient;

  final Debouncer homeserverUpdateDebouncer =
      Debouncer(delay: const Duration(seconds: 1));

  bool loadingServerInfo = false;
  bool isServerValid = false;
  bool isLoggingIn = false;

  @override
  void initState() {
    var internalId = RandomUtils.getRandomString(20);
    loginClient = MatrixClient(identifier: internalId);

    progressSubscription = loginClient.connectionStatusChanged.stream
        .listen(onLoginProgressChanged);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LoginPageView(
      canNavigateBack: widget.canNavigateBack,
      progress: progress,
      updateHomeserver: (value) {
        setState(() {
          loginFlows = null;
          isServerValid = false;
          loadingServerInfo = true;
        });
        homeserverUpdateDebouncer.run(() => updateHomeserver(value));
      },
      flows: loginFlows,
      doSsoLogin: doSsoLogin,
      doPasswordLogin: doPasswordLogin,
      isLoggingIn: isLoggingIn,
      loadingServerInfo: loadingServerInfo,
      hasSsoSupport: loginFlows?.whereType<SsoLoginFlow>().isNotEmpty == true,
      isServerValid: isServerValid,
    );
  }

  Future<void> doLogin(Future<LoginResult> Function() login) async {
    if (isServerValid == false) {
      return;
    }

    setState(() {
      isLoggingIn = true;
    });
    LoginResult result = LoginResult.error;
    try {
      result = await login();
    } catch (_) {}

    if (result != LoginResult.success) {
      setState(() {
        isLoggingIn = false;
      });
    }

    String? message = switch (result) {
      LoginResult.success => null,
      LoginResult.failed => messageLoginFailed,
      LoginResult.error => messageLoginError,
      LoginResult.alreadyLoggedIn => messageAlreadyLoggedIn,
      LoginResult.cancelled => "Login cancelled"
    };

    if (message != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      }
    }

    if (result == LoginResult.success) {
      clientManager?.addClient(loginClient);
      widget.onSuccess?.call(loginClient);
    }
  }

  Future<void> doSsoLogin(SsoLoginFlow flow) async {
    await doLogin(() => loginClient.executeLoginFlow(flow));
  }

  Future<void> doPasswordLogin(
      PasswordLoginFlow flow, String username, String password) async {
    flow.username = username;
    flow.password = password;

    await doLogin(() => loginClient.executeLoginFlow(flow));
  }

  void onLoginProgressChanged(ClientConnectionStatusUpdate event) {
    setState(() {
      progress = event.progress;
    });
  }

  Future<void> updateHomeserver(String input) async {
    setState(() {
      loginFlows = null;
      loadingServerInfo = true;
      isServerValid = false;
    });

    var uri = Uri.https(input);
    var result = await loginClient.setHomeserver(uri);

    setState(() {
      loadingServerInfo = false;
      isServerValid = result.$1;
      loginFlows = result.$2;
    });
  }
}
