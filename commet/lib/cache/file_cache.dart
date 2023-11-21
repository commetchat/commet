import 'dart:io';
import 'dart:typed_data';

import 'package:commet/cache/cached_file.dart';
import 'package:commet/config/app_config.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/utils/rng.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileCacheInstance {
  BoxCollection? db;
  CollectionBox<CachedFile>? filesBox;

  Future<String> newPath() async {
    final dir = await getTemporaryDirectory();
    String fileName = RandomUtils.getRandomString(30);
    return p.join(dir.path, "chat.commet.app", "file_cache", fileName);
  }

  Future<String> generateTempFilePath() async {
    var path = "";
    for (path = await newPath();
        await File(path).exists();
        path = await newPath()) {}

    return path;
  }

  Future<void> init() async {
    var adapter = CachedFileAdapter();

    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }

    db = await BoxCollection.open("file_cache", {"files"},
        path: await AppConfig.getDatabasePath());
    filesBox = await db!.openBox("files");
  }

  Future<bool> hasFile(String identifier) async {
    var file = await filesBox!.get(identifier);
    if (file == null) return false;

    // if the file exists in the database but not on disk, we should remove it from db
    var exists = await File(file.filePath).exists();
    if (!exists) await filesBox!.delete(identifier);

    return exists;
  }

  Future<Uri?> getFile(String identifier) async {
    if (!await hasFile(identifier)) return null;

    var entry = await filesBox!.get(identifier);
    if (entry == null) return null;
    //var lastAccess = DateTime.fromMillisecondsSinceEpoch(entry!.lastAccessedTimestamp).toLocal().toString();

    entry.lastAccessedTimestamp = DateTime.now().millisecondsSinceEpoch;
    entry.save();

    var file = File(entry.filePath);

    return file.uri;
  }

  Future<Uri> putFile(String identifier, Uint8List bytes) async {
    var path = await generateTempFilePath();
    if (BuildConfig.DEBUG) path += "_${Uri.encodeComponent(identifier)}";
    var file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);

    CachedFile entry =
        CachedFile(file.path, DateTime.now().millisecondsSinceEpoch);
    filesBox!.put(identifier, entry);

    return file.uri;
  }

  Future<Uri> fetchFile(
      String identifier, Future<Uint8List> Function() getter) async {
    var existing = await getFile(identifier);
    if (existing != null) return existing;

    var bytes = await getter();
    var path = await generateTempFilePath();
    if (BuildConfig.DEBUG) path += "_${Uri.encodeComponent(identifier)}";

    var file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);

    CachedFile entry =
        CachedFile(file.path, DateTime.now().millisecondsSinceEpoch);
    filesBox!.put(identifier, entry);

    return file.uri;
  }

  Future<void> clean() async {
    var keys = await filesBox!.getAllKeys();
    await Future.wait(keys.map((e) => _cleanFile(e)));
  }

  Future<void> _cleanFile(String key) async {
    if (filesBox == null) return;

    var entry = await filesBox!.get(key);
    if (entry == null) return;

    var file = File(entry.filePath);
    if (!await file.exists()) {
      entry.delete();
      return;
    }

    int size = await file.length();

    if (_shouldRemoveFile(
        lastAccessedTime:
            DateTime.fromMillisecondsSinceEpoch(entry.lastAccessedTimestamp),
        fileSize: size)) {
      await file.delete();
      await entry.delete();
    }
  }

  static bool _shouldRemoveFile(
      {required DateTime lastAccessedTime, required int fileSize}) {
    const largeFileSize = 10 * 1048576; //Ten Megabytes
    var diff = DateTime.now().difference(lastAccessedTime);

    if (fileSize > largeFileSize) {
      return diff.inDays > 1;
    }

    return diff.inDays > 3;
  }
}
