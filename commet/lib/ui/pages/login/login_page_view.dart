import 'dart:ui';

import 'package:commet/client/auth.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/ui/atoms/shader/star_trails.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:commet/utils/link_utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/atoms/circle_button.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class LoginPageView extends StatefulWidget {
  const LoginPageView(
      {super.key,
      this.canNavigateBack = false,
      this.progress,
      this.flows,
      required this.isLoggingIn,
      this.homeserverChecked,
      this.doSsoLogin,
      this.doPasswordLogin,
      this.loadingServerInfo = false,
      this.isServerValid = false,
      this.hasSsoSupport = false,
      this.updateHomeserver});
  final bool canNavigateBack;
  final bool isLoggingIn;
  final bool? homeserverChecked;
  final double? progress;
  final List<LoginFlow>? flows;
  final bool loadingServerInfo;
  final bool isServerValid;
  final bool hasSsoSupport;
  final Future<void> Function(SsoLoginFlow flow)? doSsoLogin;
  final Future<void> Function(
          PasswordLoginFlow flow, String username, String password)?
      doPasswordLogin;

  final Function(String)? updateHomeserver;

  @override
  State<LoginPageView> createState() => _LoginPageViewState();
}

class _LoginPageViewState extends State<LoginPageView> {
  final TextEditingController _homeserverTextField = TextEditingController(
    text: 'matrix.org',
  );
  final TextEditingController _usernameTextField = TextEditingController();
  final TextEditingController _passwordTextField = TextEditingController();

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

  @override
  void initState() {
    if (_homeserverTextField.text != "") {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _onHomeserverTextUpdated();
      });
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: const StarTrailsBackground(),
          ),
          SafeArea(
            child: Stack(
              children: [
                Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Stack(
                        children: [
                          loginField(context),
                        ],
                      ),
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
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  0, 0, 0, MediaQuery.of(context).padding.bottom),
              child: info(),
            ),
          ),
        ],
      ),
    );
  }

  Widget info() {
    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const tiamat.Text.label(BuildConfig.VERSION_TAG),
          const tiamat.Text.label(" · "),
          tiamat.Text.label(BuildConfig.GIT_HASH.substring(0, 7)),
          const tiamat.Text.label(" · "),
          Text.rich(
            TextSpan(
                style: const TextStyle(decoration: TextDecoration.underline),
                text: "Source Code",
                recognizer: TapGestureRecognizer()
                  ..onTap = () => LinkUtils.open(
                      Uri.parse("https://github.com/commetchat/commet"))),
          ),
          const tiamat.Text.label(" · "),
          Text.rich(
            TextSpan(
                style: const TextStyle(decoration: TextDecoration.underline),
                text: "License",
                recognizer: TapGestureRecognizer()
                  ..onTap = () => LinkUtils.open(Uri.parse(
                      "https://github.com/commetchat/commet/blob/main/LICENSE"))),
          ),
        ],
      ),
    );
  }

  Widget loginField(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outline, width: 1),
                  boxShadow: [
                    BoxShadow(
                        blurRadius: 50,
                        color: Theme.of(context).shadowColor.withAlpha(50))
                  ]),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Stack(
                  children: [
                    IgnorePointer(
                      ignoring: widget.isLoggingIn,
                      child: AnimatedOpacity(
                          opacity: widget.isLoggingIn ? 0.5 : 1.0,
                          duration: Durations.short2,
                          child: loginInputs(context)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.isLoggingIn)
          const Center(
            child: CircularProgressIndicator(),
          )
      ],
    );
  }

  Widget loginInputs(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Flexible(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            appIcon(context),
          ],
        ),
      ),
      const SizedBox(height: 16),
      homeserverEntry(),
      const SizedBox(height: 16),
      usenamePasswordLoginInputs(),
      SizedBox(
        height: 15,
        child: Center(
          child: SizedBox(
            height: 5,
            child: widget.progress == null
                ? null
                : LinearProgressIndicator(
                    value: widget.progress,
                  ),
          ),
        ),
      ),
      if (widget.hasSsoSupport)
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 100,
                  height: 10,
                  child: tiamat.Seperator(),
                ),
                tiamat.Text.labelLow(CommonStrings.labelOr),
                const SizedBox(
                  width: 100,
                  height: 10,
                  child: tiamat.Seperator(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                children: widget.flows!
                    .whereType<SsoLoginFlow>()
                    .map((e) => tiamat.ImageButton(
                          placeholderText: e.name,
                          image: e.icon,
                          size: 40,
                          backgroundColor: Colors.white,
                          onTap: () => widget.doSsoLogin?.call(e),
                        ))
                    .toList(),
              ),
            )
          ],
        ),
    ]);
  }

  Column usenamePasswordLoginInputs() {
    return Column(
      children: [
        usernameEntry(),
        const SizedBox(height: 16),
        passwordEntry(),
        const SizedBox(height: 16),
        loginButton(),
      ],
    );
  }

  Text appName() {
    return const Text(
      "Commet",
      style: TextStyle(fontFamily: 'Jellee', fontSize: 30),
    );
  }

  SizedBox loginButton() {
    var flow = widget.flows?.whereType<PasswordLoginFlow>().firstOrNull;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: tiamat.Button(
        text: promptSubmitLogin,
        onTap: flow != null
            ? () => widget.doPasswordLogin
                ?.call(flow, _usernameTextField.text, _passwordTextField.text)
            : null,
      ),
    );
  }

  TextField passwordEntry() {
    return TextField(
      autocorrect: false,
      controller: _passwordTextField,
      obscureText: true,
      readOnly: widget.isLoggingIn,
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
      readOnly: widget.isLoggingIn,
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp("[ ]"))],
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: promptUsername,
      ),
    );
  }

  Widget homeserverEntry() {
    return TextField(
      autocorrect: false,
      controller: _homeserverTextField,
      readOnly: widget.isLoggingIn,
      onChanged: widget.updateHomeserver,
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp("[ ]"))],
      decoration: InputDecoration(
          prefixText: 'https://',
          border: const OutlineInputBorder(),
          labelText: promptHomeserver,
          suffix: homeserverEntrySuffix()),
    );
  }

  Widget homeserverEntrySuffix() {
    if (widget.loadingServerInfo) {
      return const SizedBox(
          width: 15,
          height: 15,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ));
    }

    return Icon(
      widget.isServerValid ? Icons.check : Icons.close,
      size: 15,
      color: widget.isServerValid ? Colors.greenAccent : Colors.redAccent,
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

  void _onHomeserverTextUpdated() {
    if (widget.updateHomeserver != null) {
      widget.updateHomeserver?.call(_homeserverTextField.text);
    }
  }
}
