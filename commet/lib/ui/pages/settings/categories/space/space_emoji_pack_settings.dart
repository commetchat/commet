import 'package:commet/client/client.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/ui/pages/settings/categories/room/emoji_packs/room_emoji_pack_settings_view.dart';
import 'package:flutter/widgets.dart';

class SpaceEmojiPackSettings extends StatefulWidget {
  final Space space;
  const SpaceEmojiPackSettings(this.space, {super.key});

  @override
  State<SpaceEmojiPackSettings> createState() => _SpaceEmojiPackSettingsState();
}

class _SpaceEmojiPackSettingsState extends State<SpaceEmojiPackSettings> {
  late EmoticonComponent component;

  @override
  void initState() {
    component = widget.space.getComponent<SpaceEmoticonComponent>()!;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RoomEmojiPackSettingsView(
      component: component,
      editable: widget.space.permissions.canEditRoomEmoticons,
    );
  }
}
