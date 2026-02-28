import 'dart:async';

import 'package:commet/client/components/read_receipts/read_receipt_component.dart';
import 'package:commet/client/components/typing_indicators/typing_indicator_component.dart';
import 'package:commet/client/components/user_presence/user_presence_component.dart';
import 'package:commet/client/room.dart';
import 'package:commet/utils/common_strings.dart';
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

  String labelDefaultReadReceiptsOption(pref) => Intl.message(
      "Use global preference ($pref)",
      desc:
          "Label to use the global preference, showing the current global preference value",
      name: "labelDefaultReadReceiptsOption",
      args: [pref]);

  String labelDefaultTypingIndicatorsOption(pref) => Intl.message(
      "Use global preference ($pref)",
      desc:
          "Label to use the global preference, showing the current global preference value",
      name: "labelDefaultTypingIndicatorsOption",
      args: [pref]);

  String get labelReadReceiptsTitle => Intl.message("Read receipts",
      desc:
          "Label for the toggle for enabling and disabling public read receipts",
      name: "labelReadReceiptsTitle");

  String get labelTypingIndicatorTitle => Intl.message("Typing indicators",
      desc: "Label for the toggle for enabling and disabling typing indicators",
      name: "labelTypingIndicatorTitle");

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
        header: labelReadReceiptsTitle,
        child: material.Material(
          color: material.Colors.transparent,
          child: Column(
            children: [
              tiamat.RadioButton<bool?>(
                groupValue: publicReadReceiptsForRoom,
                value: null,
                icon: material.Icons.remove_outlined,
                text: labelDefaultReadReceiptsOption(usePublicReadReceipts
                    ? CommonStrings.labelPublic
                    : CommonStrings.labelPrivate),
                onChanged: onReadReceiptPrefChanged,
              ),
              tiamat.RadioButton<bool?>(
                groupValue: publicReadReceiptsForRoom,
                value: false,
                icon: material.Icons.hide_source,
                text: CommonStrings.labelPrivate,
                onChanged: onReadReceiptPrefChanged,
              ),
              tiamat.RadioButton<bool?>(
                groupValue: publicReadReceiptsForRoom,
                value: true,
                icon: material.Icons.public,
                text: CommonStrings.labelPublic,
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
        header: labelTypingIndicatorTitle,
        child: material.Material(
          color: material.Colors.transparent,
          child: Column(
            children: [
              tiamat.RadioButton<bool?>(
                groupValue: typingIndicatorEnabledForRoom,
                value: null,
                icon: material.Icons.remove_outlined,
                text: labelDefaultTypingIndicatorsOption(typingIndicatorEnabled
                    ? CommonStrings.labelEnabled
                    : CommonStrings.labelDisabled),
                onChanged: onTypingIndicatorPrefChanged,
              ),
              tiamat.RadioButton<bool?>(
                groupValue: typingIndicatorEnabledForRoom,
                value: false,
                icon: material.Icons.close,
                text: CommonStrings.labelDisabled,
                onChanged: onTypingIndicatorPrefChanged,
              ),
              tiamat.RadioButton<bool?>(
                groupValue: typingIndicatorEnabledForRoom,
                value: true,
                icon: material.Icons.check,
                text: CommonStrings.labelEnabled,
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
