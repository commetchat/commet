import 'package:commet/client/client.dart';
import 'package:commet/ui/pages/settings/categories/room/security/room_security_settings_view.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class RoomSecuritySettingsPage extends StatefulWidget {
  const RoomSecuritySettingsPage({super.key, required this.room});
  final Room room;

  @override
  State<RoomSecuritySettingsPage> createState() =>
      _RoomSecuritySettingsPageState();
}

class _RoomSecuritySettingsPageState extends State<RoomSecuritySettingsPage> {
  @override
  Widget build(BuildContext context) {
    return RoomSecuritySettingsView(
      isE2EEEnabled: widget.room.isE2EE,
      enableE2EE: enableE2EE,
      supportsE2EE: widget.room.client.supportsE2EE,
    );
  }

  void enableE2EE() {
    widget.room.enableE2EE();
  }
}
