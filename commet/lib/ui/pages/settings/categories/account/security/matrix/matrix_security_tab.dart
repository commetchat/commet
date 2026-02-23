import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/pages/settings/categories/account/security/matrix/session/matrix_session.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import 'cross_signing/cross_signing_page.dart';

class MatrixSecurityTab extends StatefulWidget {
  const MatrixSecurityTab(this.client, {super.key});
  final MatrixClient client;
  @override
  State<MatrixSecurityTab> createState() => _MatrixSecurityTabState();
}

class _MatrixSecurityTabState extends State<MatrixSecurityTab> {
  bool crossSigningEnabled = false;
  bool? messageBackupEnabled;
  bool privateReadReceipts = false;
  bool privateTypingIndicator = false;
  List<Device>? devices;

  String get labelChatPrivacyTitle => Intl.message("Chat Privacy",
      desc: "Header for the chat privacy section in settings",
      name: "labelChatPrivacyTitle");

  String get labelPrivateReadReceiptsToggle => Intl.message(
      "Private read receipts",
      desc:
          "Label for the toggle for enabling and disabling sending read receipts",
      name: "labelPrivateReadReceiptsToggle");

  String get labelPrivateReadReceiptsDescription => Intl.message(
      "Prevent other members of a room from knowing when you have read their messages.",
      desc:
          "description for the toggle for enabling and disabling sending read receipts",
      name: "labelPrivateReadReceiptsDescriptionn");

  String get labelPrivateTypingIndicatorToggle => Intl.message(
      "Private typing indicator",
      desc:
          "Label for the toggle for enabling and disabling sending typing indicator",
      name: "labelPrivateTypingIndicatorToggle");

  String get labelPrivateTypingIndicatorDescription => Intl.message(
      "Prevent other members of a room from knowing when you are typing a message.",
      desc:
          "description for the toggle for enabling and disabling sending typing indicator",
      name: "labelPrivateTypingIndicatorDescription");

  String get labelMatrixCrossSigning => Intl.message("Cross signing",
      desc: "Title label for matrix cross signing",
      name: "labelMatrixCrossSigning");

  String get labelMatrixCrossSigningAndBackup => Intl.message(
      "Cross Signing & Backup",
      desc: "Header label for matrix cross signing and message backup section",
      name: "labelMatrixCrossSigningAndBackup");

  String get labelMatrixAccountSessions => Intl.message("Sessions",
      desc: "Title label for account sessions",
      name: "labelMatrixAccountSessions");

  String get labelMatrixCrossSigningExplanation =>
      Intl.message("Setup to verify and keep track of all your sessions",
          desc: "Explains what matrix cross signing does",
          name: "labelMatrixCrossSigningExplanation");

  String get labelMatrixResetCrossSigningTitle =>
      Intl.message("Reset cross signing",
          desc: "Title for the popup dialog when resetting cross signing",
          name: "labelMatrixResetCrossSigningTitle");

  String get labelMatrixMessageBackup => Intl.message("Message backup",
      desc: "TItle label for matrix message backup settings",
      name: "labelMatrixMessageBackup");

  String get labelMatrixMessageBackupExplanation => Intl.message(
      "Maintains a backup of your message history, in case you lose all your sessions. Your messages will be encrypted before uploading",
      desc: "Explains what matrix message backup does",
      name: "labelMatrixMessageBackupExplanation");

  String get promptSetupMatrixMessageBackup => Intl.message("Setup backup",
      desc: "Text on the button to begin the setup process for message backup",
      name: "promptSetupMatrixMessageBackup");

  String get labelRestoreMatrixBackupTitle => Intl.message("Restore backup",
      desc: "Title of the popup dialog for restoring message backup",
      name: "labelRestoreMatrixBackupTitle");

  @override
  void initState() {
    checkState();
    getDevices();
    getChatPrivacy();
    super.initState();
  }

  void checkState() {
    setState(() {
      var encryption = widget.client.getMatrixClient().encryption;
      crossSigningEnabled = encryption?.crossSigning.enabled ?? false;
      messageBackupEnabled = encryption?.keyManager.enabled ?? false;
    });
  }

  void getDevices() async {
    var gotDevices = await widget.client.getMatrixClient().getDevices();

    gotDevices
        ?.sort((a, b) => (b.lastSeenTs ?? 0).compareTo(a.lastSeenTs ?? 0));

    if (mounted)
      setState(() {
        devices = gotDevices;
      });
  }

