import 'dart:io';

import 'package:commet/config/app_config.dart';
import 'package:commet/diagnostic/diagnostics.dart';
import 'package:commet/utils/multiple_database_server.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix_dart_sdk_drift_db/matrix_dart_sdk_drift_db.dart';
import 'package:path/path.dart' as p;

Future<DatabaseApi> getMatrixDatabaseImplementation(String clientName) async {
  var path = await AppConfig.getDriftDatabasePath();
  path = p.join(path, clientName, "data.db");
  var dir = p.dirname(path);

  if (!await Directory(dir).exists()) {
    await Directory(dir).create(recursive: true);
  }

  final file = File(path);

  var connection = await DatabaseIsolate.connect(file.absolute.path);

  return MatrixSdkDriftDatabase.init(connection, clientName,
      benchmark: benchmarkFunc);
}

Future<T> benchmarkFunc<T>(String name, Future<T> Function() func,
    [int? itemCount]) {
  return Diagnostics.databaseDiagnostics.timeAsync(name, func);
}

Future<DatabaseApi?> getLegacyMatrixDatabaseImplementation(
    String clientName) async {
  return null;
}
