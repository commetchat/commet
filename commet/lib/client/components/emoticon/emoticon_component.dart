import 'dart:async';
import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/room_component.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/space_component.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';

import 'emoji_pack.dart';

abstract class EmoticonComponent<T extends Client> implements Component<T> {
  List<EmoticonPack> globalPacks();
  List<EmoticonPack> get ownedPacks;
  bool get canCreatePack;
  Stream<int> get onOwnedPackAdded;

  Future<void> createEmoticonPack(String name, Uint8List? avatarData);
  Future<void> importEmoticonPack(String name, int avatarIndex,
      List<String> names, List<Uint8List> imageDatas);
  Future<void> deleteEmoticonPack(EmoticonPack pack);
}

abstract class RoomEmoticonComponent<R extends Client, T extends Room>
    extends EmoticonComponent<R> implements RoomComponent<R, T> {
  Future<TimelineEvent?> sendSticker(
      Emoticon sticker, TimelineEvent? inReplyTo);

  List<EmoticonPack> get availablePacks;
  List<EmoticonPack> get availableEmoji;
  List<EmoticonPack> get availableStickers;
}

abstract class SpaceEmoticonComponent<R extends Client, T extends Space>
    extends EmoticonComponent<R> implements SpaceComponent<R, T> {}
