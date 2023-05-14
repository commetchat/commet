import 'package:commet/client/client.dart';
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:flutter/material.dart' as material;

class RoomGeneralSettingsView extends StatelessWidget {
  const RoomGeneralSettingsView(
      {super.key, required this.pushRule, this.onPushRuleChanged});
  final PushRule pushRule;
  final void Function(PushRule? rule)? onPushRuleChanged;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [notificationSettings()],
    );
  }

  Widget notificationSettings() {
    return tiamat.Panel(
        mode: tiamat.TileType.surfaceLow2,
        header: "Notifications",
        child: material.Material(
          color: material.Colors.transparent,
          child: Column(
            children: [
              tiamat.RadioButton<PushRule>(
                groupValue: pushRule,
                value: PushRule.notify,
                icon: material.Icons.notifications_active_outlined,
                text: "All Messages",
                onChanged: onPushRuleChanged,
              ),
              tiamat.RadioButton<PushRule>(
                groupValue: pushRule,
                value: PushRule.mentionsOnly,
                icon: material.Icons.notification_important_outlined,
                text: "Mentions & Keywords",
                onChanged: onPushRuleChanged,
              ),
              tiamat.RadioButton<PushRule>(
                groupValue: pushRule,
                value: PushRule.dontNotify,
                icon: material.Icons.notifications_off_outlined,
                text: "Mute",
                onChanged: onPushRuleChanged,
              )
            ],
          ),
        ));
  }
}
