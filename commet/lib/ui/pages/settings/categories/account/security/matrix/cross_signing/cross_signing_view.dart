import 'package:commet/generated/l10n.dart';
import 'package:commet/ui/atoms/code_block.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/services.dart' as services;
import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:matrix/encryption.dart';
import 'package:tiamat/tiamat.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import 'cross_signing_page.dart';

@WidgetbookUseCase(name: 'Ask Setup Cross Signing', type: MatrixCrossSigningView)
@Deprecated("widgetbook")
Widget wbCrossSigningViewAskSetup(BuildContext context) {
  return m.Scaffold(
    body: PopupDialog(
      title: "Cross Signing",
      content: MatrixCrossSigningView(
        BootstrapState.askSetupCrossSigning,
        recoveryKey: "EsTg 2wVy h9WT YXon x7ze 8zJ4 v4HX d4s3 D1WR n73k 2mct gsW9",
      ),
    ),
  );
}

@WidgetbookUseCase(name: 'Loading', type: MatrixCrossSigningView)
@Deprecated("widgetbook")
Widget wbCrossSigningViewLoading(BuildContext context) {
  return m.Scaffold(
    body: PopupDialog(
      title: "Cross Signing",
      content: MatrixCrossSigningView(
        BootstrapState.loading,
        recoveryKey: "EsTg 2wVy h9WT YXon x7ze 8zJ4 v4HX d4s3 D1WR n73k 2mct gsW9",
      ),
    ),
  );
}

@WidgetbookUseCase(name: 'Ask New Ssss', type: MatrixCrossSigningView)
@Deprecated("widgetbook")
Widget wbCrossSigningAskNewSsss(BuildContext context) {
  return m.Scaffold(
    body: PopupDialog(
      title: "Cross Signing",
      content: MatrixCrossSigningView(
        BootstrapState.askNewSsss,
        recoveryKey: "EsTg 2wVy h9WT YXon x7ze 8zJ4 v4HX d4s3 D1WR n73k 2mct gsW9",
      ),
    ),
  );
}

@WidgetbookUseCase(name: 'Ask Setup online backup', type: MatrixCrossSigningView)
@Deprecated("widgetbook")
Widget wbCrossSigningaskSetupOnlineKeyBackup(BuildContext context) {
  return m.Scaffold(
    body: PopupDialog(
      title: "Cross Signing",
      content: MatrixCrossSigningView(
        BootstrapState.askSetupOnlineKeyBackup,
        recoveryKey: "EsTg 2wVy h9WT YXon x7ze 8zJ4 v4HX d4s3 D1WR n73k 2mct gsW9",
      ),
    ),
  );
}

@WidgetbookUseCase(name: 'Ask Use Existing Ssss', type: MatrixCrossSigningView)
@Deprecated("widgetbook")
Widget wbCrossSigningaskUseExistingSsss(BuildContext context) {
  return m.Scaffold(
    body: PopupDialog(
      title: "Cross Signing",
      content: MatrixCrossSigningView(
        BootstrapState.askUseExistingSsss,
        recoveryKey: "EsTg 2wVy h9WT YXon x7ze 8zJ4 v4HX d4s3 D1WR n73k 2mct gsW9",
      ),
    ),
  );
}

class MatrixCrossSigningView extends StatefulWidget {
  const MatrixCrossSigningView(this.state,
      {super.key,
      this.onSetNewSsss,
      this.onAskSetupCrossSigning,
      this.recoveryKey,
      this.onAskSetupOnlineBackup,
      this.useExistingKeys,
      this.wipeSsss,
      this.wipeExistingBackup,
      this.openExistingSsss,
      this.wipeCrossSigning});
  final BootstrapState state;

  final Function(String?)? onSetNewSsss;
  final Function()? onAskSetupCrossSigning;
  final Function(bool)? onAskSetupOnlineBackup;
  final Function(bool)? useExistingKeys;
  final Function(bool)? wipeSsss;
  final Function(bool)? wipeExistingBackup;
  final Function(String)? openExistingSsss;
  final Function(bool)? wipeCrossSigning;
  final String? recoveryKey;
  @override
  State<MatrixCrossSigningView> createState() => _MatrixCrossSigningViewState();
}

class _MatrixCrossSigningViewState extends State<MatrixCrossSigningView> {
  NewPasswordResult? passphraseValidity;
  bool? passphrasesMatch;
  m.TextEditingController passphraseController = m.TextEditingController();
  m.TextEditingController passphraseConfirmController = m.TextEditingController();

