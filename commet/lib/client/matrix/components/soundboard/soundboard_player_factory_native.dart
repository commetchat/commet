import 'package:commet/client/components/soundboard/soundboard_engine.dart';
import 'package:commet/client/matrix/components/soundboard/mediakit_soundboard_player.dart';
import 'package:commet/client/matrix/components/soundboard/soundboard_player_factory.dart';

SoundboardPlayer createSoundboardPlayer({
  required SoundResolver resolveSound,
  required UriResolver resolvePlayableUri,
  required BytesLoader loadBytes,
  void Function(String instanceId)? onInstanceFinished,
}) =>
    MediaKitSoundboardPlayer(
      resolveSound: resolveSound,
      resolvePlayableUri: resolvePlayableUri,
      onInstanceFinished: onInstanceFinished,
    );
