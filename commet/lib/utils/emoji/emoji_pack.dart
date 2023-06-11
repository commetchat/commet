import 'dart:async';
import 'dart:typed_data';

import 'package:commet/utils/emoji/emoticon.dart';
import 'package:flutter/material.dart';

abstract class EmoticonPack {
  String get identifier;
  String get attribution;
  String get displayName;

  Stream<int> get onEmoticonAdded;

  List<Emoticon> get emotes;

  ImageProvider? get image;
  IconData? get icon;

  Future<void> deleteEmoticon(Emoticon emoticon);

  Future<void> renameEmoticon(Emoticon emoticon, String name);

  Future<void> addEmoticon(
      {required String slug,
      String? shortcode,
      required Uint8List data,
      String? mimeType});
}
