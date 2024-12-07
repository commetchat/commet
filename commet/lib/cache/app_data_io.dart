import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:commet/cache/app_data.dart';
import 'package:commet/cache/app_data_db.dart';
import 'package:commet/cache/drift_error_log.dart';
import 'package:commet/cache/drift_file_cache.dart';
import 'package:commet/config/app_config.dart';
import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';

import 'package:path/path.dart' as p;

Future<void> initAppData(AppData self) async {
  var port = IsolateNameServer.lookupPortByName(AppDataDB.isolateName);

  var isolate =
      DriftIsolate.fromConnectPort(port ?? (await createIsolate()).connectPort);

  final db = AppDataDB(await isolate.connect());

  self.fileCache = DriftFileCache(db);
  self.errorLog = DriftErrorLog(db);

  await self.fileCache!.init();
}

Future<void> closeAppData(AppData self) async {}

Future<DriftIsolate> createIsolate() async {
  final token = RootIsolateToken.instance!;
  var isolate = await DriftIsolate.spawn(() {
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);

    return LazyDatabase(() async {
      final dir = p.join(await AppConfig.getDatabasePath(), "app");
      var directory = Directory(dir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = File(p.join(dir, "app_data.db"));
      return NativeDatabase(file);
    });
  }, isolateSpawn: _spawn);

  IsolateNameServer.registerPortWithName(
      isolate.connectPort, AppDataDB.isolateName);

  return isolate;
}

Future<Isolate> _spawn<T>(void Function(T message) entryPoint, T message) {
  return Isolate.spawn(entryPoint, message, debugName: "App Data Isolate");
}
