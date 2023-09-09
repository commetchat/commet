import 'dart:async';
import 'dart:typed_data';

import 'package:commet/client/components/component.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';

import 'emoji_pack.dart';

abstract class EmoticonComponent implements Component {
  List<EmoticonPack> globalPacks();
  List<EmoticonPack> get ownedPacks;
  bool get canCreatePack;

  Stream<int> get onOwnedPackAdded;

  Future<void> createEmoticonPack(String name, Uint8List? avatarData);
  Future<void> deleteEmoticonPack(EmoticonPack pack);
}

abstract class RoomEmoticonComponent extends EmoticonComponent {
  Future<TimelineEvent?> sendSticker(
      Emoticon sticker, TimelineEvent? inReplyTo);

  List<EmoticonPack> get availablePacks;
  List<EmoticonPack> get availableEmoji;
  List<EmoticonPack> get availableStickers;
}
