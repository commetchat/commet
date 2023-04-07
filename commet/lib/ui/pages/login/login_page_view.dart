import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/ui/pages/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../chat/chat_page.dart';

@WidgetbookUseCase(name: 'Login Page', type: LoginPageView)
@Deprecated("widgetbook")
Widget wbLoginPage(BuildContext context) {
  return const LoginPageView();
}

class LoginPageView extends StatefulWidget {
  const LoginPageView({this.state, super.key});
  final LoginPageState? state;

  @override
  State<LoginPageView> createState() => _LoginPageViewState();
}

class _LoginPageViewState extends State<LoginPageView> {
  final TextEditingController _homeserverTextField = TextEditingController(
    text: 'matrix.org',
  );
  final TextEditingController _usernameTextField = TextEditingController();
  final TextEditingController _passwordTextField = TextEditingController();

  bool _loading = false;

  void doLogin() async {
    setState(() {
      _loading = true;
    });

    var result = await widget.state?.login(_homeserverTextField.text, _usernameTextField.text, _passwordTextField.text);

    if (result == LoginResult.success) {
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => ChatPage(clientManager: Provider.of<ClientManager>(context))),
          (route) => false,
        );
      }
    }

    if (result == LoginResult.failed) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login Failed"),
          ),
        );
      }
    }

    if (result == LoginResult.error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("There was an error logging in"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).extension<ExtraColors>()!.surfaceLow4,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Theme.of(context).extension<ExtraColors>()!.outline, width: 1),
                  boxShadow: [BoxShadow(blurRadius: 50, color: Theme.of(context).shadowColor.withAlpha(50))]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Tile.low2(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
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
                          onPressed: doLogin,
                          child: _loading ? const LinearProgressIndicator() : const Text('Login'),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
