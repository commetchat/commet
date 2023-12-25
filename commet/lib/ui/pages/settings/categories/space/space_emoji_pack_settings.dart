import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/ui/pages/settings/categories/room/emoji_packs/room_emoji_pack_settings_view.dart';
import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
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
      component.ownedPacks,
      createNewPack: createNewPack,
      onPackCreated: component.onOwnedPackAdded,
      deletePack: deletePack,
      deleteEmoticon: deleteEmoticon,
      canCreatePack: component.canCreatePack,
      editable: widget.space.permissions.canEditRoomEmoticons,
      renameEmoticon: renameEmoticon,
      importPack: importPack,
    );
  }

  Future<void> createNewPack(String name, Uint8List? avatarData) async {
    await component.createEmoticonPack(
      name,
      avatarData,
    );
  }

  Future<void> deletePack(EmoticonPack pack) async {
    await component.deleteEmoticonPack(pack);
  }

  Future<void> deleteEmoticon(EmoticonPack pack, Emoticon emoticon) async {
    await pack.deleteEmoticon(emoticon);
  }

  Future<void> renameEmoticon(
      EmoticonPack pack, Emoticon emoticon, String name) async {
    await pack.renameEmoticon(emoticon, name);
  }

  Future<void> importPack(String name, int avatarIndex, List<String> names,
      List<Uint8List> imageDatas) async {
    component.importEmoticonPack(name, avatarIndex, names, imageDatas);
  }
}
