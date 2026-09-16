// Discord-style "server emoji" rules over a space's im.ponies.room_emotes
// packs. Pure Dart (unit-testable).

class SpaceEmojiError implements Exception {
  final String message;
  const SpaceEmojiError(this.message);

  @override
  String toString() => message;
}

class SpaceEmoji {
  final String packKey;
  final String shortcode;
  final String url;

  const SpaceEmoji(
      {required this.packKey, required this.shortcode, required this.url});
}

/// The new content to send as the `im.ponies.room_emotes` state with [packKey].
class SpaceEmojiEdit {
  final String packKey;
  final Map<String, dynamic> content;

  const SpaceEmojiEdit(this.packKey, this.content);
}

/// A read-only view of a space's emoticon packs, keyed by state key, that
/// computes the edits the "server emoji" settings make.
class SpaceEmojiLibrary {
  /// State key of the pack that emoji uploaded from the settings page go to.
  static const defaultPackKey = 'server_emojis';
  static const quota = 50;

  static const minShortcodeLength = 2;
  static const maxShortcodeLength = 32;

  static final _validShortcode = RegExp(r'^[A-Za-z0-9_]+$');

  final Map<String, dynamic> _packs;

  SpaceEmojiLibrary(Map<String, dynamic> packs) : _packs = packs;

  /// Pack state keys, default pack first.
  Iterable<String> get _packKeys => [
        if (_packs.containsKey(defaultPackKey)) defaultPackKey,
        ..._packs.keys.where((k) => k != defaultPackKey),
      ];

  Map<String, dynamic> _images(String packKey) {
    final images = _map(_map(_packs[packKey])['images']);
    return {
      for (final e in images.entries)
        if (_map(e.value)['url'] is String) e.key: _map(e.value),
    };
  }

  /// Images usable as emoji (not sticker-only), deduplicated by shortcode.
  List<SpaceEmoji> get emoji {
    final result = <SpaceEmoji>[];
    final seen = <String>{};
    for (final packKey in _packKeys) {
      final packUsage = _usage(_map(_map(_packs[packKey])['pack']));
      for (final image in _images(packKey).entries) {
        final usage = _usage(image.value) ?? packUsage;
        if (usage != null && !usage.contains('emoticon')) continue;
        if (!seen.add(image.key)) continue;
        result.add(SpaceEmoji(
            packKey: packKey,
            shortcode: image.key,
            url: image.value['url'] as String));
      }
    }
    return result;
  }

  /// Every image in every pack of the space takes a slot.
  int get usedSlots =>
      _packKeys.fold(0, (sum, key) => sum + _images(key).length);

  int get freeSlots => quota - usedSlots;

  bool _isTaken(String shortcode) =>
      _packKeys.any((key) => _images(key).containsKey(shortcode));

  /// Shortcodes of every image in the space, for [shortcodeFromFilename].
  Set<String> get takenShortcodes =>
      {for (final key in _packKeys) ..._images(key).keys};

  /// Adds an image, already uploaded to [url], to the default pack.
  SpaceEmojiEdit add(String shortcode, String url) {
    shortcode = validateShortcode(shortcode);
    if (freeSlots <= 0) {
      throw const SpaceEmojiError('This space has no emoji slots left');
    }
    if (_isTaken(shortcode)) {
      throw SpaceEmojiError('An emoji named :$shortcode: already exists');
    }

    final content = _copy(_map(_packs[defaultPackKey]));
    content['pack'] ??= {'display_name': 'Server Emojis'};
    final images = content['images'] is Map
        ? content['images'] as Map<String, dynamic>
        : content['images'] = <String, dynamic>{};
    images[shortcode] = {'url': url};

    return SpaceEmojiEdit(defaultPackKey, content);
  }

  String _owningPack(String shortcode) {
    for (final key in _packKeys) {
      if (_images(key).containsKey(shortcode)) return key;
    }
    throw SpaceEmojiError('There is no emoji named :$shortcode:');
  }

  /// Renames an image in whichever pack holds it, keeping its position.
  SpaceEmojiEdit rename(String shortcode, String newShortcode) {
    final packKey = _owningPack(shortcode);
    newShortcode = validateShortcode(newShortcode);
    if (newShortcode != shortcode && _isTaken(newShortcode)) {
      throw SpaceEmojiError('An emoji named :$newShortcode: already exists');
    }

    final content = _copy(_map(_packs[packKey]));
    final images = content['images'] as Map<String, dynamic>;
    content['images'] = {
      for (final e in images.entries)
        (e.key == shortcode ? newShortcode : e.key): e.value,
    };
    return SpaceEmojiEdit(packKey, content);
  }

  /// Removes an image from whichever pack holds it.
  SpaceEmojiEdit remove(String shortcode) {
    final packKey = _owningPack(shortcode);
    final content = _copy(_map(_packs[packKey]));
    (content['images'] as Map<String, dynamic>).remove(shortcode);
    return SpaceEmojiEdit(packKey, content);
  }

  static Map<String, dynamic> _copy(Map<String, dynamic> value) =>
      value.map((k, v) => MapEntry(k, _copyValue(v)));

  static Object? _copyValue(Object? value) => switch (value) {
        Map() => _copy(value.cast<String, dynamic>()),
        List() => value.map(_copyValue).toList(),
        _ => value,
      };

  static Map<String, dynamic> _map(Object? value) =>
      value is Map ? value.cast<String, dynamic>() : const {};

  static List<String>? _usage(Map<String, dynamic> content) {
    final usage = content['usage'];
    if (usage is! List || usage.isEmpty) return null;
    return usage.whereType<String>().toList();
  }

  /// Returns the shortcode without surrounding whitespace or colons, or throws
  /// [SpaceEmojiError] if it is not 2-32 letters, digits or underscores.
  static String validateShortcode(String input) {
    var shortcode = input.trim();
    if (shortcode.startsWith(':')) shortcode = shortcode.substring(1);
    if (shortcode.endsWith(':')) {
      shortcode = shortcode.substring(0, shortcode.length - 1);
    }

    if (shortcode.length < minShortcodeLength ||
        shortcode.length > maxShortcodeLength) {
      throw const SpaceEmojiError('Emoji names must be between '
          '$minShortcodeLength and $maxShortcodeLength characters');
    }
    if (!_validShortcode.hasMatch(shortcode)) {
      throw const SpaceEmojiError(
          'Emoji names may only contain letters, numbers and underscores');
    }
    return shortcode;
  }

  /// Derives a valid shortcode from an uploaded file's name that is not in
  /// [taken], appending `_2`, `_3`... when needed.
  static String shortcodeFromFilename(String filename, Set<String> taken) {
    var name = filename.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    if (dot > 0) name = name.substring(0, dot);

    var base = name
        .replaceAll(RegExp(r'[^A-Za-z0-9_]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (base.isEmpty) base = 'emoji';
    if (base.length < minShortcodeLength) {
      base = base.padRight(minShortcodeLength, '_');
    }

    var candidate = _truncate(base, maxShortcodeLength);
    for (var n = 2; taken.contains(candidate); n++) {
      final suffix = '_$n';
      candidate = _truncate(base, maxShortcodeLength - suffix.length) + suffix;
    }
    return candidate;
  }

  static String _truncate(String value, int length) =>
      value.length <= length ? value : value.substring(0, length);
}
