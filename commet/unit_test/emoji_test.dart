import 'dart:math';

import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/client/simulated/simulated_client.dart';
import 'package:commet/client/simulated/simulated_room.dart';
import 'package:commet/client/split_timeline.dart';
import 'package:commet/ui/atoms/emoji_widget.dart';
import 'package:commet/utils/emoji/emoji.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

void main() async {
  test("EmojiTest: doBigEmoji '😀'", () async {
    expect(TextUtils.shouldDoBigEmoji("😀"), isTrue);
  });

  test("EmojiTest: doBigEmoji '😀😀😀😀😀'", () async {
    expect(TextUtils.shouldDoBigEmoji("😀😀😀😀😀"), isTrue);
  });

  test("EmojiTest: doBigEmoji '😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀'", () async {
    expect(TextUtils.shouldDoBigEmoji("😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀"), isFalse);
  });

  test("EmojiTest: doBigEmoji 'a😀'", () async {
    expect(TextUtils.shouldDoBigEmoji("a😀"), isFalse);
  });

  test("EmojiTest: doBigEmoji '😀a'", () async {
    expect(TextUtils.shouldDoBigEmoji("😀a"), isFalse);
  });

  test("EmojiTest: doBigEmoji 'a'", () async {
    expect(TextUtils.shouldDoBigEmoji("a"), isFalse);
  });

  test("EmojiTest: Emojify '😀'", () async {
    var parsed = Emoji.emojifyString("😀");

    expect(parsed.length, equals(1));

    expect(parsed.first is WidgetSpan, isTrue);
  });

  test("EmojiTest: Emojify 'a😀'", () async {
    var parsed = Emoji.emojifyString("a😀");

    expect(parsed.length, equals(2));

    expect(parsed.first is TextSpan, isTrue);
    expect(parsed.elementAt(1) is WidgetSpan, isTrue);
  });

  test("EmojiTest: Emojify 'a😀a'", () async {
    var parsed = Emoji.emojifyString("a😀a");

    expect(parsed.length, equals(3));

    expect(parsed.first is TextSpan, isTrue);
    expect(parsed.elementAt(1) is WidgetSpan, isTrue);
    expect(parsed.last is TextSpan, isTrue);
  });

  test("EmojiTest: Emojify 'a😀a😀'", () async {
    var parsed = Emoji.emojifyString("a😀a😀");

    expect(parsed.length, equals(4));

    expect(parsed.first is TextSpan, isTrue);
    expect(parsed.elementAt(1) is WidgetSpan, isTrue);
    expect(parsed.elementAt(2) is TextSpan, isTrue);
    expect(parsed.last is WidgetSpan, isTrue);
  });

  test("EmojiTest: Emojify 'a'", () async {
    var parsed = Emoji.emojifyString("a");

    expect(parsed.length, equals(1));

    expect(parsed.first is TextSpan, isTrue);
  });
}
