import 'package:commet/ui/atoms/code_block.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/services.dart' as services;
import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:matrix/encryption.dart';
import 'package:tiamat/tiamat.dart';

import 'cross_signing_page.dart';

class MatrixCrossSigningView extends StatefulWidget {
  const MatrixCrossSigningView(this.state,
      {super.key,
      this.onSetNewSsss,
      this.onAskSetupCrossSigning,
      this.recoveryKey});
  final BootstrapState state;

  final Function(String?)? onSetNewSsss;
  final Function()? onAskSetupCrossSigning;
  final String? recoveryKey;
  @override
  State<MatrixCrossSigningView> createState() => _MatrixCrossSigningViewState();
}

class _MatrixCrossSigningViewState extends State<MatrixCrossSigningView> {
  NewPasswordResult? passphraseValidity;
  bool? passphrasesMatch;
  m.TextEditingController passphraseController = m.TextEditingController();
  m.TextEditingController passphraseConfirmController =
      m.TextEditingController();

  String copyBackupCodeText = "Copy";

  @override
  void initState() {
    passphraseController.addListener(() {
      setState(() {
        passphraseValidity = TextUtils.isValidPassword(
            passphraseController.text,
            forceDigits: true,
            forceLength: 10,
            forceSpecialCharacter: true);
      });
    });

    passphraseConfirmController.addListener(() {
      setState(() {
        passphrasesMatch =
            passphraseConfirmController.text == passphraseController.text;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      height: 500,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: showState(),
      ),
    );
  }

  Widget showState() {
    switch (widget.state) {
      case BootstrapState.loading:
        // TODO: Handle this case.
        break;
      case BootstrapState.askWipeSsss:
        // TODO: Handle this case.
        break;
      case BootstrapState.askUseExistingSsss:
        // TODO: Handle this case.
        break;
      case BootstrapState.askUnlockSsss:
        // TODO: Handle this case.
        break;
      case BootstrapState.askBadSsss:
        // TODO: Handle this case.
        break;
      case BootstrapState.askNewSsss:
        return askNewSsss();
      case BootstrapState.openExistingSsss:
        // TODO: Handle this case.
        break;
      case BootstrapState.askWipeCrossSigning:
        // TODO: Handle this case.
        break;
      case BootstrapState.askSetupCrossSigning:
        return askSetupCrossSigning();
      case BootstrapState.askWipeOnlineKeyBackup:
        // TODO: Handle this case.
        break;
      case BootstrapState.askSetupOnlineKeyBackup:
        // TODO: Handle this case.
        break;
      case BootstrapState.error:
        // TODO: Handle this case.
        break;
      case BootstrapState.done:
        // TODO: Handle this case.
        break;
    }
    return Text.label(widget.state.toString());
  }

  Widget askSetupCrossSigning() {
    return m.Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            Button(
                text: copyBackupCodeText,
                onTap: () {
                  services.Clipboard.setData(
                      services.ClipboardData(text: widget.recoveryKey!));
                  setState(() {
                    copyBackupCodeText = "Copied!";
                  });
                }),
          ],
        ),
        Button(
            text: "Confirm",
            onTap: () {
              widget.onAskSetupCrossSigning?.call();
            })
      ],
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
                width: 200,
                height: 10,
                child: Seperator(),
              ),
              Text.labelLow("Or"),
              SizedBox(
                width: 200,
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
                child: Text.label(
                    "Your security phrase should be different to your account password"),
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
                Text.error(
                    "Passphrase must contain atleast 1 Uppercase and 1 Lowercase letter"),
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
              if (passphrasesMatch == false)
                Text.error("Passphrases do not match"),
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
                          if (passphraseValidity == NewPasswordResult.valid &&
                              passphrasesMatch == true) {
                            widget.onSetNewSsss
                                ?.call(passphraseController.text);
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
}
