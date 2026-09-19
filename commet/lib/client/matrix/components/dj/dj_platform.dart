// What this platform brings to the DJ booth. Desktop (Linux, Windows) can DJ:
// it has the Rust player and runs yt-dlp. Web and Android listen only.
import 'package:commet/client/components/dj/dj_engine.dart';
import 'package:commet/client/components/dj/dj_session.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import 'dj_platform_stub.dart'
    if (dart.library.ffi) 'dj_platform_native.dart' as platform;

abstract class DjPlatform {
  /// `linux`, `windows`, `web`, `android`, ...
  String get name;

  bool get canDj;

  /// Null when [canDj] is false.
  DjEngineFactory? engineFactory(lk.Room room);

  DjResolver? get resolver;

  /// Checks the programs DJing needs; null when all are there, otherwise
  /// what is missing, for the consent prompt.
  Future<DjToolsCheck?> checkTools();

  /// Downloads what [checkTools] found missing. Throws
  /// [DjToolsCancelled] when [cancel] was used.
  Future<void> installTools(
      {void Function(String step, double? progress)? onProgress,
      DjToolsCancel? cancel});

  static final DjPlatform instance = platform.createDjPlatform();
}

/// Stops a tools download the user no longer wants.
class DjToolsCancel {
  bool cancelled = false;
  void Function()? onCancel;

  void cancel() {
    cancelled = true;
    onCancel?.call();
  }
}

class DjToolsCancelled implements Exception {
  const DjToolsCancelled();
}

class DjToolsCheck {
  /// Human names and sizes, e.g. ("yt-dlp", "18 MB").
  final List<(String name, String size)> missing;

  const DjToolsCheck(this.missing);
}
