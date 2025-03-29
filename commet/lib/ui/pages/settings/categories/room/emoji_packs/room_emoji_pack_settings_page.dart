import 'package:commet/client/client.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/ui/pages/settings/categories/room/emoji_packs/room_emoji_pack_settings_view.dart';
import 'package:flutter/widgets.dart';

class RoomEmojiPackSettingsPage extends StatefulWidget {
  const RoomEmojiPackSettingsPage(this.room, {super.key});
  final Room room;

  @override
  State<RoomEmojiPackSettingsPage> createState() =>
      _RoomEmojiPackSettingsPageState();
}

class _RoomEmojiPackSettingsPageState extends State<RoomEmojiPackSettingsPage> {
  late RoomEmoticonComponent component;

  @override
  void initState() {
    component = widget.room.getComponent<RoomEmoticonComponent>()!;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RoomEmojiPackSettingsView(
      component: component,
      editable: widget.room.permissions.canEditRoomEmoticons,
    );
  }
}
