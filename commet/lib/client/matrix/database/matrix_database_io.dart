import 'dart:io';

import 'package:commet/config/app_config.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix_dart_sdk_isar_db/matrix_dart_sdk_isar_db.dart';
import 'package:path/path.dart' as p;

Future<DatabaseApi> getMatrixDatabaseImplementation(String clientName) async {
  var path = await AppConfig.getIsarDatabasePath();
  path = p.join(path, clientName, "data.db");
  var dir = p.dirname(path);

  if (!await Directory(dir).exists()) {
    await Directory(dir).create(recursive: true);
  }

  var db = await MatrixSdkIsarDatabase.init(dir, clientName);
  return db;
}

Future<DatabaseApi> getLegacyMatrixDatabaseImplementation(
    String clientName) async {
  // ignore: deprecated_member_use
  final db = HiveCollectionsDatabase(
      clientName, await AppConfig.getHiveDatabasePath());
  await db.open();
  return db;
}
