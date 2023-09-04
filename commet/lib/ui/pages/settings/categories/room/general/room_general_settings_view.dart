import 'package:commet/client/client.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:flutter/material.dart' as material;

class RoomGeneralSettingsView extends StatelessWidget {
  const RoomGeneralSettingsView(
      {super.key, required this.pushRule, this.onPushRuleChanged});
  final PushRule pushRule;
  final void Function(PushRule? rule)? onPushRuleChanged;

  String get labelPushRuleNotifyAll => Intl.message("All Messages",
      desc: "Label for the push rule which notifies for all received messages",
      name: "labelPushRuleNotifyAll");

  String get labelPushRuleMentionsAndKeywords => Intl.message(
      "Mentions & Keywords",
      desc:
          "Label for the push rule which notifies only for keywords and mentions",
      name: "labelPushRuleMentionsAndKeywords");

  String get labelPushRuleNone => Intl.message("Mute",
      desc: "Label for the push rule which sends no notifications",
      name: "labelPushRuleNone");

  String get labelRoomSettingsNotifications => Intl.message("Notifications",
      desc: "Label for the notifications section in room settings",
      name: "labelRoomSettingsNotifications");

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [notificationSettings()],
    );
  }

  Widget notificationSettings() {
    return tiamat.Panel(
        mode: tiamat.TileType.surfaceLow2,
        header: labelRoomSettingsNotifications,
        child: material.Material(
          color: material.Colors.transparent,
          child: Column(
            children: [
              tiamat.RadioButton<PushRule>(
                groupValue: pushRule,
                value: PushRule.notify,
                icon: material.Icons.notifications_active_outlined,
                text: labelPushRuleNotifyAll,
                onChanged: onPushRuleChanged,
              ),
              tiamat.RadioButton<PushRule>(
                groupValue: pushRule,
                value: PushRule.mentionsOnly,
                icon: material.Icons.notification_important_outlined,
                text: labelPushRuleMentionsAndKeywords,
                onChanged: onPushRuleChanged,
              ),
              tiamat.RadioButton<PushRule>(
                groupValue: pushRule,
                value: PushRule.dontNotify,
                icon: material.Icons.notifications_off_outlined,
                text: labelPushRuleNone,
                onChanged: onPushRuleChanged,
              )
            ],
          ),
        ));
  }
}
