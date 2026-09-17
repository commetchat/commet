// Admin-side preview for the soundboard settings page.
//
// Plays one sound at the volume a call would use (normalizedGain *
// adminVolume * userVolume, via MediaKitSoundboardPlayer.mpvVolume), so the
// admin hears what the volume slider does before saving. Moving the slider
// during playback updates the live volume.
import 'dart:typed_data';

import 'package:commet/client/matrix/components/soundboard/mediakit_soundboard_player.dart';
import 'package:commet/debug/log.dart';
import 'package:media_kit/media_kit.dart';

class SoundboardPreviewPlayer {
  /// The listener's own soundboard volume (0..1.5), read on every change.
  final double Function() userVolume;

  Player? _player;
  double _soundGain = 1.0;

  SoundboardPreviewPlayer({required this.userVolume});

  /// Plays audio that has not been uploaded yet (the add form).
  Future<void> playBytes(Uint8List bytes, String mimeType, double soundGain) =>
      _play(() => Media.memory(bytes, type: mimeType), soundGain);

  /// Plays an already resolved, playable URI (the edit dialog).
  Future<void> playUri(String uri, double soundGain) =>
      _play(() async => Media(uri), soundGain);

  /// [soundGain] is normalizedGain * adminVolume.
  Future<void> setSoundGain(double soundGain) async {
    _soundGain = soundGain;
    try {
      await _player?.setVolume(_volume);
    } catch (_) {}
  }

  double get _volume =>
      MediaKitSoundboardPlayer.mpvVolume(userVolume(), _soundGain);

  Future<void> _play(Future<Media> Function() media, double soundGain) async {
    _soundGain = soundGain;
    final player = _player ??= _createPlayer();
    await player.stop();
    await player.setVolume(_volume);
    await player.open(await media(), play: true);
  }

  Player _createPlayer() {
    final player = Player();
    player.stream.error
        .listen((error) => Log.w('Soundboard preview error: $error'));
    return player;
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    final player = _player;
    _player = null;
    try {
      await player?.dispose();
    } catch (_) {}
  }
}
