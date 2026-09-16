// media_kit-backed SoundboardPlayer: one media_kit Player per trigger.
//
// Every instance (keyed by the trigger's eventId) gets its own Player, so the
// same sound triggered twice overlaps instead of restarting (Discord
// behavior). On web each Player owns its own media element, so this holds
// there too. An instance is disposed when it completes or errors, and
// [MediaKitSoundboardPlayer.onInstanceFinished] reports it so the engine can
// drop it. An instance that never reports an end (stalled stream) is
// released after [MediaKitSoundboardPlayer.maxInstanceLifetime]. Volume per
// instance = SoundboardSound.gain (normalization * admin volume) * userVolume,
// resolved on every start so admin changes apply to the next trigger. All
// errors are swallowed after logging: a soundboard failure must never take
// down the call.
import 'dart:async';

import 'package:commet/client/components/soundboard/soundboard_constraints.dart';
import 'package:commet/client/components/soundboard/soundboard_engine.dart';
import 'package:commet/client/components/soundboard/soundboard_sound.dart';
import 'package:commet/debug/log.dart';
import 'package:media_kit/media_kit.dart';

typedef SoundResolver = SoundboardSound? Function(String soundId);
typedef UriResolver = Future<String> Function(SoundboardSound sound);

/// One playing sound. Production wraps a media_kit [Player]; tests fake it.
abstract class SoundboardAudioInstance {
  /// Fires once playback ends, naturally or through a fatal error.
  Stream<void> get finished;
  Future<void> setVolume(double mpvVolume);
  Future<void> open(String uri);

  /// Stops playback and releases the instance.
  Future<void> dispose();
}

class _LiveInstance {
  final SoundboardAudioInstance audio;

  /// [SoundboardSound.gain] (normalization * admin volume) when started.
  final double soundGain;
  late final StreamSubscription<void> finishedSub;
  late final Timer lifetime;

  _LiveInstance(this.audio, this.soundGain);
}

class MediaKitSoundboardPlayer implements SoundboardPlayer {
  final SoundResolver resolveSound;
  final UriResolver resolvePlayableUri;
  final SoundboardAudioInstance Function() createInstance;
  final Duration maxInstanceLifetime;

  /// Called when an instance ends on its own (completion, error, unknown
  /// sound). Not called for [stop]/[stopAll], which the caller initiated.
  void Function(String instanceId)? onInstanceFinished;

  final Map<String, _LiveInstance> _instances = {};
  double _userVolume = 0.8;

  MediaKitSoundboardPlayer({
    required this.resolveSound,
    required this.resolvePlayableUri,
    SoundboardAudioInstance Function()? createInstance,
    this.onInstanceFinished,
    Duration? maxInstanceLifetime,
  })  : createInstance = createInstance ?? _MediaKitAudioInstance.new,
        maxInstanceLifetime = maxInstanceLifetime ??
            const Duration(
                milliseconds: SoundboardConstraints.maxDurationMs + 5000);

  /// media_kit takes mpv's `volume`, where 100 plays the file unchanged (and
  /// mpv applies it cubically, so 0..1 is silence). Never boosts past 100.
  /// [soundGain] is [SoundboardSound.gain].
  static double mpvVolume(double userVolume, double soundGain) =>
      (userVolume * soundGain).clamp(0.0, 1.0) * 100;

  @override
  Future<void> start(String instanceId, String soundId) async {
    final sound = resolveSound(soundId);
    if (sound == null) {
      // Unknown sound (e.g. removed after event sent): nothing to play.
      onInstanceFinished?.call(instanceId);
      return;
    }
    final live = _LiveInstance(createInstance(), sound.gain);
    live.finishedSub =
        live.audio.finished.listen((_) => _finish(instanceId, live));
    live.lifetime = Timer(maxInstanceLifetime, () => _finish(instanceId, live));
    _instances[instanceId] = live;
    try {
      await _applyVolume(live);
      final uri = await resolvePlayableUri(sound);
      // Stopped while the file was being resolved.
      if (_instances[instanceId] != live) return;
      Log.d('Soundboard: playing $soundId ($instanceId) from $uri');
      await live.audio.open(uri);
    } catch (e, s) {
      Log.onError(e, s, content: 'Soundboard play failed: $soundId');
      await _finish(instanceId, live);
    }
  }

  Future<void> _finish(String instanceId, _LiveInstance live) async {
    if (_instances[instanceId] != live) return;
    await _release(instanceId);
    onInstanceFinished?.call(instanceId);
  }

  Future<void> _release(String instanceId) async {
    final live = _instances.remove(instanceId);
    if (live == null) return;
    live.lifetime.cancel();
    try {
      await live.finishedSub.cancel();
      await live.audio.dispose();
    } catch (e, s) {
      Log.onError(e, s, content: 'Soundboard stop failed: $instanceId');
    }
  }

  @override
  Future<void> stop(String instanceId) => _release(instanceId);

  @override
  Future<void> stopAll() async {
    for (final id in _instances.keys.toList()) {
      await _release(id);
    }
  }

  /// Sets the user volume (0..1.5, 0 = mute), which also applies to future
  /// instances, and updates [instanceId] if it is live.
  @override
  Future<void> setVolumeFor(String instanceId, double volume) async {
    _userVolume = volume.clamp(0.0, 1.5);
    final live = _instances[instanceId];
    if (live == null) return;
    try {
      await _applyVolume(live);
    } catch (_) {}
  }

  Future<void> _applyVolume(_LiveInstance live) =>
      live.audio.setVolume(mpvVolume(_userVolume, live.soundGain));

  @override
  bool isPlaying(String instanceId) => _instances.containsKey(instanceId);
}

class _MediaKitAudioInstance implements SoundboardAudioInstance {
  final Player _player = Player();

  @override
  late final Stream<void> finished = _finishedStream();

  Stream<void> _finishedStream() {
    // open() does not throw for unplayable media; mpv reports it here.
    final controller = StreamController<void>();
    final subs = [
      _player.stream.completed.listen((done) {
        if (done) controller.add(null);
      }),
      _player.stream.error.listen((error) {
        Log.w('Soundboard player error: $error');
        // mpv also reports errors it recovers from; only a stopped player
        // has ended.
        if (!_player.state.playing) controller.add(null);
      }),
    ];
    controller.onCancel = () async {
      for (final sub in subs) {
        await sub.cancel();
      }
    };
    return controller.stream;
  }

  @override
  Future<void> setVolume(double mpvVolume) => _player.setVolume(mpvVolume);

  @override
  Future<void> open(String uri) => _player.open(Media(uri), play: true);

  @override
  Future<void> dispose() async {
    await _player.stop();
    await _player.dispose();
  }
}
