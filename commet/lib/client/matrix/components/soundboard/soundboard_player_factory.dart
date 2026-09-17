// Picks the soundboard audio sink for the platform: media_kit (mpv) on
// native, Web Audio in the browser (media_kit's web player is an <audio>
// element whose volume cannot go above 1.0, so normalization boosts would
// be lost).
import 'dart:typed_data';

import 'package:commet/client/components/soundboard/soundboard_engine.dart';
import 'package:commet/client/components/soundboard/soundboard_sound.dart';

import 'soundboard_player_factory_native.dart'
    if (dart.library.js_interop) 'soundboard_player_factory_web.dart' as impl;

typedef SoundResolver = SoundboardSound? Function(String soundId);
typedef UriResolver = Future<String> Function(SoundboardSound sound);
typedef BytesLoader = Future<Uint8List> Function(SoundboardSound sound);

/// A player that can fetch and decode a sound before it is first played.
abstract interface class PreloadingSoundboardPlayer
    implements SoundboardPlayer {
  Future<void> preload(String soundId);
}

/// [resolvePlayableUri] feeds the native player (a cached file path);
/// [loadBytes] feeds the web one. [onInstanceFinished] is called when an
/// instance ends on its own (completion, error, unknown sound), not for
/// stop/stopAll.
SoundboardPlayer createSoundboardPlayer({
  required SoundResolver resolveSound,
  required UriResolver resolvePlayableUri,
  required BytesLoader loadBytes,
  void Function(String instanceId)? onInstanceFinished,
}) =>
    impl.createSoundboardPlayer(
      resolveSound: resolveSound,
      resolvePlayableUri: resolvePlayableUri,
      loadBytes: loadBytes,
      onInstanceFinished: onInstanceFinished,
    );
