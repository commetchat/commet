import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/ui/pages/settings/categories/room/emoji_packs/room_emoji_pack_settings_view.dart';
import 'package:commet/utils/emoji/emoji_pack.dart';
import 'package:commet/utils/emoji/emoticon.dart';
import 'package:flutter/widgets.dart';

class SpaceEmojiPackSettings extends StatefulWidget {
  final Space space;
  const SpaceEmojiPackSettings(this.space, {super.key});

  @override
  State<SpaceEmojiPackSettings> createState() => _SpaceEmojiPackSettingsState();
}

class _SpaceEmojiPackSettingsState extends State<SpaceEmojiPackSettings> {
  @override
  Widget build(BuildContext context) {
    return RoomEmojiPackSettingsView(
      widget.space.ownedEmoji,
      createNewPack: createNewPack,
      onPackCreated: widget.space.onEmojiPackAdded.stream,
      deletePack: deletePack,
      deleteEmoticon: deleteEmoticon,
      editable: widget.space.permissions.canEditRoomEmoticons,
      renameEmoticon: renameEmoticon,
    );
  }

  Future<void> createNewPack(String name, Uint8List? avatarData) async {
    await widget.space.createEmoticonPack(
      name,
      avatarData,
    );
  }

  Future<void> deletePack(EmoticonPack pack) async {
    await widget.space.deleteEmoticonPack(pack);
  }

  Future<void> deleteEmoticon(EmoticonPack pack, Emoticon emoticon) async {
    await pack.deleteEmoticon(emoticon);
  }

  Future<void> renameEmoticon(
      EmoticonPack pack, Emoticon emoticon, String name) async {
    await pack.renameEmoticon(emoticon, name);
  }
}
