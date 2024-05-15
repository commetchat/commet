import 'dart:async';
import 'dart:typed_data';

import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:flutter/material.dart';

abstract class EmoticonPack {
  String get identifier;
  String get attribution;
  String get displayName;
  String get ownerId;
  String get ownerDisplayName;

  Stream<int> get onEmoticonAdded;

  List<Emoticon> get emotes;

  List<Emoticon> get emoji;

  List<Emoticon> get stickers;

  List<String> getShortcodes();

  ImageProvider? get image;
  IconData? get icon;

  bool get isStickerPack;
  bool get isEmojiPack;
  bool get isGloballyAvailable;

  Future<void> deleteEmoticon(Emoticon emoticon);

  Future<void> renameEmoticon(Emoticon emoticon, String name);

  Future<void> markEmoticonAsSticker(Emoticon emoticon, bool isSticker);

  Future<void> markEmoticonAsEmoji(Emoticon emoticon, bool isEmoji);

  Future<void> markAsEmoji(bool isEmojiPack);

  Future<void> markAsSticker(bool isStickerPack);

  Emoticon? getByShortcode(String shortcode);

  Future<void> addEmoticon(
      {required String slug,
      String? shortcode,
      required Uint8List data,
      String? mimeType,
      bool? isEmoji,
      bool? isSticker});

  Future<void> markAsGlobal(bool isGlobal);

  List<Emoticon> search(String searchText, [int limit = -1]);
}
