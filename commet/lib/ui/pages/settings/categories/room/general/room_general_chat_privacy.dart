import 'dart:async';

import 'package:commet/client/components/read_receipts/read_receipt_component.dart';
import 'package:commet/client/components/typing_indicators/typing_indicator_component.dart';
import 'package:commet/client/components/user_presence/user_presence_component.dart';
import 'package:commet/client/room.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomGeneralChatPrivacySettings extends StatefulWidget {
  const RoomGeneralChatPrivacySettings(this.room);

  final Room room;

  @override
  State<RoomGeneralChatPrivacySettings> createState() =>
      _RoomGeneralChatPrivacySettings();
}

class _RoomGeneralChatPrivacySettings
    extends State<RoomGeneralChatPrivacySettings> {
  bool? publicReadReceiptsForRoom;
  bool? typingIndicatorEnabledForRoom;

  String get labelEnabledOption => Intl.message("Enabled",
      desc: "Label for an enabled value", name: "labelEnabledOption");

  String get labelDisabledOption => Intl.message("Disabled",
      desc: "Label for an disabled value", name: "labelDisabledOption");

  String labelDefaultOption(pref) => Intl.message("Use global preference $pref",
      desc: "Label to use the global preference",
      name: "labelOptionDefault",
      args: [pref]);

  String get labelPublicReadReceiptsTitle => Intl.message(
      "Public read receipts",
      desc:
          "Label for the toggle for enabling and disabling public read receipts",
      name: "labelPublicReadReceiptsTitle");

  String get labelPublicTypingIndicatorTitle => Intl.message(
      "Public typing indicator",
      desc:
          "Label for the toggle for enabling and disabling public typing indicator",
      name: "labelPublicTypingIndicatorTitle");

  @override
  void initState() {
    setState(() {
      publicReadReceiptsForRoom = widget.room
          .getComponent<ReadReceiptComponent>()!
          .usePublicReadReceiptsForRoom;
      typingIndicatorEnabledForRoom = widget.room
          .getComponent<TypingIndicatorComponent>()!
          .typingIndicatorEnabledForRoom;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      publicReadReceiptsSettings(),
      const SizedBox(
        height: 10,
      ),
      publicTypingIndicatorSettings(),
    ]);
  }

  Widget publicReadReceiptsSettings() {
    var usePublicReadReceipts = widget.room.client
        .getComponent<UserPresenceComponent>()!
        .usePublicReadReceipts;
    return tiamat.Panel(
        mode: tiamat.TileType.surfaceContainerLow,
        header: labelPublicReadReceiptsTitle,
        child: material.Material(
          color: material.Colors.transparent,
          child: Column(
            children: [
              tiamat.RadioButton<bool?>(
                groupValue: publicReadReceiptsForRoom,
                value: null,
                icon: material.Icons.remove_outlined,
                text: labelDefaultOption(usePublicReadReceipts
                    ? "($labelEnabledOption)"
                    : "($labelDisabledOption)"),
                onChanged: onReadReceiptPrefChanged,
              ),
              tiamat.RadioButton<bool?>(
                groupValue: publicReadReceiptsForRoom,
                value: false,
                icon: material.Icons.close,
                text: labelDisabledOption,
                onChanged: onReadReceiptPrefChanged,
              ),
              tiamat.RadioButton<bool?>(
                groupValue: publicReadReceiptsForRoom,
                value: true,
                icon: material.Icons.check,
                text: labelEnabledOption,
                onChanged: onReadReceiptPrefChanged,
              ),
            ],
          ),
        ));
  }

  Widget publicTypingIndicatorSettings() {
    var typingIndicatorEnabled = widget.room.client
        .getComponent<UserPresenceComponent>()!
        .typingIndicatorEnabled;
    return tiamat.Panel(
        mode: tiamat.TileType.surfaceContainerLow,
        header: labelPublicTypingIndicatorTitle,
        child: material.Material(
          color: material.Colors.transparent,
          child: Column(
            children: [
              tiamat.RadioButton<bool?>(
                groupValue: typingIndicatorEnabledForRoom,
                value: null,
                icon: material.Icons.remove_outlined,
                text: labelDefaultOption(typingIndicatorEnabled
                    ? "($labelEnabledOption)"
                    : "($labelDisabledOption)"),
                onChanged: onTypingIndicatorPrefChanged,
              ),
              tiamat.RadioButton<bool?>(
                groupValue: typingIndicatorEnabledForRoom,
                value: false,
                icon: material.Icons.close,
                text: labelDisabledOption,
                onChanged: onTypingIndicatorPrefChanged,
              ),
              tiamat.RadioButton<bool?>(
                groupValue: typingIndicatorEnabledForRoom,
                value: true,
                icon: material.Icons.check,
                text: labelEnabledOption,
                onChanged: onTypingIndicatorPrefChanged,
              ),
            ],
          ),
        ));
  }

  Future<void> onReadReceiptPrefChanged(bool? value) async {
    widget.room
        .getComponent<ReadReceiptComponent>()!
        .setUsePublicReadReceiptsForRoom(value);
    setState(() => publicReadReceiptsForRoom = value);
  }

  Future<void> onTypingIndicatorPrefChanged(bool? value) async {
    widget.room
        .getComponent<TypingIndicatorComponent>()!
        .setTypingIndicatorEnabledForRoom(value);
    setState(() => typingIndicatorEnabledForRoom = value);
  }
}
