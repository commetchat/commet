import 'dart:io';
import 'dart:typed_data';

import 'package:commet/cache/cached_file.dart';
import 'package:commet/config/app_config.dart';
import 'package:commet/ui/pages/loading/loading_page.dart';
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
    final dir = await getTemporaryDirectory();

    var path = "";
    for (path = await newPath(); await File(path).exists(); path = await newPath()) {}

    return path;
  }

  Future<void> init() async {
    db = await BoxCollection.open("file_cache", {"files"}, path: await AppConfig.getDatabasePath());
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
    var lastAccess = DateTime.fromMillisecondsSinceEpoch(entry!.lastAccessedTimestamp).toLocal().toString();

    print("Accessing file: $identifier from cache, last accessed: $lastAccess");

    entry!.lastAccessedTimestamp = DateTime.now().millisecondsSinceEpoch;
    entry.save();

    var file = File(entry.filePath);

    return file.uri;
  }

  Future<Uri> fetchFile(String identifier, Future<Uint8List> Function() getter) async {
    var existing = await getFile(identifier);
    if (existing != null) return existing;

    print("File did not exist in cache, calling getter");

    var bytes = await getter();
    var path = await generateTempFilePath();

    var file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);

    print("wrote file to cache");
    print(path);

    CachedFile entry = CachedFile(file.path, DateTime.now().millisecondsSinceEpoch);
    filesBox!.put(identifier, entry);

    return file.uri;
  }
}
