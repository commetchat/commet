// What this platform brings to the DJ booth. Desktop (Linux, Windows) can DJ:
// it has the Rust player, plays the DJ's own files and runs source
// extensions. Web and Android listen only.
import 'package:commet/client/components/dj/dj_engine.dart';
import 'package:commet/client/components/dj/dj_models.dart';
import 'package:commet/client/components/dj/dj_session.dart';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import 'dj_platform_stub.dart' if (dart.library.ffi) 'dj_platform_native.dart'
    as platform;

abstract class DjPlatform {
  /// `linux`, `windows`, `web`, `android`, ...
  String get name;

  bool get canDj;

  /// Null when [canDj] is false.
  DjEngineFactory? engineFactory(lk.Room room);

  DjResolver? get resolver;

  /// The source extensions, null where there are none ([canDj] false).
  DjSources? get sources;

  /// Queue entries for audio files on this computer, added by [addedBy].
  Future<List<DjTrack>> localTracks(List<String> paths,
      {required String addedBy, required String Function() newId});

  static final DjPlatform instance = platform.createDjPlatform();

  /// Files the DJ can add from their computer: what the player decodes.
  static const audioFileExtensions = [
    'mp3',
    'flac',
    'ogg',
    'oga',
    'opus',
    'm4a',
    'mp4',
    'aac',
    'wav',
    'webm',
  ];
}

/// An installed source extension, as the user sees it.
class DjSourceInfo {
  final String id;
  final String name;
  final String version;
  final String? description;
  final String? homepage;

  /// Where it was installed from, when that was a link: installing from it
  /// again updates it.
  final String? installedFrom;

  const DjSourceInfo({
    required this.id,
    required this.name,
    required this.version,
    this.description,
    this.homepage,
    this.installedFrom,
  });
}

/// An extension read from its package, not installed yet: what the install
/// prompt shows.
abstract class DjSourcePackage {
  DjSourceInfo get info;

  /// Programs it downloads when installed, as (name, size) with the size
  /// null when the manifest doesn't say.
  List<(String name, String? size)> get downloads;

  /// Set when the package can't be installed here, in words for the user.
  String? get problem;
}

/// Stops an install the user no longer wants.
class DjSourceCancel {
  bool cancelled = false;
  final List<void Function()> _onCancel = [];

  void onCancel(void Function() callback) => _onCancel.add(callback);

  void cancel() {
    cancelled = true;
    for (final callback in _onCancel) {
      callback();
    }
  }
}

class DjSourceCancelled implements Exception {
  const DjSourceCancelled();

  @override
  String toString() => 'Cancelled';
}

/// Installs, lists and removes source extensions (docs/dj-extensions.md).
abstract class DjSources {
  ValueListenable<List<DjSourceInfo>> get installed;

  /// Reads a package from a `.zip` on this computer.
  Future<DjSourcePackage> openFile(String path);

  /// Downloads a package from an `https://` link.
  Future<DjSourcePackage> openLink(String url, {DjSourceCancel? cancel});

  /// Installs [package] and downloads what it needs. [onProgress] gets what
  /// is being fetched and how far along it is (0..1, null while unknown).
  /// Throws [DjSourceCancelled] when [cancel] was used.
  Future<void> install(DjSourcePackage package,
      {void Function(String step, double? progress)? onProgress,
      DjSourceCancel? cancel});

  Future<void> remove(String id);
}
