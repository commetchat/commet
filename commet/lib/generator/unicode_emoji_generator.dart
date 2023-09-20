import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';

import '../utils/emoji/unicode_emoji_data.dart';

class UnicodeEmojiBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {
        'assets/emoji_data/data.json': [
          'lib/utils/emoji/unicode_emoji_data_groups.g.dart'
        ],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    final outputId = AssetId(
        inputId.package, "lib/utils/emoji/unicode_emoji_data_groups.g.dart");

    final data =
        (json.decode(await buildStep.readAsString(inputId)) as List<dynamic>);
    Map<int, List<UnicodeEmojiData>> packs = {};

    String shortcodesString =
        await File("assets/emoji_data/shortcodes/en.json").readAsString();
    Map<String, dynamic> shortCodes = jsonDecode(shortcodesString);

    for (var e in data) {
      var emoji = e as Map<String, dynamic>;

      if (!emoji.containsKey("group")) continue;

      String hexcode = emoji["hexcode"];
      if (!shortCodes.containsKey(hexcode)) continue;

      int group = emoji["group"];
      String unicode = emoji["emoji"];

      String shortcode = shortCodes[hexcode] is String
          ? shortCodes[hexcode]
          : shortCodes[hexcode].first;

      if (!packs.containsKey(group)) {
        packs[group] = List.empty(growable: true);
      }

      packs[group]!
          .add(UnicodeEmojiData(unicode: unicode, shortcode: shortcode));
    }

    final outputBuffer = StringBuffer('// Generated, do not edit\n');
    outputBuffer.write("// ignore_for_file: constant_identifier_names\n");
    outputBuffer.write(
        "import 'package:commet/utils/emoji/unicode_emoji_data.dart';\n");

    outputBuffer.write("class UnicodeEmojiGroups {\n");

    for (var key in packs.keys) {
      outputBuffer
          .write("  static const List<UnicodeEmojiData> GROUP_$key = [\n");

      for (var emoji in packs[key]!) {
        outputBuffer.write(
            "    UnicodeEmojiData(unicode: \"${emoji.unicode}\", shortcode: \"${emoji.shortcode}\"),\n");
      }

      outputBuffer.write("  ];\n");
    }

    outputBuffer.write("}");

    await buildStep.writeAsString(outputId, outputBuffer.toString());
  }
}
