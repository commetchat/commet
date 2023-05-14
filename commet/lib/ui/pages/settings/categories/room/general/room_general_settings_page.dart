import 'package:commet/client/room.dart';
import 'package:commet/ui/pages/settings/categories/room/general/room_general_settings_view.dart';
import 'package:flutter/widgets.dart';

class RoomGeneralSettingsPage extends StatefulWidget {
  const RoomGeneralSettingsPage({super.key, required this.room});
  final Room room;
  @override
  State<RoomGeneralSettingsPage> createState() =>
      _RoomGeneralSettingsPageState();
}

class _RoomGeneralSettingsPageState extends State<RoomGeneralSettingsPage> {
  late PushRule pushRule;

  @override
  void initState() {
    pushRule = widget.room.pushRule;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RoomGeneralSettingsView(
      pushRule: pushRule,
      onPushRuleChanged: setPushRule,
    );
  }

  void setPushRule(PushRule? rule) {
    if (rule == null) return;

    setState(() {
      pushRule = rule;
    });

    widget.room.setPushRule(rule);
  }
}
