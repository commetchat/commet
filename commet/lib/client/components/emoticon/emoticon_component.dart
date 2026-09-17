import 'dart:async';
import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/room_component.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/space_component.dart';
import 'package:commet/client/components/emoticon/space_emoji_library.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';

import 'emoji_pack.dart';

abstract class EmoticonComponent<T extends Client> implements Component<T> {
  List<EmoticonPack> globalPacks();
  List<EmoticonPack> get ownedPacks;
  List<EmoticonPack> get availablePacks;
  bool get canCreatePack;
  Stream<void> get onStateChanged;

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
    extends EmoticonComponent<R> implements SpaceComponent<R, T> {
  /// The space's custom emoji, usable in messages and reactions in any of its
  /// rooms. Each has a [Emoticon.shortcode] and an [Emoticon.url].
  List<Emoticon> get availableEmoji;

  int get emojiQuota;

  /// Emoji slots taken by images in any of the space's packs.
  int get usedEmojiSlots;

  /// A free, valid shortcode for an image uploaded from [filename].
  String suggestShortcode(String filename);

  /// Throws [SpaceEmojiError] when the name is invalid or taken, or the quota
  /// is full.
  Future<void> addEmoji(String shortcode, Uint8List data,
      {String? mimeType, String? filename});

  Future<void> renameEmoji(Emoticon emoji, String shortcode);

  Future<void> removeEmoji(Emoticon emoji);
}
