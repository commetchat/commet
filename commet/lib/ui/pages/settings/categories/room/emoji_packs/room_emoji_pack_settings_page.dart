import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/ui/pages/settings/categories/room/emoji_packs/room_emoji_pack_settings_view.dart';
import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
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
      widget.room.roomEmoticons!.ownedPacks,
      createNewPack: createNewPack,
      onPackCreated: widget.room.roomEmoticons!.onOwnedPackAdded,
      deletePack: deletePack,
      deleteEmoticon: deleteEmoticon,
      canCreatePack: widget.room.roomEmoticons!.canCreatePack,
      renameEmoticon: renameEmoticon,
      editable: widget.room.permissions.canEditRoomEmoticons,
    );
  }

  Future<void> createNewPack(String name, Uint8List? avatarData) async {
    await widget.room.roomEmoticons?.createEmoticonPack(name, avatarData);
  }

  Future<void> deletePack(EmoticonPack pack) async {
    await widget.room.roomEmoticons?.deleteEmoticonPack(pack);
  }

  Future<void> deleteEmoticon(EmoticonPack pack, Emoticon emoticon) async {
    await pack.deleteEmoticon(emoticon);
  }

  Future<void> renameEmoticon(
      EmoticonPack pack, Emoticon emoticon, String name) async {
    await pack.renameEmoticon(emoticon, name);
  }
}
