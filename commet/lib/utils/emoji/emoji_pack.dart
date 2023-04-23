import 'dart:convert';

import 'package:commet/utils/emoji/emoji.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class EmojiPack {
  late List<Emoji> emoji;
  late String name;

  EmojiPack({required this.name}) {
    emoji = List.empty(growable: true);
  }

  void add(Emoji newEmoji) {
    emoji.add(newEmoji);
  }

  static Future<List<EmojiPack>> defaults() async {
    var people = EmojiPack(name: "Smileys & People");
    var nature = EmojiPack(name: "Animals & Nature");
    var food = EmojiPack(name: "Food & Drink");
    var activities = EmojiPack(name: "Activities");
    var objects = EmojiPack(name: "Objects");
    var places = EmojiPack(name: "Trabel & Places");
    var symbols = EmojiPack(name: "Symbols");
    var flags = EmojiPack(name: "Flags");

    Map<int, EmojiPack> groupToPack = {
      0: people,
      1: people,
      3: nature,
      4: food,
      5: places,
      6: activities,
      7: objects,
      8: symbols,
      9: flags
    };

    String jsonString =
        await rootBundle.loadString("assets/emoji_data/data.json");
    List<dynamic> data = jsonDecode(jsonString);

    String shortcodesString =
        await rootBundle.loadString("assets/emoji_data/shortcodes/en.json");
    Map<String, dynamic> shortCodes = jsonDecode(shortcodesString);

    for (var emoji in data) {
      Map emojiData = emoji;
      String hexcode = emojiData['hexcode'];

      if (!shortCodes.containsKey(hexcode)) {
        continue;
      }

      var codes = shortCodes[hexcode];
      var shortcode = codes is String ? codes : (codes as List).first;

      if (emojiData.containsKey('group')) {
        int groupId = emojiData['group'];
        var e = Emoji(AssetImage("assets/twemoji/assets/72x72/$hexcode.png"),
            shortcode: shortcode, unicode: hexcode);

        if (groupToPack.containsKey(groupId)) {
          groupToPack[groupId]!.add(e);
        } else {
          symbols.add(e);
        }
      }
    }

    var result = [
      people,
      nature,
      food,
      places,
      activities,
      objects,
      symbols,
      flags
    ];

    return result;
  }
}
