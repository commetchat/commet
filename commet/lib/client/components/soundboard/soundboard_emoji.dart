// The icon of a soundboard sound: a unicode emoji or a custom Space emoticon.
//
// Pure Dart (unit-testable). Rendering lives in the UI, which turns [mxc]
// into an image with the client it has at hand.

/// Either a unicode emoji ([SoundboardEmoji.unicode]) or a Space emoticon
/// referenced by its mxc image ([SoundboardEmoji.custom]).
class SoundboardEmoji {
  /// Shown by clients that cannot render a custom emoticon.
  static const String fallback = '🔊';

  /// The unicode emoji, or [fallback] for a custom emoticon.
  final String unicode;

  /// `mxc://` URI of the emoticon image. Null for unicode emoji.
  final String? mxc;

  /// Emoticon shortcode with colons (`:velho:`). A label only, since the
  /// emoticon may be renamed or deleted from its pack; [mxc] stays valid.
  final String? shortcode;

  const SoundboardEmoji.unicode(this.unicode)
      : mxc = null,
        shortcode = null;

  const SoundboardEmoji.custom({required String this.mxc, String? shortcode})
      : unicode = fallback,
        shortcode = shortcode ?? '';

  bool get isCustom => mxc != null;

  /// State event fields. `emoji` is always written because earlier builds
  /// require it and skip sounds without it.
  Map<String, dynamic> toJson() => {
        'emoji': unicode,
        if (isCustom) 'emoji_mxc': mxc,
        if (isCustom) 'emoji_shortcode': shortcode,
      };

  /// Reads the fields written by [toJson] from any client, never throwing.
  factory SoundboardEmoji.fromJson(Map<String, dynamic> json) {
    final mxc = json['emoji_mxc'];
    if (mxc is String && mxc.startsWith('mxc://')) {
      final shortcode = json['emoji_shortcode'];
      return SoundboardEmoji.custom(
          mxc: mxc, shortcode: shortcode is String ? shortcode : '');
    }
    final emoji = json['emoji'];
    return SoundboardEmoji.unicode(
        emoji is String && emoji.isNotEmpty ? emoji : fallback);
  }

  @override
  bool operator ==(Object other) =>
      other is SoundboardEmoji &&
      other.unicode == unicode &&
      other.mxc == mxc &&
      other.shortcode == shortcode;

  @override
  int get hashCode => Object.hash(unicode, mxc, shortcode);

  @override
  String toString() => isCustom ? 'SoundboardEmoji($shortcode $mxc)' : unicode;
}
