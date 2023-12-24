import 'dart:ui';

import 'package:commet/client/client.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/ui/atoms/shader/star_trails.dart';
import 'package:commet/ui/pages/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/atoms/circle_button.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

@UseCase(name: 'Login Page', type: LoginPageView)
@Deprecated("widgetbook")
Widget wbLoginPage(BuildContext context) {
  return const LoginPageView();
}

class LoginPageView extends StatefulWidget {
  const LoginPageView({this.state, super.key, this.canNavigateBack = false});
  final LoginPageState? state;
  final bool canNavigateBack;

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

  String get promptHomeserver => Intl.message("Homeserver",
      name: "promptHomeserver",
      desc: "Placeholder text for homeserver field on login form");

  String get promptUsername => Intl.message("Username",
      name: "promptUsername",
      desc: "Placeholder text for username field on login form");

  String get promptPassword => Intl.message("Password",
      name: "promptPassword",
      desc: "Placeholder text for password field on login form");

  String get promptSubmitLogin => Intl.message("Login",
      name: "promptSubmitLogin",
      desc: "Prompt to submit the username and password, and attempt to login");

  void doLogin() async {
    setState(() {
      _loading = true;
    });

    LoginResult result = await widget.state!.login(_homeserverTextField.text,
        _usernameTextField.text, _passwordTextField.text);

    setState(() {
      _loading = false;
    });

    String? message;

    switch (result) {
      case LoginResult.success:
        break;
      case LoginResult.failed:
        message = messageLoginFailed;
        break;
      case LoginResult.error:
        message = messageLoginError;
        break;
      case LoginResult.alreadyLoggedIn:
        message = messageAlreadyLoggedIn;
        break;
    }

    if (message != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: const StarTrailsBackground(),
            ),
            Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    loginField(context),
                    info(),
                  ],
                ),
              ),
            ),
            if (widget.canNavigateBack)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                    alignment: Alignment.topLeft,
                    child: CircleButton(
                      radius: 25,
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.of(context).pop(),
                    )),
              ),
          ],
        ),
      ),
    );
  }

  Widget info() {
    return Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const tiamat.Text.label(BuildConfig.VERSION_TAG),
              const tiamat.Text.label(" · "),
              tiamat.Text.label(BuildConfig.GIT_HASH.substring(0, 7)),
            ],
          ),
        ));
  }

  Widget loginField(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).extension<ExtraColors>()!.surfaceLow1,
              border: Border.all(
                  color: Theme.of(context).extension<ExtraColors>()!.outline,
                  width: 1),
              boxShadow: [
                BoxShadow(
                    blurRadius: 50,
                    color: Theme.of(context).shadowColor.withAlpha(50))
              ]),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  appIcon(context),
                  const SizedBox(
                    width: 8,
                  ),
                  appName(),
                ],
              ),
              const SizedBox(height: 16),
              homeserverEntry(),
              const SizedBox(height: 16),
              usernameEntry(),
              const SizedBox(height: 16),
              passwordEntry(),
              const SizedBox(height: 16),
              loginButton(),
            ]),
          ),
        ),
      ),
    );
  }

  Text appName() {
    return const Text(
      "Commet",
      style: TextStyle(fontFamily: 'Jellee', fontSize: 30),
    );
  }

  SizedBox loginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: tiamat.Button(
        isLoading: _loading,
        text: promptSubmitLogin,
        onTap: doLogin,
      ),
    );
  }

  TextField passwordEntry() {
    return TextField(
      autocorrect: false,
      controller: _passwordTextField,
      obscureText: true,
      readOnly: _loading,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: promptPassword,
      ),
    );
  }

  TextField usernameEntry() {
    return TextField(
      autocorrect: false,
      controller: _usernameTextField,
      readOnly: _loading,
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp("[ ]"))],
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: promptUsername,
      ),
    );
  }

  TextField homeserverEntry() {
    return TextField(
      autocorrect: false,
      controller: _homeserverTextField,
      readOnly: _loading,
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp("[ ]"))],
      decoration: InputDecoration(
        prefixText: 'https://',
        border: const OutlineInputBorder(),
        labelText: promptHomeserver,
      ),
    );
  }

  SizedBox appIcon(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: SvgPicture.asset(
        "assets/images/app_icon/icon.svg",
        theme: SvgTheme(currentColor: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }
}
