import 'dart:io';

import 'package:commet/config/app_config.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix_dart_sdk_drift_db/matrix_dart_sdk_drift_db.dart';
import 'package:path/path.dart' as p;
// ignore: depend_on_referenced_packages
import 'package:drift/native.dart';

Future<DatabaseApi> getMatrixDatabaseImplementation(String clientName) async {
  var path = await AppConfig.getDriftDatabasePath();
  path = p.join(path, clientName, "data.db");
  var dir = p.dirname(path);

  if (!await Directory(dir).exists()) {
    await Directory(dir).create(recursive: true);
  }

  var db = await MatrixSdkDriftDatabase.init(
      NativeDatabase.createInBackground(File(path)));
  return db;
}

Future<DatabaseApi?> getLegacyMatrixDatabaseImplementation(
    String clientName) async {
  return null;
}
