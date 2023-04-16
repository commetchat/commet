import 'package:commet/client/matrix/matrix_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
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

  @override
  void initState() {
    crossSigningEnabled =
        widget.client.getMatrixClient().encryption?.crossSigning.enabled ??
            false;

    super.initState();
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
      ],
    );
  }

  Panel crossSigningPanel() {
    return Panel(
        header: "Cross Signing & Backup",
        mode: TileType.surfaceLow2,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Column(
            children: [crossSigning(), tiamat.Seperator(), messageBackup()],
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
              tiamat.Text.label("Cross Signing"),
              tiamat.Text.labelLow(
                  "Setup to verify and keep track of all your sessions")
            ],
          ),
        ),
        crossSigningEnabled
            ? tiamat.Button.danger(
                text: "Reset",
              )
            : tiamat.Button.secondary(
                text: "Enable",
                onTap: () => PopupDialog.show(context,
                    content: MatrixCrossSigningPage(client: widget.client),
                    barrierDismissible: true,
                    title: "Cross Signing"),
              )
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
              tiamat.Text.label("Message Backup"),
              tiamat.Text.labelLow(
                  "Maintains a backup of your message history, in case you lose all your sessions. Your messages will be encrypted before uploading")
            ],
          ),
        ),
        tiamat.Button.secondary(
          text: "Enable",
        )
      ],
    );
  }
}
