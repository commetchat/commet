import 'package:commet/utils/text_utils.dart';
import 'package:test/test.dart';

void main() async {
  test("IsEmoji: 😀", () async {
    expect(TextUtils.isEmoji("😀"), isTrue);
  });

  test("IsEmoji: 👨‍👨‍👧‍👧", () async {
    expect(TextUtils.isEmoji("👨‍👨‍👧‍👧"), isTrue);
  });

  test("IsEmoji: 1️⃣", () async {
    expect(TextUtils.isEmoji("1️⃣"), isTrue);
  });

  test("IsEmoji: A", () async {
    expect(TextUtils.isEmoji("A"), isFalse);
  });

  test("IsEmoji: A̛͚̖", () async {
    expect(TextUtils.isEmoji("A̛͚̖"), isFalse);
  });

  test("IsEmoji: A😀", () async {
    expect(TextUtils.isEmoji("A😀"), isFalse);
  });

  test("EmojiTest: should do big emoji 'ABCD😀FGH'", () async {
    var string = "ABCD😀FGH";
    var spans = TextUtils.formatString(string);
    expect(TextUtils.shouldDoBigEmoji(spans), isFalse);
  });

  test("EmojiTest: should do big emoji '😀😀😀'", () async {
    var string = "😀😀😀";
    var spans = TextUtils.formatString(string);
    expect(TextUtils.shouldDoBigEmoji(spans), isTrue);
  });

  test("EmojiTest: should do big emoji '😀 😀 😀'", () async {
    var string = "😀 😀 😀";
    var spans = TextUtils.formatString(string);
    expect(TextUtils.shouldDoBigEmoji(spans), isTrue);
  });

  test("EmojiTest: should do big emoji '😀😀😀😀😀😀😀😀😀😀😀😀😀😀'",
      () async {
    var string = "😀😀😀😀😀😀😀😀😀😀😀😀😀😀";
    var spans = TextUtils.formatString(string);
    expect(TextUtils.shouldDoBigEmoji(spans), isFalse);
  });
}
