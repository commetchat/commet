import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/pages/settings/categories/account/security/matrix/session/matrix_session.dart';
import 'package:flutter/material.dart';
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
  List<Device>? devices;

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
    });
  }

  void getDevices() async {
    var gotDevices = await widget.client.getMatrixClient().getDevices();

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
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
          child: crossSigningPanel(),
        ),
        sessionsPanel()
      ],
    );
  }

  Panel sessionsPanel() {
    return Panel(
      header: "Sessions",
      mode: TileType.surfaceLow2,
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
        header: "Cross Signing & Backup",
        mode: TileType.surfaceLow2,
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
        const Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tiamat.Text.label("Cross Signing"),
              tiamat.Text.labelLow(
                  "Setup to verify and keep track of all your sessions")
            ],
          ),
        ),
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
            child: crossSigningEnabled
                ? tiamat.Button.danger(
                    text: "Reset",
                    onTap: () => AdaptiveDialog.show(context,
                        builder: (_) => MatrixCrossSigningPage(
                              client: widget.client,
                              mode: MatrixCrossSigningMode.resetCrossSigning,
                              onComplete: checkState,
                            ),
                        dismissible: true,
                        title: "Reset Cross Signing"),
                  )
                : tiamat.Button.secondary(
                    text: "Enable",
                    onTap: () => AdaptiveDialog.show(context,
                        builder: (_) => MatrixCrossSigningPage(
                              client: widget.client,
                              onComplete: checkState,
                            ),
                        dismissible: true,
                        title: "Cross Signing"),
                  )),
      ],
    );
  }

  Widget messageBackup() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tiamat.Text.label("Message Backup"),
              tiamat.Text.labelLow(
                  "Maintains a backup of your message history, in case you lose all your sessions. Your messages will be encrypted before uploading")
            ],
          ),
        ),
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
            child: messageBackupEnabled == true
                ? tiamat.Button.secondary(
                    text: "Restore",
                    onTap: () => AdaptiveDialog.show(context,
                        builder: (_) => MatrixCrossSigningPage(
                              client: widget.client,
                              onComplete: checkState,
                              mode: MatrixCrossSigningMode.restoreBackup,
                            ),
                        dismissible: true,
                        title: "Restore Backup"),
                  )
                : messageBackupEnabled == false
                    ? tiamat.Button.secondary(
                        text: "Enable",
                        onTap: () => AdaptiveDialog.show(context,
                            builder: (_) => MatrixCrossSigningPage(
                                  client: widget.client,
                                  onComplete: checkState,
                                  mode: MatrixCrossSigningMode.enableBackup,
                                ),
                            dismissible: true,
                            title: "Setup Backup"),
                      )
                    : const CircularProgressIndicator())
      ],
    );
  }
}
