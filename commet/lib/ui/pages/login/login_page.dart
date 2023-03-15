import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/ui/pages/chat/chat_page.dart';
import 'package:commet/ui/pages/login/login_page_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../client/client_manager.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  Future<LoginResult> login(String homeserverInput, String userNameInput, String passwordInput) async {
    try {
      final manager = Provider.of<ClientManager>(context, listen: false);
      var client = MatrixClient();

      var result =
          await client.login(LoginType.loginPassword, userNameInput, homeserverInput.trim(), password: passwordInput);

      if (result == LoginResult.success) {
        manager.addClient(client);
        await client.init();
        return LoginResult.success;
      } else {
        return LoginResult.failed;
      }
    } catch (e) {
      return LoginResult.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoginPageView(
      state: this,
    );
  }
}
