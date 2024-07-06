import 'package:commet/ui/atoms/code_block.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/services.dart' as services;
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:matrix/encryption.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

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
  m.TextEditingController passphraseConfirmController =
      m.TextEditingController();

  m.TextEditingController keyInputController = m.TextEditingController();

  String copyBackupCodeText = CommonStrings.promptCopy;

  String get promptWipeMatrixKeys => Intl.message("Wipe Keys",
      desc: "Text on the button to wipe matrix encryption keys",
      name: "promptWipeMatrixKeys");

  String get promptAbortWipingMatrixKeys => Intl.message("Wait, No!",
      desc: "Text on the button which aborts wiping matrix encryption keys",
      name: "promptAbortWipingMatrixKeys");

  String get promptGenerateMatrixRecoveryKey => Intl.message("Generate Key",
      desc: "Button text to generate a recovery key",
      name: "promptGenerateMatrixRecoveryKey");

  String get labelMatrixRecoveryKeyCreateExplanation => Intl.message(
      "We need to set a security key, which can be used to access message history. We can either generate a key for you, or you can choose your own security phrase",
      desc:
          "Explains what the matrix recovery key does, and that it can be generated or user input",
      name: "labelMatrixRecoveryKeyCreateExplanation");

  String get promptSetMatrixPassphrase => Intl.message("Set Phrase",
      desc: "Button text to set a passphrase",
      name: "promptSetMatrixPassphrase");

  String get promptUseExistingMatrixKeys => Intl.message("Use Existing Keys",
      desc: "Button text to opt to use existing keys",
      name: "promptUseExistingMatrixKeys");

  String get promptCreateNewMatrixKeys => Intl.message("No, create new keys",
      desc: "Button text to opt to create new keys",
      name: "promptCreateNewMatrixKeys");

  String get promptWipeMatrixBackup => Intl.message("Wipe backup",
      desc: "Button text to wipe the matrix message backup",
      name: "promptWipeMatrixBackup");

  String get promptEnableMatrixBackup => Intl.message("Enable backup",
      desc: "Button text to enable to encrypted message backup",
      name: "promptEnableMatrixBackup");

  String get labelExistingMatrixKeysFound => Intl.message(
      "Existing signing keys have been found!",
      desc:
          "Text that is shown when the user is setting up cross signing, but has existing keys",
      name: "labelExistingMatrixKeysFound");

  String get labelAskUseExistingMatrixKeys => Intl.message(
      "Would you like to use the existing keys?",
      desc:
          "Text that is shown when the user is setting up cross signing, but has existing keys and asks the user if they would like to use those keys",
      name: "labelAskUseExistingMatrixKeys");

  String get labelMatrixRecoveryKeyExplanation => Intl.message(
      "This is your recovery key. You can use it to verify your session if you lose access to all other sessions. Keep it somewhere secure!",
      desc: "Gives a brief description about the function on the recovery key",
      name: "labelMatrixRecoveryKeyExplanation");

  String get labelMatrixRecoveryKeyPromptExplanation => Intl.message(
      "To unlock your old messages, please enter your recovery key that has been generated in a previous session. Your recovery key is NOT your password.",
      name: "labelMatrixRecoveryKeyPromptExplanation",
      desc:
          "Shown when a user is attempting to recover their old messages, explains that they need the recovery key");

  String get promptMatrixRecoveryKeyInput => Intl.message("Recovery key",
      desc: "Placeholder text for the recovery key input box",
      name: "promptMatrixRecoveryKeyInput");

  String get promptConfirmWipingCrossSigningKeys =>
      Intl.message("Are you sure you want to wipe your cross signing keys?",
          desc: "Asks the user if they are sure they want to wipe the keys",
          name: "promptConfirmWipingCrossSigningKeys");

  String get labelMatrixSecurityPhraseShouldNotBePassword => Intl.message(
      "Your security phrase should be different to your account password",
      desc: "Tells the user to not use their password as their security phrase",
      name: "labelMatrixSecurityPhraseShouldNotBePassword");

  String get errorMatrixPassphraseMustContainUpperAndLowercase => Intl.message(
      "Passphrase must contain atleast 1 Uppercase and 1 Lowercase letter",
      desc: "Explains constraints of recovery passphrase",
      name: "errorMatrixPassphraseMustContainUpperAndLowercase");

  String get errorMatrixPassphraseMustContainNumber =>
      Intl.message("Passphrase must contain atleast 1 number",
          desc: "Explains constraints of recovery passphrase",
          name: "errorMatrixPassphraseMustContainNumber");

  String get errorMatrixPassphraseMustContainSymbol =>
      Intl.message("Passphrase must contain atleast 1 symbol",
          desc: "Explains constraints of recovery passphrase",
          name: "errorMatrixPassphraseMustContainSymbol");

  String get erroMatrixPassphraseMustBeLonger =>
      Intl.message("Passphrase must be atleast 10 characters long",
          desc: "Explains constraints of recovery passphrase",
          name: "erroMatrixPassphraseMustBeLonger");

  String get labelMatrixConfirmSecurityPhrase =>
      Intl.message("Confirm security phrase:",
          desc: "Prompts the user to input their passphrase again",
          name: "labelMatrixConfirmSecurityPhrase");

  String get placeholderMatrixConfirmSecurityPhrase =>
      Intl.message("Confirm security phrase",
          desc: "Placeholder text for the confirm passphrase text input",
          name: "placeholderMatrixConfirmSecurityPhrase");

  String get errorMatrixPassphrasesDontMatch => Intl.message(
      "Passphrases do not match",
      desc:
          "Error when the user enters passphrase twice and the two dont match",
      name: "errorMatrixPassphrasesDontMatch");

  String get labelMatrixPromptPassphrase => Intl.message("Security phrase:",
      desc: "Prompt the user to enter passphrase",
      name: "labelMatrixPromptPassphrase");

  String get placeholderMatrixEnterSecutiyPhrase =>
      Intl.message("Security phrase",
          desc: "Placeholder text for the passphrase text box",
          name: "placeholderMatrixEnterSecutiyPhrase");

  String get labelMatrixExistingMessageBackupFound =>
      Intl.message("Existing backup found!",
          desc: "Message to explain that existing backup has been found",
          name: "labelMatrixExistingMessageBackupFound");

  String get labelMatrixAskWipeBackupToContinue => Intl.message(
      "If you are changing your cross signing keys, you will need to wipe your existing backup... Continue?",
      desc:
          "Asks the user if they want to wipe their existing backup to continue changing their cross signing keys",
      name: "labelMatrixAskWipeBackupToContinue");

  String get labelMatrixWarnResetKeysIsPermanent => Intl.message(
      "Resetting your keys is permanent, and will result in a loss of your chat history backup. You almost definitely dont want to do this!",
      desc:
          "Explains that resetting keys is permanent, should emphasize that this isnt really a great idea",
      name: "labelMatrixWarnResetKeysIsPermanent");

  String get labelMatrixAskEnableMessageBackup =>
      Intl.message("Would you like to enable online key backup?",
          desc: "Asks the user if they want to enable online backup",
          name: "labelMatrixAskEnableMessageBackup");

  String get labelMatrixExplainOnlineKeyBackup => Intl.message(
      "Online key backup will allow you to retreive message history in the event that you lose access to all your sessions",
      desc: "Explains what the message backup does",
      name: "labelMatrixExplainOnlineKeyBackup");

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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
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
        // ignore: todo
        // TODO: Handle this case.
        break;
      case BootstrapState.askBadSsss:
        // ignore: todo
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
    return tiamat.Text.label(widget.state.toString());
  }

  Widget askSetupCrossSigning() {
    return m.Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        m.Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tiamat.Text.label(labelMatrixRecoveryKeyExplanation),
            const SizedBox(height: 8),
            m.SelectionArea(
              child: Codeblock(
                text: widget.recoveryKey!,
              ),
            ),
            const SizedBox(height: 8),
            tiamat.Button.secondary(
                text: copyBackupCodeText,
                onTap: () {
                  services.Clipboard.setData(
                      services.ClipboardData(text: widget.recoveryKey!));
                  setState(() {
                    copyBackupCodeText = CommonStrings.promptCopyComplete;
                  });
                }),
          ],
        ),
        const SizedBox(
          height: 50,
        ),
        tiamat.Button(
            text: CommonStrings.promptConfirm,
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
              tiamat.Text.label(labelMatrixRecoveryKeyPromptExplanation),
              const SizedBox(height: 8),
              tiamat.TextInput(
                placeholder: promptMatrixRecoveryKeyInput,
                controller: keyInputController,
                obscureText: true,
              )
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          tiamat.Button(
              text: CommonStrings.promptConfirm,
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
              tiamat.Text.label(promptConfirmWipingCrossSigningKeys),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
          const SizedBox(
            height: 50,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                child: tiamat.Button.danger(
                  text: promptWipeMatrixKeys,
                  onTap: () => widget.wipeCrossSigning?.call(true),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                  child: tiamat.Button.secondary(
                      text: promptAbortWipingMatrixKeys,
                      onTap: () => widget.wipeCrossSigning?.call(false)))
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
          tiamat.Text.body(labelMatrixRecoveryKeyCreateExplanation),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 40,
                child: tiamat.Button(
                  text: promptGenerateMatrixRecoveryKey,
                  onTap: () => widget.onSetNewSsss?.call(null),
                ),
              ),
            ],
          ),
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
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: tiamat.Text.label(
                    labelMatrixSecurityPhraseShouldNotBePassword),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
                child: tiamat.Text.labelLow(labelMatrixPromptPassphrase),
              ),
              tiamat.TextInput(
                controller: passphraseController,
                placeholder: placeholderMatrixEnterSecutiyPhrase,
                obscureText: true,
              ),
              if (passphraseValidity == NewPasswordResult.noMixedCase)
                tiamat.Text.error(
                    errorMatrixPassphraseMustContainUpperAndLowercase),
              if (passphraseValidity == NewPasswordResult.noNumbers)
                tiamat.Text.error(errorMatrixPassphraseMustContainNumber),
              if (passphraseValidity == NewPasswordResult.noSymbols)
                tiamat.Text.error(errorMatrixPassphraseMustContainSymbol),
              if (passphraseValidity == NewPasswordResult.tooShort)
                tiamat.Text.error(erroMatrixPassphraseMustBeLonger),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
                child: tiamat.Text.labelLow(labelMatrixConfirmSecurityPhrase),
              ),
              tiamat.TextInput(
                controller: passphraseConfirmController,
                obscureText: true,
                placeholder: placeholderMatrixConfirmSecurityPhrase,
              ),
              if (passphrasesMatch == false)
                tiamat.Text.error(errorMatrixPassphrasesDontMatch),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 40,
                      child: tiamat.Button(
                        text: promptSetMatrixPassphrase,
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

  Widget loading() {
    return const m.SizedBox(
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
              tiamat.Text.label(labelExistingMatrixKeysFound),
              const SizedBox(
                height: 20,
              ),
              tiamat.Text.label(labelAskUseExistingMatrixKeys),
            ],
          ),
          const SizedBox(
            height: 50,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                child: tiamat.Button(
                  text: promptUseExistingMatrixKeys,
                  onTap: () => widget.useExistingKeys?.call(true),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                  child: tiamat.Button.secondary(
                      text: promptCreateNewMatrixKeys,
                      onTap: () => widget.useExistingKeys?.call(false)))
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
            tiamat.Text.label(labelAskUseExistingMatrixKeys),
            const SizedBox(
              height: 20,
            ),
            tiamat.Text.label(labelMatrixWarnResetKeysIsPermanent),
          ],
        ),
        const SizedBox(
          height: 50,
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
                width: 200,
                child: tiamat.Button(
                    text: promptUseExistingMatrixKeys,
                    onTap: () => widget.wipeSsss?.call(false))),
            const SizedBox(
              height: 10,
            ),
            SizedBox(
              width: 200,
              child: tiamat.Button.danger(
                text: promptWipeMatrixKeys,
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
            tiamat.Text.label(labelMatrixAskEnableMessageBackup),
            const SizedBox(
              height: 20,
            ),
            tiamat.Text.label(labelMatrixExplainOnlineKeyBackup),
          ],
        ),
        const SizedBox(
          height: 50,
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 200,
              child: tiamat.Button(
                text: promptEnableMatrixBackup,
                onTap: () => widget.onAskSetupOnlineBackup?.call(true),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            SizedBox(
                width: 200,
                child: tiamat.Button.secondary(
                    text: CommonStrings.promptPoliteNo,
                    onTap: () => widget.onAskSetupOnlineBackup?.call(false)))
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
          const m.Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(
                child: m.Icon(
              m.Icons.verified_user_rounded,
              color: m.Colors.green,
              size: 100,
            )),
          ),
          tiamat.Button.success(
            text: CommonStrings.promptDone,
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
          const m.Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(
                child: m.Icon(
              m.Icons.error,
              color: m.Colors.red,
              size: 100,
            )),
          ),
          tiamat.Button.secondary(
            text: CommonStrings.promptBack,
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
            tiamat.Text.label(labelMatrixExistingMessageBackupFound),
            const SizedBox(
              height: 20,
            ),
            tiamat.Text.label(labelMatrixAskWipeBackupToContinue),
          ],
        ),
        const SizedBox(
          height: 50,
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 200,
              child: tiamat.Button.danger(
                text: promptWipeMatrixBackup,
                onTap: () => widget.wipeExistingBackup?.call(true),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            SizedBox(
                width: 200,
                child: tiamat.Button.secondary(
                    text: CommonStrings.promptPoliteNo,
                    onTap: () => widget.wipeExistingBackup?.call(false)))
          ],
        )
      ],
    );
  }
}
