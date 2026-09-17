// Browser SoundboardPlayer on Web Audio: each sound is decoded once into an
// AudioBuffer and every instance plays through its own
// AudioBufferSourceNode -> GainNode, so the gain can exceed 1.0 (normalization
// boosts) unlike <audio>.volume. Same semantics as MediaKitSoundboardPlayer:
// one voice per trigger (instances of the same sound overlap), an instance
// that ends on its own is reported through [onInstanceFinished], errors are
// logged and swallowed. Sounds come from room state that any Space moderator
// can set, so decoded buffers are bounded in number and length (see
// soundboard_media_limits.dart) and playback is cut like on native.
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:commet/client/components/soundboard/soundboard_constraints.dart';
import 'package:commet/client/components/soundboard/soundboard_media_limits.dart';
import 'package:commet/client/components/soundboard/soundboard_normalizer.dart';
import 'package:commet/client/matrix/components/soundboard/soundboard_player_factory.dart';
import 'package:commet/debug/log.dart';
import 'package:web/web.dart' as web;

class _Voice {
  final web.AudioBufferSourceNode source;
  final web.GainNode gain;

  /// SoundboardSound.gain (normalization * admin volume) when started.
  final double soundGain;
  _Voice(this.source, this.gain, this.soundGain);
}

class WebAudioSoundboardPlayer implements PreloadingSoundboardPlayer {
  final SoundResolver resolveSound;
  final BytesLoader loadBytes;

  /// Called when an instance ends on its own (completion, error, unknown
  /// sound). Not called for [stop]/[stopAll], which the caller initiated.
  void Function(String instanceId)? onInstanceFinished;

  web.AudioContext? _context;
  final SoundboardBufferCache<web.AudioBuffer> _buffers =
      SoundboardBufferCache(maxEntries: SoundboardConstraints.maxCachedSounds);
  final Map<String, _Voice> _voices = {};

  /// Instances started but still decoding; a stop in the meantime cancels
  /// them.
  final Set<String> _pending = {};
  double _userVolume = 0.8;

  WebAudioSoundboardPlayer({
    required this.resolveSound,
    required this.loadBytes,
    this.onInstanceFinished,
  });

  web.AudioContext get _ctx => _context ??= web.AudioContext();

  double _amplitude(_Voice voice) => (_userVolume * voice.soundGain)
      .clamp(0.0, 1.5 * SoundboardNormalizer.maxGain);

  Future<web.AudioBuffer> _buffer(String soundId) {
    final sound = resolveSound(soundId);
    if (sound == null) {
      return Future.error(StateError('Unknown sound $soundId'));
    }
    // Keyed by file too: an admin can point a sound at a new file.
    return _buffers.get('${sound.soundId}\n${sound.mediaUri}', () async {
      final bytes = await loadBytes(sound);
      // decodeAudioData detaches the buffer it gets; hand it a copy.
      final copy = Uint8List.fromList(bytes).buffer.toJS;
      final web.AudioBuffer buffer;
      try {
        buffer = await _ctx.decodeAudioData(copy).toDart;
      } catch (e) {
        throw SoundboardMediaRejected('not decodable audio: $e');
      }
      if (buffer.duration * 1000 > SoundboardConstraints.maxPlaybackMs) {
        throw SoundboardMediaRejected(
            '${buffer.duration.toStringAsFixed(1)} s long');
      }
      return buffer;
    });
  }

  @override
  Future<void> preload(String soundId) => _buffer(soundId);

  @override
  Future<void> start(String instanceId, String soundId) async {
    final sound = resolveSound(soundId);
    if (sound == null) {
      // Unknown sound (e.g. removed after event sent): nothing to play.
      onInstanceFinished?.call(instanceId);
      return;
    }
    _pending.add(instanceId);
    try {
      // Autoplay policy: a click is a user gesture, so resume works here.
      if (_ctx.state == 'suspended') await _ctx.resume().toDart;
      final buffer = await _buffer(soundId);
      // Stopped while the sound was being decoded.
      if (!_pending.remove(instanceId)) return;
      final gain = _ctx.createGain();
      final source = _ctx.createBufferSource()..buffer = buffer;
      source.connect(gain);
      gain.connect(_ctx.destination);
      final voice = _Voice(source, gain, sound.gain);
      gain.gain.value = _amplitude(voice);
      source.onended = ((web.Event _) {
        // Also fires after stop(); only a voice still registered ended on
        // its own.
        if (!identical(_voices[instanceId], voice)) return;
        _voices.remove(instanceId);
        gain.disconnect();
        onInstanceFinished?.call(instanceId);
      }).toJS;
      _voices[instanceId] = voice;
      // Same cut as MediaKitSoundboardPlayer.maxInstanceLifetime.
      source.start(0, 0, SoundboardConstraints.maxPlaybackMs / 1000);
    } catch (e, s) {
      Log.onError(e, s, content: 'Soundboard play failed: $soundId');
      if (_pending.remove(instanceId) || _voices.containsKey(instanceId)) {
        _stopVoice(instanceId);
        onInstanceFinished?.call(instanceId);
      }
    }
  }

  void _stopVoice(String instanceId) {
    final voice = _voices.remove(instanceId);
    if (voice == null) return;
    try {
      voice.source.stop();
      voice.gain.disconnect();
    } catch (_) {}
  }

  @override
  Future<void> stop(String instanceId) async {
    _pending.remove(instanceId);
    _stopVoice(instanceId);
  }

  @override
  Future<void> stopAll() async {
    _pending.clear();
    for (final id in _voices.keys.toList()) {
      _stopVoice(id);
    }
  }

  /// Sets the user volume (0..1.5, 0 = mute), which also applies to future
  /// instances, and updates [instanceId] if it is live.
  @override
  Future<void> setVolumeFor(String instanceId, double volume) async {
    _userVolume = volume.clamp(0.0, 1.5);
    final voice = _voices[instanceId];
    if (voice != null) voice.gain.gain.value = _amplitude(voice);
  }

  @override
  bool isPlaying(String instanceId) =>
      _voices.containsKey(instanceId) || _pending.contains(instanceId);
}
