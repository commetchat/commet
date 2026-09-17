// Shared overlay state: which sender currently has a visible emoji burst.
//
// Written by the call's SoundboardSession (via engine listeners), read by
// every VoipStreamView. Keyed by Matrix userId so the emoji appears ONLY on
// the sender's avatar — never broadcast to all tiles.
import 'package:commet/client/components/soundboard/soundboard_emoji.dart';
import 'package:flutter/widgets.dart';

class SoundboardOverlayEntry {
  final String soundId;
  final SoundboardEmoji emoji;

  /// Image of a custom [emoji], resolved by the caller that has a client.
  final ImageProvider? image;
  final int expiresAtMs;
  final int overlayMs;

  const SoundboardOverlayEntry({
    required this.soundId,
    required this.emoji,
    this.image,
    required this.expiresAtMs,
    required this.overlayMs,
  });
}

class SoundboardOverlayRegistry extends ChangeNotifier {
  static final SoundboardOverlayRegistry instance =
      SoundboardOverlayRegistry._();
  SoundboardOverlayRegistry._();

  final Map<String, SoundboardOverlayEntry> _byUser = {};

  SoundboardOverlayEntry? entryFor(String userId) {
    final e = _byUser[userId];
    if (e == null) return null;
    if (DateTime.now().millisecondsSinceEpoch > e.expiresAtMs) {
      _byUser.remove(userId);
      return null;
    }
    return e;
  }

  SoundboardOverlayEntry show({
    required String userId,
    required String soundId,
    required SoundboardEmoji emoji,
    ImageProvider? image,
    required int overlayMs,
  }) {
    final entry = _byUser[userId] = SoundboardOverlayEntry(
      soundId: soundId,
      emoji: emoji,
      image: image,
      overlayMs: overlayMs,
      expiresAtMs: DateTime.now().millisecondsSinceEpoch + overlayMs + 200,
    );
    notifyListeners();
    return entry;
  }

  /// Clears [userId]'s overlay only if it is still [entry].
  void clearEntry(String userId, SoundboardOverlayEntry entry) {
    if (identical(_byUser[userId], entry)) clearUser(userId);
  }

  void clearUser(String userId) {
    if (_byUser.remove(userId) != null) notifyListeners();
  }

  void clearAll() {
    if (_byUser.isNotEmpty) {
      _byUser.clear();
      notifyListeners();
    }
  }

  /// Test seam.
  void clearForTests() => clearAll();
}
