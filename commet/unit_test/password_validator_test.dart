import 'package:commet/utils/text_utils.dart';
import 'package:test/test.dart';

void main() async {
  test("Force Digits: 'abcdefg'", () async {
    expect(
        TextUtils.isValidPassword("abcdefg", forceDigits: true) ==
            NewPasswordResult.noNumbers,
        isTrue);
  });

  test("Force Digits: 'abcdefg123'", () async {
    expect(
        TextUtils.isValidPassword("abcdefg123", forceDigits: true) ==
            NewPasswordResult.valid,
        isTrue);
  });

  test("Force length 10: 'abc'", () async {
    expect(
        TextUtils.isValidPassword("abc", forceLength: 10) ==
            NewPasswordResult.tooShort,
        isTrue);
  });

  test("Force length 10: 'abcdefghijklmnopqrstuvqxyz'", () async {
    expect(
        TextUtils.isValidPassword("abcdefghijklmnopqrstuvqxyz",
                forceLength: 10) ==
            NewPasswordResult.valid,
        isTrue);
  });

  test("Force Special Characters: 'abcdef'", () async {
    expect(
        TextUtils.isValidPassword("abcdef", forceSpecialCharacter: true) ==
            NewPasswordResult.noSymbols,
        isTrue);
  });

  test("Force Special Characters: 'abcdef!'", () async {
    expect(
        TextUtils.isValidPassword("abcdef!", forceSpecialCharacter: true) ==
            NewPasswordResult.valid,
        isTrue);
  });

  test("Force All: 'a'", () async {
    expect(
        TextUtils.isValidPassword("a",
                forceSpecialCharacter: true,
                forceLength: 10,
                forceDigits: true) !=
            NewPasswordResult.valid,
        isTrue);
  });

  test("Force All: 'a1'", () async {
    expect(
        TextUtils.isValidPassword("a1",
                forceSpecialCharacter: true,
                forceLength: 10,
                forceDigits: true) !=
            NewPasswordResult.valid,
        isTrue);
  });

  test("Force All: 'a1!'", () async {
    expect(
        TextUtils.isValidPassword("a1!",
                forceSpecialCharacter: true,
                forceLength: 10,
                forceDigits: true) !=
            NewPasswordResult.valid,
        isTrue);
  });

  test("Force All: 'a1!bcdefghijklmnop'", () async {
    expect(
        TextUtils.isValidPassword("a1!bcdefghijklmnop",
                forceSpecialCharacter: true,
                forceLength: 10,
                forceDigits: true) ==
            NewPasswordResult.valid,
        isTrue);
  });
}