  void getChatPrivacy() async {
    var prr = await widget.client.matrixClient
        .getAccountData(widget.client.matrixClient.userID!,
            MatrixClient.privateReadReceiptsKey)
        .catchError((e) {
      if (!(e is MatrixException && e.error == MatrixError.M_NOT_FOUND))
        Log.e(e);
      return {"enabled": false};
    });
    var pti = await widget.client.matrixClient
        .getAccountData(widget.client.matrixClient.userID!,
            MatrixClient.privateTypingIndicatorKey)
        .catchError((e) {
      if (!(e is MatrixException && e.error == MatrixError.M_NOT_FOUND))
        Log.e(e);
      return {"enabled": false};
    });

    setState(() {
      privateReadReceipts =
          prr["enabled"] is bool ? prr["enabled"] as bool : false;
      privateTypingIndicator =
          pti["enabled"] is bool ? pti["enabled"] as bool : false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        const SizedBox(
          height: 4,
        ),
        chatPrivacyPanel(),
        const SizedBox(
          height: 4,
        ),
        crossSigningPanel(),
        const SizedBox(
          height: 4,
        ),
        sessionsPanel()
      ],
    );
  }

  Panel sessionsPanel() {
    return Panel(
      header: labelMatrixAccountSessions,
      mode: TileType.surfaceContainerLow,
      child: devices == null
          ? const CircularProgressIndicator()
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: MatrixSession(
                    devices![index],
                    widget.client.getMatrixClient(),
                    onUpdated: () {
                      setState(() {
                        getDevices();
                      });
                    },
                  ),
                );
              },
              itemCount: devices!.length,
            ),
    );
  }

  Panel crossSigningPanel() {
    return Panel(
        header: labelMatrixCrossSigningAndBackup,
        mode: TileType.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Column(
            children: [
              crossSigning(),
              const tiamat.Seperator(),
              messageBackup()
            ],
          ),
        ));
  }

  Widget crossSigning() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tiamat.Text.label(labelMatrixCrossSigning),
              tiamat.Text.labelLow(labelMatrixCrossSigningExplanation)
            ],
          ),
        ),
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
            child: crossSigningEnabled
                ? tiamat.Button.danger(
                    text: CommonStrings.promptReset,
                    onTap: () => AdaptiveDialog.show(context,
                        builder: (_) => MatrixCrossSigningPage(
                              client: widget.client,
                              mode: MatrixCrossSigningMode.resetCrossSigning,
                              onComplete: checkState,
                            ),
                        dismissible: true,
                        title: labelMatrixResetCrossSigningTitle),
                  )
                : tiamat.Button.secondary(
                    text: CommonStrings.promptEnable,
                    onTap: () => AdaptiveDialog.show(context,
                        builder: (_) => MatrixCrossSigningPage(
                              client: widget.client,
                              onComplete: checkState,
                            ),
                        dismissible: true,
                        title: labelMatrixCrossSigning),
                  )),
      ],
    );
  }

  Widget messageBackup() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tiamat.Text.label(labelMatrixMessageBackup),
              tiamat.Text.labelLow(labelMatrixMessageBackupExplanation)
            ],
          ),
        ),
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
            child: messageBackupEnabled == true
                ? tiamat.Button.secondary(
                    text: CommonStrings.promptRestore,
                    onTap: () => AdaptiveDialog.show(context,
                        builder: (_) => MatrixCrossSigningPage(
                              client: widget.client,
                              onComplete: checkState,
                              mode: MatrixCrossSigningMode.restoreBackup,
                            ),
                        dismissible: true,
                        title: labelRestoreMatrixBackupTitle),
                  )
                : messageBackupEnabled == false
                    ? tiamat.Button.secondary(
                        text: CommonStrings.promptEnable,
                        onTap: () => AdaptiveDialog.show(context,
                            builder: (_) => MatrixCrossSigningPage(
                                  client: widget.client,
                                  onComplete: checkState,
                                  mode: MatrixCrossSigningMode.enableBackup,
                                ),
                            dismissible: true,
                            title: promptSetupMatrixMessageBackup),
                      )
                    : const CircularProgressIndicator())
      ],
    );
  }

  Widget chatPrivacyPanel() {
    return Panel(
      header: labelChatPrivacyTitle,
      mode: TileType.surfaceContainerLow,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tiamat.Text.labelEmphasised(labelPrivateReadReceiptsToggle),
                    tiamat.Text.labelLow(labelPrivateReadReceiptsDescription)
                  ]),
              tiamat.Switch(
                state: privateReadReceipts,
                onChanged: (value) {
                  setState(() {
                    privateReadReceipts = value;
                    widget.client.matrixClient.setAccountData(
                        widget.client.matrixClient.userID!,
                        MatrixClient.privateReadReceiptsKey,
                        {"enabled": privateReadReceipts});
                    widget.client.matrixClient.receiptsPublicByDefault =
                        !privateReadReceipts;
                  });
                },
              )
            ],
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tiamat.Text.labelEmphasised(
                        labelPrivateTypingIndicatorToggle),
                    tiamat.Text.labelLow(labelPrivateTypingIndicatorDescription)
                  ]),
              tiamat.Switch(
                state: privateTypingIndicator,
                onChanged: (value) {
                  setState(() {
                    privateTypingIndicator = value;
                    widget.client.matrixClient.setAccountData(
                        widget.client.matrixClient.userID!,
                        MatrixClient.privateTypingIndicatorKey,
                        {"enabled": privateTypingIndicator});
                  });
                },
              )
            ],
          ),
        ),
      ]),
    );
  }
}
