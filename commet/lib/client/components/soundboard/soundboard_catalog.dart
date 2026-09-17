// Catalog seam. Pure Dart interface; Matrix adapter persists per-sound
// state events (type chat.commet.soundboard.sound, state_key=soundId).
import 'dart:async';

import 'soundboard_sound.dart';

abstract class SoundboardCatalog {
  List<SoundboardSound> get sounds;
  SoundboardSound? getById(String soundId);
  Stream<void> get onChanged;
}

/// In-memory catalog for tests / previews.
class InMemorySoundboardCatalog implements SoundboardCatalog {
  final List<SoundboardSound> _sounds;
  final StreamController<void> _controller =
      StreamController<void>.broadcast();

  InMemorySoundboardCatalog([List<SoundboardSound>? initial])
      : _sounds = List.of(initial ?? []);

  @override
  List<SoundboardSound> get sounds => List.unmodifiable(_sounds);

  @override
  SoundboardSound? getById(String soundId) {
    for (final s in _sounds) {
      if (s.soundId == soundId) return s;
    }
    return null;
  }

  void upsert(SoundboardSound sound) {
    final i = _sounds.indexWhere((s) => s.soundId == sound.soundId);
    if (i >= 0) {
      _sounds[i] = sound;
    } else {
      _sounds.add(sound);
    }
    _controller.add(null);
  }

  void remove(String soundId) {
    _sounds.removeWhere((s) => s.soundId == soundId);
    _controller.add(null);
  }

  @override
  Stream<void> get onChanged => _controller.stream;
}
