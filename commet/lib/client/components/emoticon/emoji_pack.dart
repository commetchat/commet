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

  EmoticonUsage get usage;

  Future<void> deleteEmoticon(Emoticon emoticon);

  Future<void> setPackUsage(EmoticonUsage usage);

  Future<void> updatePack(
      {EmoticonUsage? usage, String? name, Uint8List? imageData});

  Emoticon? getByShortcode(String shortcode);

  bool get isStickerPack;

  bool get isEmojiPack;

  Future<void> updateEmoticon({
    String? slug,
    String? shortcode,
    Uint8List? data,
    String? mimeType,
    EmoticonUsage? usage,
    required Emoticon previous,
  });

  Future<void> addEmoticon({
    required String slug,
    String? shortcode,
    required Uint8List data,
    String? mimeType,
    EmoticonUsage usage,
  });

  Future<void> markAsGlobal(bool isGlobal);

  List<Emoticon> search(String searchText, [int limit = -1]);
}
