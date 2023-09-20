import 'package:commet/utils/text_utils.dart';
import 'package:test/test.dart';

void main() async {
  test("EmojiTest: doBigEmoji '😀'", () async {
    expect(TextUtils.shouldDoBigEmoji("😀"), isTrue);
  });

  test("EmojiTest: doBigEmoji '😀😀😀😀😀'", () async {
    expect(TextUtils.shouldDoBigEmoji("😀😀😀😀😀"), isTrue);
  });

  test("EmojiTest: doBigEmoji '😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀'", () async {
    expect(
        TextUtils.shouldDoBigEmoji("😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀"), isFalse);
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
}
