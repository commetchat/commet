import 'package:commet/client/client.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/ui/pages/settings/categories/room/emoji_packs/room_emoji_pack_settings_view.dart';
import 'package:commet/ui/pages/settings/categories/space/space_emoji_settings_view.dart';
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class SpaceEmojiPackSettings extends StatefulWidget {
  final Space space;
  const SpaceEmojiPackSettings(this.space, {super.key});

  @override
  State<SpaceEmojiPackSettings> createState() => _SpaceEmojiPackSettingsState();
}

class _SpaceEmojiPackSettingsState extends State<SpaceEmojiPackSettings> {
  late SpaceEmoticonComponent component;

  @override
  void initState() {
    component = widget.space.getComponent<SpaceEmoticonComponent>()!;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final editable = widget.space.permissions.canEditRoomEmoticons;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SpaceEmojiSettingsView(component: component, editable: editable),
        const SizedBox(height: 24),
        const tiamat.Text.labelEmphasised('Emoji packs'),
        const tiamat.Text.labelLow(
            'Server emojis are stored in a pack of their own. Packs can also '
            'hold stickers and be imported in bulk.'),
        const SizedBox(height: 8),
        RoomEmojiPackSettingsView(
          component: component,
          editable: editable,
        ),
      ],
    );
  }
}
