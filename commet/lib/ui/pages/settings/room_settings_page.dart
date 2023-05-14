import 'package:commet/client/client.dart';
import 'package:commet/ui/pages/settings/categories/room/settings_category_room.dart';
import 'package:commet/ui/pages/settings/settings_page.dart';
import 'package:flutter/widgets.dart';

class RoomSettingsPage extends StatelessWidget {
  const RoomSettingsPage({super.key, required this.room});
  final Room room;

  @override
  Widget build(BuildContext context) {
    return SettingsPage(settings: [
      SettingsCategoryRoom(
        room,
      ),
    ]);
  }
}
