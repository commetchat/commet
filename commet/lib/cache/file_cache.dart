import 'dart:io';

import 'package:commet/cache/cached_file.dart';
import 'package:commet/config/app_config.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/utils/rng.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileCacheInstance {
  Isar? db;
  IsarCollection<CachedFile>? files;

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
    final dir = p.join(await AppConfig.getDatabasePath(), "cache");
    var directory = Directory(dir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    db =
        await Isar.open([CachedFileSchema], directory: dir, name: "file_cache");

    files = db!.collection<CachedFile>();
    clean();
  }

  Future<CachedFile?> _getByFileId(String fileId) async {
    return await files!.filter().fileIdEqualTo(fileId).findFirst();
  }

  Future<bool> hasFile(String identifier) async {
    var file = await _getByFileId(identifier);
    if (file == null) return false;

    // if the file exists in the database but not on disk, we should remove it from db
    var exists = await File(file.filePath).exists();
    if (!exists)
      await db!.writeTxn(() async {
        files!.delete(file.id);
      });

    return exists;
  }

  Future<Uri?> getFile(String identifier) async {
    if (!await hasFile(identifier)) return null;

    var entry = await _getByFileId(identifier);
    if (entry == null) return null;
    //var lastAccess = DateTime.fromMillisecondsSinceEpoch(entry!.lastAccessedTimestamp).toLocal().toString();

    entry.lastAccessedTimestamp = DateTime.now().millisecondsSinceEpoch;

    db!.writeTxn(() async {
      await files!.put(entry);
    });

    var file = File(entry.filePath);

    return file.uri;
  }

  Future<Uri> putFile(String identifier, Uint8List bytes) async {
    var path = await generateTempFilePath();
    if (BuildConfig.DEBUG) path += "_${Uri.encodeComponent(identifier)}";
    var file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);

    CachedFile entry = CachedFile(
        file.path, identifier, DateTime.now().millisecondsSinceEpoch);

    db!.writeTxn(() async {
      await files!.put(entry);
    });

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

    CachedFile entry = CachedFile(
        file.path, identifier, DateTime.now().millisecondsSinceEpoch);

    db!.writeTxn(() async {
      await files!.put(entry);
    });

    return file.uri;
  }

  Future<void> clean() async {
    if (kDebugMode) {
      print("Cleaning files");
    }

    var now = DateTime.now();
    var cutoffTime = now.subtract(const Duration(days: 2));
    var timeMs = cutoffTime.millisecondsSinceEpoch;

    var removeFiles =
        await files!.filter().lastAccessedTimestampLessThan(timeMs).findAll();

    var allFiles = await files!.where().findAll();

    if (kDebugMode) {
      print(
          "Found: ${removeFiles.length}/${allFiles.length} files for cleaning");
    }

    for (var file in removeFiles) {
      _cleanFile(file);
    }

    db!.writeTxn(() async {
      files!.deleteAll(removeFiles.map((e) => e.id).toList());
    });
  }

  Future<void> _cleanFile(CachedFile entry) async {
    var file = File(entry.filePath);
    if (!await file.exists()) {
      return;
    }

    file.delete();
  }

  // static bool _shouldRemoveFile(
  //     {required DateTime lastAccessedTime, required int fileSize}) {
  //   const largeFileSize = 10 * 1048576; //Ten Megabytes
  //   var diff = DateTime.now().difference(lastAccessedTime);

  //   if (fileSize > largeFileSize) {
  //     return diff.inDays > 1;
  //   }

  //   return true;
  // }
}
