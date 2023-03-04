import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/ui/pages/chat_page.dart';
import 'package:commet/ui/pages/desktop_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:provider/provider.dart';

import '../../client/client.dart';
import '../../client/client_manager.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _homeserverTextField = TextEditingController(
    text: 'matrix.org',
  );
  final TextEditingController _usernameTextField = TextEditingController();
  final TextEditingController _passwordTextField = TextEditingController();

  bool _loading = false;

  void _tryLogin() async {
    try {
      final manager = Provider.of<ClientManager>(context, listen: false);
      var client = MatrixClient();

      print(_homeserverTextField.text);

      var result = await client.login(
          LoginType.loginPassword, _usernameTextField.text, _homeserverTextField.text.trim(),
          password: _passwordTextField.text);

      if (result == LoginResult.success) {
        manager.addClient(client);
        client.init();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ChatPage()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login Failed"),
          ),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        child: Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(50.0),
                child: AspectRatio(
                  aspectRatio: 1 / 1.3,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(13.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(128),
                            spreadRadius: 0,
                            blurRadius: 50,
                          )
                        ]),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),
                            TextField(
                              autocorrect: false,
                              controller: _homeserverTextField,
                              readOnly: _loading,
                              decoration: const InputDecoration(
                                prefixText: 'https://',
                                border: OutlineInputBorder(),
                                labelText: 'Homeserver',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              autocorrect: false,
                              controller: _usernameTextField,
                              readOnly: _loading,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Username',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              autocorrect: false,
                              controller: _passwordTextField,
                              obscureText: true,
                              readOnly: _loading,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Password',
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _tryLogin,
                                child: _loading ? const LinearProgressIndicator() : const Text('Login'),
                              ),
                            ),
                          ]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
