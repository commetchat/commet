import 'file_cache_stub.dart'
    if (dart.library.io) "package:commet/cache/isar_file_cache.dart";

import 'package:flutter/foundation.dart';

abstract class FileCache {
  Future<void> init();

  Future<void> close();

  Future<bool> hasFile(String identifier);

  Future<Uri?> getFile(String identifier);

  Future<Uri> putFile(String identifier, Uint8List bytes);

  Future<Uri> fetchFile(String identifier, Future<Uint8List> Function() getter);

  Future<void> clean();

  static FileCache? getFileCacheInstance() {
    return getFileCacheImplementation();
  }
}
