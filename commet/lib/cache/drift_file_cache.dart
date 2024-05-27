import 'dart:io';

import 'package:commet/cache/file_cache.dart';
import 'package:commet/config/app_config.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/rng.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'drift_file_cache.g.dart';

FileCache? getFileCacheImplementation() {
  return DriftFileCache();
}

class FileCacheEntry extends Table {
  TextColumn get id => text()();
  TextColumn get path => text()();

  IntColumn get lastAccessedTimestamp => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [FileCacheEntry])
class DriftFileCacheDatabase extends _$DriftFileCacheDatabase {
  DriftFileCacheDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

class DriftFileCache implements FileCache {
  bool isInit = false;
  late DriftFileCacheDatabase db;

  @override
  Future<void> clean() async {
    Log.i("Cleaning files");

    var now = DateTime.now();
    var cutoffTime = now.subtract(const Duration(days: 5));
    var timeMs = cutoffTime.millisecondsSinceEpoch;

    var removeFiles = await (db.select(db.fileCacheEntry)
          ..where(
              (tbl) => tbl.lastAccessedTimestamp.isSmallerThanValue(timeMs)))
        .get();

    var allFiles = await (db.select(db.fileCacheEntry).get());

    Log.i("Found: ${removeFiles.length}/${allFiles.length} files for cleaning");

    for (var file in removeFiles) {
      _cleanFile(file);
    }

    var removedIds = removeFiles.map((e) => e.id).toList();
    await (db.delete(db.fileCacheEntry)
          ..where((tbl) => tbl.id.isIn(removedIds)))
        .go();
  }

  Future<void> _cleanFile(FileCacheEntryData entry) async {
    var file = File(entry.path);
    if (!await file.exists()) {
      return;
    }

    file.delete();
  }

  @override
  Future<void> close() {
    return db.close();
  }

  @override
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

    var entry = FileCacheEntryCompanion.insert(
        id: identifier,
        path: path,
        lastAccessedTimestamp: DateTime.now().millisecondsSinceEpoch);

    await db.into(db.fileCacheEntry).insertOnConflictUpdate(entry);

    return file.uri;
  }

  @override
  Future<Uri?> getFile(String identifier) async {
    if (!await hasFile(identifier)) return null;

    var entry = await _getByFileId(identifier);
    if (entry == null) return null;
    //var lastAccess = DateTime.fromMillisecondsSinceEpoch(entry!.lastAccessedTimestamp).toLocal().toString();

    db.into(db.fileCacheEntry).insertOnConflictUpdate(entry.copyWith(
        lastAccessedTimestamp: DateTime.now().millisecondsSinceEpoch));

    var file = File(entry.path);

    return file.uri;
  }

  @override
  Future<bool> hasFile(String identifier) async {
    var file = await _getByFileId(identifier);
    if (file == null) return false;

    // if the file exists in the database but not on disk, we should remove it from db
    var exists = await File(file.path).exists();
    if (!exists)
      (db.delete(db.fileCacheEntry)..where((tbl) => tbl.id.equals(file.id)))
          .go();

    return exists;
  }

  @override
  Future<void> init() async {
    if (isInit) {
      return;
    }

    isInit = true;

    final dir = p.join(await AppConfig.getDatabasePath(), "app");
    var directory = Directory(dir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    db = DriftFileCacheDatabase(
        NativeDatabase.createInBackground(File(p.join(dir, "app_data.db"))));
    clean();
  }

  @override
  Future<Uri> putFile(String identifier, Uint8List bytes) async {
    var path = await generateTempFilePath();
    if (BuildConfig.DEBUG) path += "_${Uri.encodeComponent(identifier)}";
    var file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);

    var entry = FileCacheEntryCompanion.insert(
        id: identifier,
        path: path,
        lastAccessedTimestamp: DateTime.now().millisecondsSinceEpoch);

    await db.into(db.fileCacheEntry).insertOnConflictUpdate(entry);

    return file.uri;
  }

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

  Future<FileCacheEntryData?> _getByFileId(String fileId) async {
    return (db.select(db.fileCacheEntry)
          ..where((tbl) => tbl.id.equals(fileId))
          ..limit(1))
        .getSingleOrNull();
  }
}
