import 'package:commet/client/components/dj/dj_engine.dart';
import 'package:commet/client/components/dj/dj_session.dart';
import 'package:commet/client/matrix/components/dj/dj_platform.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

DjPlatform createDjPlatform() => _ListenOnly();

/// The browser: plays the room's music, can't run yt-dlp.
class _ListenOnly implements DjPlatform {
  @override
  String get name => 'web';

  @override
  bool get canDj => false;

  @override
  DjEngineFactory? engineFactory(lk.Room room) => null;

  @override
  DjResolver? get resolver => null;

  @override
  Future<DjToolsCheck?> checkTools() async => null;

  @override
  Future<void> installTools(
      {void Function(String step, double? progress)? onProgress,
      DjToolsCancel? cancel}) async {}
}
