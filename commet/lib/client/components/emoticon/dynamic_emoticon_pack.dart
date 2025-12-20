import 'dart:typed_data';

import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:flutter/src/painting/image_provider.dart';
import 'package:flutter/src/widgets/icon_data.dart';

class DynamicEmoticonPack implements EmoticonPack {
  List<Emoticon> emoticons;
  DynamicEmoticonPack({
    required this.emoticons,
    required this.displayName,
    required this.identifier,
    required this.usage,
    this.icon,
  });

  @override
  Future<void> addEmoticon(
      {required String slug,
      String? shortcode,
      required Uint8List data,
      String? mimeType,
      EmoticonUsage usage = EmoticonUsage.emoji}) {
    throw UnimplementedError();
  }

  @override
  String get attribution => "";

  @override
  Future<void> deleteEmoticon(Emoticon emoticon) {
    throw UnimplementedError();
  }

  @override
  String displayName;

  @override
  List<Emoticon> get emoji => emotes.where((i) => i.isEmoji).toList();

  @override
  List<Emoticon> get emotes => emoticons;

  @override
  Emoticon? getByShortcode(String shortcode) {
    throw UnimplementedError();
  }

  @override
  List<String> getShortcodes() {
    throw UnimplementedError();
  }

  @override
  IconData? icon;

  @override
  String identifier;

  @override
  ImageProvider<Object>? get image => null;

  @override
  bool get isEmojiPack => throw UnimplementedError();

  @override
  bool get isGloballyAvailable => throw UnimplementedError();

  @override
  bool get isStickerPack => throw UnimplementedError();

  @override
  Future<void> markAsGlobal(bool isGlobal) {
    throw UnimplementedError();
  }

  @override
  String get ownerDisplayName => throw UnimplementedError();

  @override
  String get ownerId => throw UnimplementedError();

  @override
  List<Emoticon> search(String searchText, [int limit = -1]) {
    throw UnimplementedError();
  }

  @override
  Future<void> setPackUsage(EmoticonUsage usage) {
    throw UnimplementedError();
  }

  @override
  List<Emoticon> get stickers => emoticons.where((i) => i.isSticker).toList();

  @override
  Future<void> updateEmoticon(
      {String? slug,
      String? shortcode,
      Uint8List? data,
      String? mimeType,
      EmoticonUsage? usage,
      required Emoticon previous}) {
    throw UnimplementedError();
  }

  @override
  Future<void> updatePack(
      {EmoticonUsage? usage, String? name, Uint8List? imageData}) {
    throw UnimplementedError();
  }

  @override
  EmoticonUsage usage;
}
