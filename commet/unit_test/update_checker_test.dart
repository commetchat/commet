import 'package:commet/utils/update_checker.dart';
import 'package:flutter_test/flutter_test.dart';

/// The version comparison decides whether the user is told an update exists, so
/// getting it wrong is either a missed update (too strict) or a permanently
/// nagging prompt (too loose). It is pure, so it is pinned here rather than
/// left to the manual path.
void main() {
  group('parseVersion', () {
    test('reads a plain tag', () {
      expect(UpdateChecker.parseVersion("v0.10.2"), [0, 10, 2]);
    });

    test('works without the leading v', () {
      expect(UpdateChecker.parseVersion("1.2.3"), [1, 2, 3]);
    });

    test('reads a bare major', () {
      expect(UpdateChecker.parseVersion("v2"), [2]);
    });

    test('ignores a pre-release suffix', () {
      expect(UpdateChecker.parseVersion("v1.2.3-rc1"), [1, 2, 3]);
    });

    test('returns null when there is no version', () {
      expect(UpdateChecker.parseVersion("development"), isNull);
      expect(UpdateChecker.parseVersion(""), isNull);
    });

    test('returns null when a numeric component is too large', () {
      expect(UpdateChecker.parseVersion("v9223372036854775808.0.0"), isNull);
    });
  });

  group('isNewer', () {
    test('a later patch is newer', () {
      expect(UpdateChecker.isNewer("v0.10.3", "v0.10.2"), isTrue);
    });

    test('a later minor outranks a later patch', () {
      expect(UpdateChecker.isNewer("v0.11.0", "v0.10.9"), isTrue);
    });

    test('a later major outranks everything below it', () {
      expect(UpdateChecker.isNewer("v1.0.0", "v0.99.99"), isTrue);
    });

    test('the identical version is not newer', () {
      expect(UpdateChecker.isNewer("v0.10.2", "v0.10.2"), isFalse);
    });

    test('an older version is not newer', () {
      expect(UpdateChecker.isNewer("v0.10.1", "v0.10.2"), isFalse);
      expect(UpdateChecker.isNewer("v0.9.9", "v0.10.0"), isFalse);
    });

    test('compares numerically, not as strings', () {
      // The classic trap: "10" < "9" as text but 10 > 9 as a number.
      expect(UpdateChecker.isNewer("v0.10.0", "v0.9.0"), isTrue);
      expect(UpdateChecker.isNewer("v0.9.0", "v0.10.0"), isFalse);
    });

    test('treats a missing component as zero', () {
      expect(UpdateChecker.isNewer("v0.11", "v0.10.2"), isTrue);
      expect(UpdateChecker.isNewer("v0.10.2", "v0.10"), isTrue);
      expect(UpdateChecker.isNewer("v0.10", "v0.10.0"), isFalse);
    });

    test('a pre-release of a newer version still counts as newer', () {
      // Tag shape comes from the repo's releases; a prerelease suffix should
      // not stop us noticing the numeric part moved.
      expect(UpdateChecker.isNewer("v0.11.0-rc1", "v0.10.2"), isTrue);
    });

    test('an unparseable current version never reports an update', () {
      // Local builds default to VERSION_TAG=development and must stay quiet.
      expect(UpdateChecker.isNewer("v0.11.0", "development"), isFalse);
    });

    test('an unparseable candidate version never reports an update', () {
      expect(UpdateChecker.isNewer("nightly", "v0.10.2"), isFalse);
    });
  });
}
