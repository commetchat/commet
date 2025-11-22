import 'dart:convert';

import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/utils/emoji/unicode_emoji_data.dart';
import 'package:commet/utils/emoji/unicode_emoji_data_groups.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:matrix/matrix.dart';

class UnicodeEmojis {
  static List<UnicodeEmoticonPack>? packs;

  static Future<List<UnicodeEmoticonPack>> load() async {
    packs = List.from([
      UnicodeEmoticonPack(
          dataPacks: [UnicodeEmojiGroups.GROUP_0],
          getLocalisedName: () => "Smileys",
          icon: Icons.emoji_emotions),
      UnicodeEmoticonPack(
          dataPacks: [UnicodeEmojiGroups.GROUP_1],
          getLocalisedName: () => "People",
          icon: Icons.emoji_people),
      UnicodeEmoticonPack(
          dataPacks: [UnicodeEmojiGroups.GROUP_3],
          getLocalisedName: () => "Animals & Nature",
          icon: Icons.emoji_nature_rounded),
      UnicodeEmoticonPack(
          dataPacks: [UnicodeEmojiGroups.GROUP_4],
          getLocalisedName: () => "Food & Drink",
          icon: Icons.emoji_food_beverage),
      UnicodeEmoticonPack(
          dataPacks: [UnicodeEmojiGroups.GROUP_5],
          getLocalisedName: () => "Travel & Places",
          icon: Icons.emoji_transportation),
      UnicodeEmoticonPack(
          dataPacks: [UnicodeEmojiGroups.GROUP_6],
          getLocalisedName: () => "Activities",
          icon: Icons.emoji_events),
      UnicodeEmoticonPack(
          dataPacks: [UnicodeEmojiGroups.GROUP_7],
          getLocalisedName: () => "Objects",
          icon: Icons.emoji_objects),
      UnicodeEmoticonPack(
          dataPacks: [UnicodeEmojiGroups.GROUP_8],
          getLocalisedName: () => "Symbols",
          icon: Icons.emoji_symbols),
      UnicodeEmoticonPack(
          dataPacks: [UnicodeEmojiGroups.GROUP_9],
          getLocalisedName: () => "Flags",
          icon: Icons.emoji_flags),
    ]);

    for (var pack in packs!) {
      await pack.load();
    }

    return packs!;
  }

  static Map<String, dynamic>? shortcodeData;

  static Future<void> loadShortcodeData() async {
    if (shortcodeData == null) {
      var data =
          await rootBundle.loadString('assets/emoji_data/shortcodes/en.json');

      shortcodeData = jsonDecode(data) as Map<String, dynamic>;
    }
  }

  static String? findShortcode(String emoji) {
    var codepoint = UnicodeEmoticon.emojiToUnicode(emoji).toUpperCase();

    var codes = shortcodeData![codepoint];
    if (codes is String) {
      return codes;
    } else if (codes is List<dynamic>) {
      return codes[0] as String;
    }

    return codepoint;
  }
}

class UnicodeEmoticonPack implements EmoticonPack {
  @override
  String get attribution =>
      "Copyright 2020 Twitter, Inc and other contributors";

  @override
  String get displayName => getLocalisedName();

  @override
  String get identifier => throw UnimplementedError();

  @override
  List<Emoticon> get emotes => _emoji!;

  @override
  bool get isEmojiPack => true;

  @override
  bool get isStickerPack => false;

  @override
  List<Emoticon> get emoji => _emoji!;

  @override
  List<Emoticon> get stickers => [];

  List<List<UnicodeEmojiData>> dataPacks;

  @override
  final IconData? icon;

  @override
  final ImageProvider<Object>? image;

  List<Emoticon>? _emoji;

  Map<String, Emoticon>? _emojiByShortcode;

  final String Function() getLocalisedName;

  UnicodeEmoticonPack(
      {required this.getLocalisedName,
      required this.dataPacks,
      this.icon,
      this.image});

  Future<void> load() async {
    _emoji = List.empty(growable: true);

    for (var pack in dataPacks) {
      var emoji = List.generate(
          pack.length,
          (index) => UnicodeEmoticon(pack[index].unicode,
              shortcode: pack[index].shortcode));

      _emoji!.addAll(emoji);
    }

    for (var emoji in _emoji!) {
      _emojiByShortcode = <String, Emoticon>{};
      if (emoji.shortcode != null) {
        _emojiByShortcode![emoji.shortcode!] = emoji;
      }
    }
  }

  @override
  Future<void> deleteEmoticon(Emoticon emoticon) {
    throw UnimplementedError();
  }

  @override
  Future<void> markAsGlobal(bool isGlobal) {
    throw UnimplementedError();
  }

  @override
  List<String> getShortcodes() {
    return emoji.map((e) => e.shortcode!).toList();
  }

  @override
  List<Emoticon> search(String searchText, [int limit = -1]) {
    var fuzzy = Fuzzy<Emoticon>(emoji,
        options: FuzzyOptions(threshold: 0.4, keys: [
          WeightedKey(
              name: "shortcode",
              getter: (obj) {
                return obj.shortcode ?? "";
              },
              weight: 1)
        ]));

    return fuzzy.search(searchText, limit).map((e) => e.item).toList();
  }

  @override
  Emoticon? getByShortcode(String shortcode) {
    return _emojiByShortcode?.tryGet(shortcode);
  }

  @override
  String get ownerDisplayName => "";

  @override
  String get ownerId => "";

  @override
  Future<void> setPackUsage(EmoticonUsage usage) async {}

  @override
  EmoticonUsage get usage => EmoticonUsage.emoji;

  @override
  Future<void> addEmoticon(
      {required String slug,
      String? shortcode,
      required Uint8List data,
      String? mimeType,
      EmoticonUsage? usage}) {
    throw UnimplementedError();
  }

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
  bool get isGloballyAvailable => false;
}

class UnicodeEmoticon extends Emoticon {
  late String? _shortcode;

  @override
  late String slug;

  @override
  String get key => slug;

  @override
  ImageProvider? get image => null;

  @override
  String? get shortcode => _shortcode;

  @override
  bool get isEmoji => true;

  @override
  bool get isSticker => false;

  UnicodeEmoticon(String text, {String? shortcode}) {
    _shortcode = shortcode;
    slug = text;
  }

  static final _u200D = String.fromCharCode(0x200D);

  static final _uFE0Fg = RegExp(
    r'\uFE0F',
    unicode: true,
  );

  static String emojiToUnicode(String rawText) => toCodePoint(
        !rawText.contains(_u200D) ? rawText.replaceAll(_uFE0Fg, '') : rawText,
      );

  static String toCodePoint(String input, {String sep = '-'}) {
    var r = [], c = 0, p = 0, i = 0;
    while (i < input.length) {
      c = input.codeUnitAt(i++);
      if (p != 0) {
        r.add(
            (0x10000 + ((p - 0xD800) << 10) + (c - 0xDC00)).toRadixString(16));
        p = 0;
      } else if (0xD800 <= c && c <= 0xDBFF) {
        p = c;
      } else {
        r.add(c.toRadixString(16));
      }
    }
    return r.join(sep);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is! UnicodeEmoticon) {
      return false;
    }

    return other.slug == slug;
  }

  @override
  int get hashCode {
    return slug.hashCode;
  }

  @override
  EmoticonUsage get usage => EmoticonUsage.emoji;
}
