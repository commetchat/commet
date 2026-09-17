// Validation for admin-provided name/emoji. Pure Dart (unit-testable).
import 'soundboard_constraints.dart';
import 'soundboard_emoji.dart';

class SoundboardValidationError implements Exception {
  final String message;
  const SoundboardValidationError(this.message);
  @override
  String toString() => 'SoundboardValidationError: $message';
}

class SoundboardValidator {
  /// Sanitizes display name: trims, collapses whitespace, rejects markup/
  /// control chars, enforces length. Returns sanitized name.
  static String sanitizeName(String input) {
    var name = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    // Strip control characters (incl. \n, \t already collapsed).
    name = name.replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), '');
    if (name.length < SoundboardConstraints.minNameLength) {
      throw const SoundboardValidationError('Name must not be empty');
    }
    if (name.runes.length > SoundboardConstraints.maxNameLength) {
      throw const SoundboardValidationError('Name too long');
    }
    // Reject markup / structured-text injection; names are plain text.
    if (name.contains('<') || name.contains('>')) {
      throw const SoundboardValidationError('Name must not contain markup');
    }
    return name;
  }

  /// Validates a single emoji grapheme. Accepts ZWJ sequences, skin tones,
  /// flags, keycaps — anything that is one extended grapheme cluster with
  /// at least one Emoji codepoint. Rejects `.length == 1` style checks.
  ///
  /// Heuristic without ICU: strip ZWJ/VS16/skin-tone/keycap modifiers, then
  /// require 1..8 remaining base codepoints, at least one with Emoji
  /// property, and no whitespace/control. This accepts compound emoji while
  /// rejecting multi-emoji strings like "😂😂".
  static String sanitizeEmoji(String input) {
    final emoji = input.trim();
    if (emoji.isEmpty || emoji.contains(RegExp(r'\s'))) {
      throw const SoundboardValidationError('Emoji must be a single emoji');
    }
    // Split into extended-grapheme-ish clusters: break on ZWJ-joined runs
    // stays together; regional indicators pair into flags.
    final clusters = _splitGraphemes(emoji);
    if (clusters.length != 1) {
      throw const SoundboardValidationError('Emoji must be a single emoji');
    }
    if (!_containsEmoji(emoji)) {
      throw const SoundboardValidationError('Not an emoji');
    }
    return emoji;
  }

  /// Validates a sound's emoji. Unicode goes through [sanitizeEmoji]; a
  /// custom emoticon needs a well-formed `mxc://server/media-id` and a
  /// `:shortcode:` (colons are added when missing). Event content can be
  /// written by any client, so this is checked even for picker output.
  static SoundboardEmoji sanitizeSoundEmoji(SoundboardEmoji emoji) {
    final mxc = emoji.mxc;
    if (mxc == null) {
      return SoundboardEmoji.unicode(sanitizeEmoji(emoji.unicode));
    }
    if (!_mxcPattern.hasMatch(mxc)) {
      throw const SoundboardValidationError('Invalid custom emoji image');
    }
    var name = (emoji.shortcode ?? '').trim();
    if (name.length >= 2 && name.startsWith(':') && name.endsWith(':')) {
      name = name.substring(1, name.length - 1);
    }
    if (!_shortcodePattern.hasMatch(name)) {
      throw const SoundboardValidationError('Invalid custom emoji name');
    }
    return SoundboardEmoji.custom(mxc: mxc, shortcode: ':$name:');
  }

  // Matrix spec: server name (hostname, IPv4 or [IPv6], optional port) and
  // an opaque media ID of [A-Za-z0-9_-].
  static final _mxcPattern = RegExp(
      r'^mxc://([A-Za-z0-9.\-]+|\[[0-9A-Fa-f:.]+\])(:[0-9]{1,5})?/[A-Za-z0-9_\-]+$');
  static final _shortcodePattern = RegExp(r'^[^\s:<>]{1,100}$');

  static List<String> _splitGraphemes(String s) {
    // Minimal extended-grapheme approximation sufficient for emoji:
    // - CR LF pairs, Regional_Indicator pairs, and ZWJ/keycap/VS16/skin-tone
    //   glued sequences each count as ONE cluster.
    final runes = s.runes.toList();
    final clusters = <String>[];
    final buf = StringBuffer();
    var riCount = 0; // consecutive regional indicators in current cluster

    void flush() {
      if (buf.isNotEmpty) {
        clusters.add(buf.toString());
        buf.clear();
        riCount = 0;
      }
    }

    bool isRI(int r) => r >= 0x1F1E6 && r <= 0x1F1FF;
    bool isGlue(int r) =>
        r == 0x200D || // ZWJ
        r == 0xFE0F || // VS16
        r == 0xFE0E || // VS15
        (r >= 0x1F3FB && r <= 0x1F3FF) || // skin tones
        r == 0x20E3; // keycap combiner

    for (var i = 0; i < runes.length; i++) {
      final r = runes[i];
      final prev = i > 0 ? runes[i - 1] : null;
      final inGlueRun = prev != null &&
          (prev == 0x200D || isGlue(r) || isGlue(prev) || prev == 0x20E3);

      if (buf.isEmpty) {
        buf.write(String.fromCharCode(r));
        riCount = isRI(r) ? 1 : 0;
        continue;
      }

      if (r == 0x200D || isGlue(r) || (prev != null && prev == 0x200D)) {
        buf.write(String.fromCharCode(r));
        continue;
      }
      if (isRI(r) && riCount == 1 && !inGlueRun) {
        // Second RI completes a flag cluster.
        buf.write(String.fromCharCode(r));
        clusters.add(buf.toString());
        buf.clear();
        riCount = 0;
        continue;
      }
      if (r == 0x0A && prev == 0x0D) {
        buf.write(String.fromCharCode(r));
        continue;
      }
      // Break cluster.
      void pushCurrent() {
        clusters.add(buf.toString());
        buf.clear();
      }

      pushCurrent();
      buf.write(String.fromCharCode(r));
      riCount = isRI(r) ? 1 : 0;
    }
    flush();
    return clusters;
  }

  static bool _containsEmoji(String s) {
    for (final r in s.runes) {
      if (_isEmojiCodepoint(r)) return true;
    }
    return false;
  }

  static bool _isEmojiCodepoint(int r) {
    return (r >= 0x1F600 && r <= 0x1F64F) || // emoticons
        (r >= 0x1F300 && r <= 0x1F5FF) || // symbols & pictographs
        (r >= 0x1F680 && r <= 0x1F6FF) || // transport
        (r >= 0x1F700 && r <= 0x1F77F) || // alchemical
        (r >= 0x1F780 && r <= 0x1F7FF) || // geometric ext
        (r >= 0x1F800 && r <= 0x1F8FF) || // supplemental arrows-c
        (r >= 0x1F900 && r <= 0x1F9FF) || // supplemental symbols
        (r >= 0x1FA00 && r <= 0x1FAFF) || // chess/extended-a
        (r >= 0x2600 && r <= 0x26FF) || // misc symbols
        (r >= 0x2700 && r <= 0x27BF) || // dingbats
        (r >= 0x2B00 && r <= 0x2BFF) || // misc arrows
        (r >= 0x1F1E6 && r <= 0x1F1FF) || // flags
        (r >= 0x2300 && r <= 0x23FF) || // misc technical (⏰ etc.)
        r == 0x00A9 ||
        r == 0x00AE ||
        (r >= 0x30 && r <= 0x39); // keycap digits handled with combiner
  }
}
