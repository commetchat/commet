import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/ui/pages/settings/categories/room/emoji_packs/room_emoji_pack_settings_view.dart';
import 'package:commet/utils/emoji/emoji_pack.dart';
import 'package:commet/utils/emoji/emoticon.dart';
import 'package:flutter/widgets.dart';

class RoomEmojiPackSettingsPage extends StatefulWidget {
  const RoomEmojiPackSettingsPage(this.room, {super.key});
  final Room room;

  @override
  State<RoomEmojiPackSettingsPage> createState() =>
      _RoomEmojiPackSettingsPageState();
}

class _RoomEmojiPackSettingsPageState extends State<RoomEmojiPackSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return RoomEmojiPackSettingsView(
      widget.room.ownedEmoji,
      createNewPack: createNewPack,
      onPackCreated: widget.room.onEmojiPackAdded.stream,
      deletePack: deletePack,
      deleteEmoticon: deleteEmoticon,
      editable: widget.room.permissions.canEditRoomEmoticons,
    );
  }

  Future<void> createNewPack(String name, Uint8List? avatarData) async {}

  Future<void> deletePack(EmoticonPack pack) async {}

  Future<void> deleteEmoticon(EmoticonPack pack, Emoticon emoticon) async {}
}
