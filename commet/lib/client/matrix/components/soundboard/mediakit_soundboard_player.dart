// media_kit-backed SoundboardPlayer: polyphonic, restart-per-soundId.
//
// One Player per concurrent soundId (different sounds overlap; same soundId
// restarts via seek-then-play on the existing Player — no layering, no
// global <audio> bottleneck). Volume per Player = normalizedGain *
// adminVolume * userVolume, recomputed on every start and setVolumeFor.
// All errors are swallowed after logging: a soundboard failure must never
// take down the call.
import 'package:commet/client/components/soundboard/soundboard_engine.dart';
import 'package:commet/client/components/soundboard/soundboard_sound.dart';
import 'package:commet/debug/log.dart';
import 'package:media_kit/media_kit.dart';

typedef SoundResolver = SoundboardSound? Function(String soundId);
typedef UriResolver = Future<String> Function(SoundboardSound sound);

class MediaKitSoundboardPlayer implements SoundboardPlayer {
  final SoundResolver resolveSound;
  final UriResolver resolvePlayableUri;

  final Map<String, Player> _players = {};
  // SoundboardSound.gain (normalization * admin volume) per soundId.
  final Map<String, double> _soundGain = {};
  double _userVolume = 0.8;

  MediaKitSoundboardPlayer({
    required this.resolveSound,
    required this.resolvePlayableUri,
  });

  double _effectiveVolume(String soundId) =>
      mpvVolume(_userVolume, _soundGain[soundId] ?? 1.0);

  /// media_kit takes mpv's `volume`, where 100 plays the file unchanged (and
  /// mpv applies it cubically, so 0..1 is silence). Never boosts past 100.
  /// [soundGain] is [SoundboardSound.gain].
  static double mpvVolume(double userVolume, double soundGain) =>
      (userVolume * soundGain).clamp(0.0, 1.0) * 100;

  @override
  Future<void> start(String soundId) async {
    try {
      // Resolve on every start: an admin may have changed the volume since.
      final sound = resolveSound(soundId);
      if (sound != null) _soundGain[soundId] = sound.gain;
      final existing = _players[soundId];
      if (existing != null) {
        // Restart semantics: same sound restarts from 0, never layers.
        await existing.seek(Duration.zero);
        await existing.setVolume(_effectiveVolume(soundId));
        await existing.play();
        return;
      }
      final player = Player();
      // open() does not throw for unplayable media; mpv reports it here.
      player.stream.error.listen(
          (error) => Log.w('Soundboard player error ($soundId): $error'));
      _players[soundId] = player;
      await player.setVolume(_effectiveVolume(soundId));
      String uri;
      if (sound != null) {
        uri = await resolvePlayableUri(sound);
      } else {
        // Unknown sound (e.g. removed after event sent): nothing to play.
        // Remove the placeholder so isPlaying is false.
        await player.dispose();
        _players.remove(soundId);
        return;
      }
      Log.d('Soundboard: playing $soundId from $uri '
          'at volume ${_effectiveVolume(soundId)}');
      await player.open(Media(uri), play: true);
    } catch (e, s) {
      Log.onError(e, s, content: 'Soundboard play failed: $soundId');
      final p = _players.remove(soundId);
      try {
        await p?.dispose();
      } catch (_) {}
    }
  }

  @override
  Future<void> stop(String soundId) async {
    final p = _players.remove(soundId);
    if (p == null) return;
    try {
      await p.stop();
      await p.dispose();
    } catch (e, s) {
      Log.onError(e, s, content: 'Soundboard stop failed: $soundId');
    }
  }

  @override
  Future<void> stopAll() async {
    final all = _players.values.toList();
    _players.clear();
    for (final p in all) {
      try {
        await p.stop();
        await p.dispose();
      } catch (_) {}
    }
  }

  @override
  Future<void> setVolumeFor(String soundId, double volume) async {
    _userVolume = volume.clamp(0.0, 1.5);
    final p = _players[soundId];
    if (p == null) return;
    try {
      await p.setVolume(_effectiveVolume(soundId));
    } catch (_) {}
  }

  /// Global user volume (0..1.5, 0 = mute). Applies to live + future sounds.
  Future<void> setGlobalVolume(double volume) async {
    _userVolume = volume.clamp(0.0, 1.5);
    for (final entry in _players.entries) {
      try {
        await entry.value.setVolume(_effectiveVolume(entry.key));
      } catch (_) {}
    }
  }

  @override
  bool isPlaying(String soundId) => _players.containsKey(soundId);

  int get openPlayers => _players.length;
}
