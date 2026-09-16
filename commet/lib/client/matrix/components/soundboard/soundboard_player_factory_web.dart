import 'package:commet/client/components/soundboard/soundboard_engine.dart';
import 'package:commet/client/matrix/components/soundboard/soundboard_player_factory.dart';
import 'package:commet/client/matrix/components/soundboard/web_audio_soundboard_player.dart';

SoundboardPlayer createSoundboardPlayer({
  required SoundResolver resolveSound,
  required UriResolver resolvePlayableUri,
  required BytesLoader loadBytes,
  void Function(String instanceId)? onInstanceFinished,
}) =>
    WebAudioSoundboardPlayer(
      resolveSound: resolveSound,
      loadBytes: loadBytes,
      onInstanceFinished: onInstanceFinished,
    );
