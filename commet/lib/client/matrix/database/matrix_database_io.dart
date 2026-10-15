import 'dart:io';

import 'package:commet/config/app_config.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/diagnostic/diagnostics.dart';
import 'package:commet/utils/database/multiple_database_server.dart';
import 'package:drift/native.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix_dart_sdk_drift_db/matrix_dart_sdk_drift_db.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

Future<DatabaseApi> getMatrixDatabaseImplementation(String clientName,
    {bool onDatabaseIsolate = true, bool readOnly = false}) async {
  var path = await AppConfig.getDriftDatabasePath();
  path = p.join(path, clientName, "data.db");
  var dir = p.dirname(path);

  if (!await Directory(dir).exists()) {
    await Directory(dir).create(recursive: true);
  }

  final file = File(path);

  if (onDatabaseIsolate) {
    var connection =
        await DatabaseIsolate.connect(file.absolute.path, readOnly: readOnly);

    return MatrixSdkDriftDatabase.init(connection, clientName,
        benchmark: benchmarkFunc);
  } else {
    var connection = setupNativeDatabase(file, readOnly: readOnly);
    return MatrixSdkDriftDatabase.init(connection, clientName,
        benchmark: benchmarkFunc);
  }
}

NativeDatabase setupNativeDatabase(File file, {bool readOnly = false}) {
  final db = sqlite.sqlite3.open(file.path,
      mode: readOnly
          ? sqlite.OpenMode.readOnly
          : sqlite.OpenMode.readWriteCreate);

  Log.d("Opening database (readonly: $readOnly) ${file.path}");

  return NativeDatabase.opened(
    db,
    setup: (database) {
      if (!readOnly) {
        database.execute("pragma journal_mode = wal;");
      }
    },
  );
}

Future<T> benchmarkFunc<T>(String name, Future<T> Function() func,
    [int? itemCount]) {
  return Diagnostics.databaseDiagnostics.timeAsync(name, func);
}

Future<DatabaseApi?> getLegacyMatrixDatabaseImplementation(
    String clientName) async {
  return null;
}
