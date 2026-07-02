import 'package:commet/client/alert.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/molecules/alert_view.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/pages/settings/categories/account/security/matrix/session/matrix_session.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:commet/utils/links/link_utils.dart';
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
  bool isVerified = false;
  List<Device>? devices;

  Map<String, Object?>? authMetadata;

  Uri? get accountManagementUri {
    var str = authMetadata?.tryGet<String>("account_management_uri");
    if (str == null) return null;
    return Uri.tryParse(str);
  }

  List<String>? get supportedActions =>
      authMetadata?.tryGetList<String>("account_management_actions_supported");

  bool get canRemoveDeviceOAuth =>
      supportedActions?.contains("org.matrix.device_delete") == true &&
      accountManagementUri != null;

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
    super.initState();
  }

  void checkState() {
    setState(() {
      var encryption = widget.client.getMatrixClient().encryption;
      crossSigningEnabled = encryption?.crossSigning.enabled ?? false;
      messageBackupEnabled = encryption?.keyManager.enabled ?? false;
      isVerified = widget.client.matrixClient.isUnknownSession == false;
    });
  }

  void getDevices() async {
    var gotDevices = await widget.client.getMatrixClient().getDevices();

    if (authMetadata == null) {
      try {
        authMetadata = await widget.client.matrixClient
            .request(RequestType.GET, "/client/v1/auth_metadata");
      } catch (e, s) {
        Log.onError(e, s);
      }
    }

    gotDevices
        ?.sort((a, b) => (b.lastSeenTs ?? 0).compareTo(a.lastSeenTs ?? 0));

    if (mounted)
      setState(() {
        devices = gotDevices;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      spacing: 4,
      children: [crossSigningPanel(), sessionsPanel()],
    );
  }

  Panel sessionsPanel() {
    return Panel(
      header: labelMatrixAccountSessions,
      mode: TileType.surfaceContainerLow,
      child: devices == null
          ? SizedBox(
              height: 300,
              child: Center(child: const CircularProgressIndicator()))
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                var device = devices![index];
                return Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: MatrixSession(
                    device,
                    widget.client.getMatrixClient(),
                    removeSession: canRemoveDeviceOAuth
                        ? () async {
                            LinkUtils.open(
                                accountManagementUri!.replace(queryParameters: {
                                  "action": "org.matrix.device_delete",
                                  "device_id": device.deviceId
                                }),
                                context: context,
                                filterTrackingParameters: false,
                                bypassConfirmation: false);
                          }
                        : null,
                  ),
                );
              },
              itemCount: devices!.length,
            ),
    );
  }

  void onUpdated() {
    setState(() {
      getDevices();
    });
  }

  Panel crossSigningPanel() {
    return Panel(
        header: labelMatrixCrossSigningAndBackup,
        mode: TileType.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Column(
            spacing: 4,
            children: [
              if (!isVerified)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                  child: Container(
                    decoration: BoxDecoration(
                        color: ColorScheme.of(context).surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: AlertView(Alert(AlertType.warning,
                          messageGetter: () =>
                              "Your current session is not verified. You will not be able to participate in encrypted chats.",
                          titleGetter: () => "Unverified")),
                    ),
                  ),
                ),
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
}
