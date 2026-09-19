import 'dart:io';

import 'package:commet/client/components/dj/dj_engine.dart';
import 'package:commet/client/components/dj/dj_session.dart';
import 'package:commet/client/matrix/components/dj/dj_platform.dart';
import 'package:commet/client/matrix/components/dj/native/dj_link_resolver.dart';
import 'package:commet/client/matrix/components/dj/native/dj_music_player.dart';
import 'package:commet/client/matrix/components/dj/native/dj_tools.dart';
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
  late final DjResolver? resolver = canDj ? NativeDjLinkResolver() : null;

  @override
  Future<DjToolsCheck?> checkTools() async {
    if (!canDj) return null;
    if (await DjTools.instance.locate() != null) return null;
    final missing = await DjTools.instance.missing();
    return DjToolsCheck([
      if (missing.contains(DjTool.ytDlp))
        ('yt-dlp', DjTools.downloadSizes[DjTool.ytDlp]!),
      if (missing.contains(DjTool.jsRuntime))
        ('Deno', DjTools.downloadSizes[DjTool.jsRuntime]!),
    ]);
  }

  @override
  Future<void> installTools(
      {void Function(String step, double? progress)? onProgress,
      DjToolsCancel? cancel}) async {
    final downloads = DjDownloadCancel();
    cancel?.onCancel = downloads.cancel;
    try {
      await DjTools.instance.install(
          cancel: downloads,
          onProgress: (tool, progress) => onProgress?.call(
              tool == DjTool.ytDlp ? 'yt-dlp' : 'Deno', progress));
    } on DjDownloadCancelled {
      throw const DjToolsCancelled();
    }
  }
}
