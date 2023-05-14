import 'package:commet/client/client.dart';
import 'package:flutter/widgets.dart';

import '../room/general/room_general_settings_view.dart';

class SpaceGeneralSettingsPage extends StatefulWidget {
  const SpaceGeneralSettingsPage({super.key, required this.space});
  final Space space;

  @override
  State<SpaceGeneralSettingsPage> createState() =>
      _SpaceGeneralSettingsPageState();
}

class _SpaceGeneralSettingsPageState extends State<SpaceGeneralSettingsPage> {
  late PushRule pushRule;

  @override
  void initState() {
    pushRule = widget.space.pushRule;
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

    widget.space.setPushRule(rule);
  }
}