  m.TextEditingController keyInputController = m.TextEditingController();

  String copyBackupCodeText = "Copy";

  @override
  void initState() {
    passphraseController.addListener(() {
      setState(() {
        passphraseValidity = TextUtils.isValidPassword(passphraseController.text,
            forceDigits: true, forceLength: 10, forceSpecialCharacter: true);
      });
    });

    passphraseConfirmController.addListener(() {
      setState(() {
        passphrasesMatch = passphraseConfirmController.text == passphraseController.text;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 500, maxHeight: 500),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: showState(),
      ),
    );
  }

  Widget showState() {
    switch (widget.state) {
      case BootstrapState.loading:
        return loading();
      case BootstrapState.askWipeSsss:
        return askWipeSsss();
      case BootstrapState.askUseExistingSsss:
        return askUseExistingSsss();
      case BootstrapState.askUnlockSsss:
        // TODO: Handle this case.
        break;
      case BootstrapState.askBadSsss:
        // TODO: Handle this case.
        break;
      case BootstrapState.askNewSsss:
        return askNewSsss();
      case BootstrapState.openExistingSsss:
        return openExistingSsss();
      case BootstrapState.askWipeCrossSigning:
        return askWipeCrossSigning();
      case BootstrapState.askSetupCrossSigning:
        return askSetupCrossSigning();
      case BootstrapState.askWipeOnlineKeyBackup:
        return askWipeOnlineKeybackup();
      case BootstrapState.askSetupOnlineKeyBackup:
        return askSetupOnlineKeyBackup();
      case BootstrapState.error:
        return error(context);
      case BootstrapState.done:
        return done(context);
    }
    return Text.label(widget.state.toString());
  }

  Widget askSetupCrossSigning() {
    return m.Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        m.Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.label(
                "This is your recovery key. You can use it to verify your session if you lose access to all other sessions. Keep it somewhere secure!"),
            SizedBox(height: 8),
            m.SelectionArea(
              child: Codeblock(
                text: widget.recoveryKey!,
              ),
            ),
            SizedBox(height: 8),
            Button.secondary(
                text: copyBackupCodeText,
                onTap: () {
                  services.Clipboard.setData(services.ClipboardData(text: widget.recoveryKey!));
                  setState(() {
                    copyBackupCodeText = "Copied!";
                  });
                }),
          ],
        ),
        SizedBox(
          height: 50,
        ),
        Button(
            text: "Confirm",
            onTap: () {
              widget.onAskSetupCrossSigning?.call();
            })
      ],
    );
  }

  Widget openExistingSsss() {
    return SizedBox(
      width: 400,
      child: m.Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          m.Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text.label(
                  "To unlock your old messages, please enter your recovery key that has been generated in a previous session. Your recovery key is NOT your password."),
              SizedBox(height: 8),
              TextInput(
                placeholder: "Recovery Key",
                controller: keyInputController,
                obscureText: true,
              )
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Button(
              text: "Confirm",
              onTap: () {
                widget.openExistingSsss?.call(keyInputController.text);
              })
        ],
      ),
    );
  }

  Widget askWipeCrossSigning() {
    return m.SizedBox(
      width: 500,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          m.Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.label("Are you sure you want to wipe your cross signing keys?"),
              SizedBox(
                height: 10,
              ),
            ],
          ),
          SizedBox(
            height: 50,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                child: Button.danger(
                  text: "Wipe Keys",
                  onTap: () => widget.wipeCrossSigning?.call(true),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              SizedBox(child: Button.secondary(text: "Wait, No!", onTap: () => widget.wipeCrossSigning?.call(false)))
            ],
          )
        ],
      ),
    );
  }

  Widget askNewSsss() {
    return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.body(
              "We need to set a security key, which can be used to access message history. We can either generate a key for you, or you can choose your own security phrase"),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 40,
                child: Button(
                  text: "Generate Key",
                  onTap: () => widget.onSetNewSsss?.call(null),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              SizedBox(
                width: 100,
                height: 10,
                child: Seperator(),
              ),
              Text.labelLow("Or"),
              SizedBox(
                width: 100,
                height: 10,
                child: Seperator(),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text.label("Your security phrase should be different to your account password"),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
                child: Text.labelLow("Security phrase:"),
              ),
              TextInput(
                controller: passphraseController,
                placeholder: "Security phrase",
                obscureText: true,
              ),
              if (passphraseValidity == NewPasswordResult.noMixedCase)
                Text.error("Passphrase must contain atleast 1 Uppercase and 1 Lowercase letter"),
              if (passphraseValidity == NewPasswordResult.noNumbers)
                Text.error("Passphrase must contain atleast 1 number"),
              if (passphraseValidity == NewPasswordResult.noSymbols)
                Text.error("Passphrase must contain atleast 1 symbol"),
              if (passphraseValidity == NewPasswordResult.tooShort)
                Text.error("Passphrase must be atleast 10 characters long"),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
                child: Text.labelLow("Confirm security phrase:"),
              ),
              TextInput(
                controller: passphraseConfirmController,
                obscureText: true,
                placeholder: "Confirm security phrase",
              ),
              if (passphrasesMatch == false) Text.error("Passphrases do not match"),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 40,
                      child: Button(
                        text: "Set Phrase",
                        onTap: () {
                          if (passphraseValidity == NewPasswordResult.valid && passphrasesMatch == true) {
                            widget.onSetNewSsss?.call(passphraseController.text);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ]);
  }

  Widget loading() {
    return m.SizedBox(
      width: 500,
      height: 200,
      child: Center(
        child: m.CircularProgressIndicator(),
      ),
    );
  }

  Widget askUseExistingSsss() {
    return m.SizedBox(
      width: 500,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          m.Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.label("Existing signing keys have been found!"),
              SizedBox(
                height: 20,
              ),
              Text.label("Would you like to continue using the existing keys?"),
            ],
          ),
          SizedBox(
            height: 50,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                child: Button(
                  text: "Use Existing Keys",
                  onTap: () => widget.useExistingKeys?.call(true),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              SizedBox(
                  child:
                      Button.secondary(text: "No, create new keys", onTap: () => widget.useExistingKeys?.call(false)))
            ],
          )
        ],
      ),
    );
  }

  Widget askWipeSsss() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        m.Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.label("Existing keys found, would you like to reset?"),
            SizedBox(
              height: 20,
            ),
            Text.label(
                "Resetting your keys is permanent, and will result in a loss of your chat history backup. You almost definitely dont want to do this!"),
          ],
        ),
        SizedBox(
          height: 50,
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
                width: 200,
                child: Button(text: "Continue with existing keys", onTap: () => widget.wipeSsss?.call(false))),
            SizedBox(
              height: 10,
            ),
            SizedBox(
              width: 200,
              child: Button.danger(
                text: "Wipe Keys",
                onTap: () => widget.wipeSsss?.call(true),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget askSetupOnlineKeyBackup() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        m.Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.label("Would you like to enable online key backup?"),
            SizedBox(
              height: 20,
            ),
            Text.label(
                "Online key backup will allow you to retreive message history in the event that you lose access to all your sessions"),
          ],
        ),
        SizedBox(
          height: 50,
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 200,
              child: Button(
                text: "Enable Backup",
                onTap: () => widget.onAskSetupOnlineBackup?.call(true),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            SizedBox(
                width: 200,
                child: Button.secondary(text: "No, thanks", onTap: () => widget.onAskSetupOnlineBackup?.call(false)))
          ],
        )
      ],
    );
  }

  Widget done(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          m.Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
                child: m.Icon(
              m.Icons.verified_user_rounded,
              color: m.Colors.green,
              size: 100,
            )),
          ),
          Button.success(
            text: "Done",
            onTap: () => m.Navigator.pop(context),
          )
        ]);
  }

  Widget error(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          m.Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
                child: m.Icon(
              m.Icons.error,
              color: m.Colors.red,
              size: 100,
            )),
          ),
          Button.secondary(
            text: "Go Back",
            onTap: () => m.Navigator.pop(context),
          )
        ]);
  }

  Widget askWipeOnlineKeybackup() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        m.Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.label("Existing backup found!"),
            SizedBox(
              height: 20,
            ),
            Text.label(
                "If you are changing your cross signing keys, you will need to wipe your existing backup... Continue?"),
          ],
        ),
        SizedBox(
          height: 50,
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 200,
              child: Button.danger(
                text: "Wipe Backup",
                onTap: () => widget.wipeExistingBackup?.call(true),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            SizedBox(
                width: 200,
                child: Button.secondary(text: "No, thanks", onTap: () => widget.wipeExistingBackup?.call(false)))
          ],
        )
      ],
    );
  }
}
