import 'dart:async';

import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/debug/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;
import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class MatrixRoomChatPrivacySettings extends StatefulWidget {
  const MatrixRoomChatPrivacySettings(this.room);

  final MatrixRoom room;

  @override
  State<MatrixRoomChatPrivacySettings> createState() =>
      _MatrixRoomChatPrivacySettingsState();
}

class _MatrixRoomChatPrivacySettingsState
    extends State<MatrixRoomChatPrivacySettings> {
  bool? globalPrivateReadReceipts;
  bool? globalPrivateTypingIndicator;
  bool? privateReadReceipts;
  bool? privateTypingIndicator;

  String get labelEnabledOption => Intl.message("Enabled",
      desc: "Label for an enabled value", name: "labelEnabledOption");

  String get labelDisabledOption => Intl.message("Disabled",
      desc: "Label for an disabled value", name: "labelDisabledOption");

  String labelDefaultOption(pref) => Intl.message("Use global preference $pref",
      desc: "Label to use the global preference",
      name: "labelOptionDefault",
      args: [pref]);

  String get labelPrivateReadReceiptsTitle => Intl.message(
      "Private read receipts",
      desc:
          "Label for the toggle for enabling and disabling private read receipts",
      name: "labelPrivateReadReceiptsToggle");

  String get labelPrivateTypingIndicatorTitle => Intl.message(
      "Private typing indicator",
      desc:
          "Label for the toggle for enabling and disabling private typing indicator",
      name: "labelPrivateTypingIndicatorTitle");

  @override
  void initState() {
    getChatPrivacy();
    super.initState();
  }

  Future<void> getChatPrivacy() async {
    var client = widget.room.client as MatrixClient;
    var prr = await client.matrixClient
        .getAccountData(
            client.matrixClient.userID!, MatrixClient.privateReadReceiptsKey)
        .catchError((e) {
      if (!(e is MatrixException && e.error == MatrixError.M_NOT_FOUND))
        Log.e(e);
      return {"enabled": null};
    });
    var pti = await client.matrixClient
        .getAccountData(
            client.matrixClient.userID!, MatrixClient.privateTypingIndicatorKey)
        .catchError((e) {
      if (!(e is MatrixException && e.error == MatrixError.M_NOT_FOUND))
        Log.e(e);
      return {"enabled": null};
    });
    var rprr = await client
        .getRoomAccountData(client.matrixClient.userID!,
            widget.room.matrixRoom.id, MatrixClient.privateReadReceiptsKey)
        .catchError((e) {
      if (!(e is MatrixException && e.error == MatrixError.M_NOT_FOUND))
        Log.e(e);
      return {"enabled": null};
    });
    var rpti = await client
        .getRoomAccountData(client.matrixClient.userID!,
            widget.room.matrixRoom.id, MatrixClient.privateTypingIndicatorKey)
        .catchError((e) {
      if (!(e is MatrixException && e.error == MatrixError.M_NOT_FOUND))
        Log.e(e);
      return {"enabled": null};
    });

    setState(() {
      globalPrivateReadReceipts =
          prr["enabled"] is bool ? prr["enabled"] as bool : false;
      globalPrivateTypingIndicator =
          pti["enabled"] is bool ? pti["enabled"] as bool : false;
      privateReadReceipts =
          rprr["enabled"] is bool ? rprr["enabled"] as bool : null;
      privateTypingIndicator =
          rpti["enabled"] is bool ? rpti["enabled"] as bool : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      privateReadReceiptsSettings(),
      const SizedBox(
        height: 10,
      ),
      privateTypingIndicatorSettings(),
    ]);
  }

  Widget privateReadReceiptsSettings() {
    return tiamat.Panel(
        mode: tiamat.TileType.surfaceContainerLow,
        header: labelPrivateReadReceiptsTitle,
        child: material.Material(
          color: material.Colors.transparent,
          child: Column(
            children: [
              tiamat.RadioButton<bool?>(
                groupValue: privateReadReceipts,
                value: null,
                icon: material.Icons.remove_outlined,
                text: labelDefaultOption(globalPrivateReadReceipts is bool
                    ? (globalPrivateReadReceipts as bool
                        ? "($labelEnabledOption)"
                        : "($labelDisabledOption)")
                    : ""),
                onChanged: onPRRChanged,
              ),
              tiamat.RadioButton<bool?>(
                groupValue: privateReadReceipts,
                value: false,
                icon: material.Icons.close,
                text: labelDisabledOption,
                onChanged: onPRRChanged,
              ),
              tiamat.RadioButton<bool?>(
                groupValue: privateReadReceipts,
                value: true,
                icon: material.Icons.check,
                text: labelEnabledOption,
                onChanged: onPRRChanged,
              ),
            ],
          ),
        ));
  }

  Widget privateTypingIndicatorSettings() {
    return tiamat.Panel(
        mode: tiamat.TileType.surfaceContainerLow,
        header: labelPrivateTypingIndicatorTitle,
        child: material.Material(
          color: material.Colors.transparent,
          child: Column(
            children: [
              tiamat.RadioButton<bool?>(
                groupValue: privateTypingIndicator,
                value: null,
                icon: material.Icons.remove_outlined,
                text: labelDefaultOption(globalPrivateTypingIndicator is bool
                    ? (globalPrivateTypingIndicator as bool
                        ? "($labelEnabledOption)"
                        : "($labelDisabledOption)")
                    : ""),
                onChanged: onPTIChanged,
              ),
              tiamat.RadioButton<bool?>(
                groupValue: privateTypingIndicator,
                value: false,
                icon: material.Icons.close,
                text: labelDisabledOption,
                onChanged: onPTIChanged,
              ),
              tiamat.RadioButton<bool?>(
                groupValue: privateTypingIndicator,
                value: true,
                icon: material.Icons.check,
                text: labelEnabledOption,
                onChanged: onPTIChanged,
              ),
            ],
          ),
        ));
  }

  Future<void> onPRRChanged(bool? value) async {
    var client = widget.room.client as MatrixClient;
    client.setRoomAccountData(
      client.matrixClient.userID!,
      widget.room.identifier,
      MatrixClient.privateReadReceiptsKey,
      {"enabled": value},
    );
    setState(() => privateReadReceipts = value);
  }

  Future<void> onPTIChanged(bool? value) async {
    var client = widget.room.client as MatrixClient;
    client.setRoomAccountData(
      client.matrixClient.userID!,
      widget.room.identifier,
      MatrixClient.privateTypingIndicatorKey,
      {"enabled": value},
    );

    setState(() => privateTypingIndicator = value);
  }
}
