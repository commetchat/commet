import 'dart:io';

import 'package:commet/client/components/dj/dj_engine.dart';
import 'package:commet/client/components/dj/dj_models.dart';
import 'package:commet/client/components/dj/dj_session.dart';
import 'package:commet/client/matrix/components/dj/dj_platform.dart';
import 'package:commet/client/matrix/components/dj/native/dj_extension_resolver.dart';
import 'package:commet/client/matrix/components/dj/native/dj_extensions.dart';
import 'package:commet/client/matrix/components/dj/native/dj_local_files.dart';
import 'package:commet/client/matrix/components/dj/native/dj_music_player.dart';
import 'package:commet/client/matrix/components/dj/native/native_dj_engine.dart';
import 'package:commet/main.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

DjPlatform createDjPlatform() => _NativeDjPlatform();

class _NativeDjPlatform implements DjPlatform {
  @override
  String get name => Platform.operatingSystem;

  /// Desktop with the Rust player built in. Android has no librust_lib_commet
  /// (cargokit is off there), so it listens only.
  @override
  late final bool canDj = (Platform.isLinux || Platform.isWindows) &&
      DjMusicBindings.load() != null;

  @override
  DjEngineFactory? engineFactory(lk.Room room) {
    final bindings = canDj ? DjMusicBindings.load() : null;
    if (bindings == null) return null;
    return () => NativeDjEngine(room, bindings,
        monitorVolume: preferences.djMusicVolume.value);
  }

  @override
  late final DjResolver? resolver =
      canDj ? DjExtensionResolver(DjExtensions.instance) : null;

  @override
  DjSources? get sources => canDj ? DjExtensions.instance : null;

  @override
  Future<List<DjTrack>> localTracks(List<String> paths,
      {required String addedBy, required String Function() newId}) async {
    if (!canDj) return const [];
    return [
      for (final path in paths)
        await DjLocalFiles.instance
            .track(path, id: newId(), addedBy: addedBy),
    ];
  }
}
