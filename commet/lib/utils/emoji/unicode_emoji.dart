import 'dart:convert';

import 'package:commet/utils/emoji/emoticon.dart';
import 'package:commet/utils/emoji/emoji_pack.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class UnicodeEmojis {
  static List<UnicodeEmoticonPack>? packs;

  static Future<List<UnicodeEmoticonPack>> load() async {
    if (packs != null) return packs!;

    String jsonString =
        await rootBundle.loadString("assets/emoji_data/data.json");
    List<dynamic> data = jsonDecode(jsonString);

    String shortcodesString =
        await rootBundle.loadString("assets/emoji_data/shortcodes/en.json");
    Map<String, dynamic> shortCodes = jsonDecode(shortcodesString);

    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    packs = List.from([
      UnicodeEmoticonPack(
          getLocalisedName: () => "Smileys & People", groups: [0, 1]),
      UnicodeEmoticonPack(
          getLocalisedName: () => "Animals & Nature", groups: [3]),
      UnicodeEmoticonPack(getLocalisedName: () => "Food & Drink", groups: [4]),
      UnicodeEmoticonPack(
          getLocalisedName: () => "Travel & Places", groups: [5]),
      UnicodeEmoticonPack(getLocalisedName: () => "Activities", groups: [6]),
      UnicodeEmoticonPack(getLocalisedName: () => "Objects", groups: [7]),
      UnicodeEmoticonPack(getLocalisedName: () => "Symbols", groups: [8]),
      UnicodeEmoticonPack(getLocalisedName: () => "Flags", groups: [9]),
    ]);

    for (var pack in packs!) {
      await pack.load(data, shortCodes, manifestMap);
    }

    return packs!;
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
  Stream<int> get onEmoticonAdded => throw UnimplementedError();

  @override
  List<Emoticon> get emotes => _emoji;

  @override
  final IconData? icon;

  @override
  final ImageProvider<Object>? image;

  final List<Emoticon> _emoji = List.empty(growable: true);

  final String Function() getLocalisedName;
  final List<int> groups;

  UnicodeEmoticonPack(
      {required this.groups,
      required this.getLocalisedName,
      this.icon,
      this.image});

  Future<void> load(List<dynamic> emojiData, Map<String, dynamic> shortCodes,
      Map<String, dynamic> manifestMap) async {
    for (var emoji in emojiData) {
      Map data = emoji;
      String hexcode = data['hexcode'];

      if (!shortCodes.containsKey(hexcode)) {
        continue;
      }

      var codes = shortCodes[hexcode];
      var shortcode = codes is String ? codes : (codes as List).first;

      if (data.containsKey('group')) {
        int groupId = data['group'];
        if (groups.contains(groupId)) {
          var emojiChar = data['emoji'];

          if (!manifestMap
              .containsKey(UnicodeEmoticon.emojiToAsset(emojiChar))) {
            print("Skipping emoji due to missing asset: $emojiChar");
            continue;
          }

          var e = UnicodeEmoticon(emojiChar, shortcode: shortcode);
          _emoji.add(e);
        }
      }
    }
  }

  @override
  Future<void> addEmoticon(
      {required String slug,
      String? shortcode,
      required Uint8List data,
      String? mimeType}) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteEmoticon(Emoticon emoticon) {
    throw UnimplementedError();
  }

  @override
  Future<void> renameEmoticon(Emoticon emoticon, String name) {
    throw UnimplementedError();
  }
}

class UnicodeEmoticon extends Emoticon {
  late ImageProvider _image;
  late String? _shortcode;

  @override
  late String slug;

  @override
  ImageProvider<Object> get image => _image;

  @override
  String? get shortcode => _shortcode;

  UnicodeEmoticon(String text, {String? shortcode}) {
    String hexcode = emojiToUnicode(text);
    _image = AssetImage("assets/twemoji/assets/72x72/$hexcode.png");
    _shortcode = shortcode;
    slug = text;
  }

  static String emojiToAsset(String emojiChar) {
    String hexcode = emojiToUnicode(emojiChar);
    return "assets/twemoji/assets/72x72/$hexcode.png";
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
}
