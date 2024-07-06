import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:commet/config/app_config.dart';
import 'package:commet/diagnostic/diagnostics.dart';
import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:flutter/services.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix_dart_sdk_drift_db/matrix_dart_sdk_drift_db.dart';
import 'package:path/path.dart' as p;
// ignore: depend_on_referenced_packages
import 'package:drift/native.dart';

Future<DatabaseApi> getMatrixDatabaseImplementation(String clientName) async {
  var port =
      IsolateNameServer.lookupPortByName(_getIsolateNameForClient(clientName));

  var isolate = DriftIsolate.fromConnectPort(
      port ?? (await _createIsolate(clientName)).connectPort);

  return MatrixSdkDriftDatabase.init(await isolate.connect(), clientName,
      benchmark: benchmarkFunc);
}

Future<T> benchmarkFunc<T>(String name, Future<T> Function() func,
    [int? itemCount]) {
  return Diagnostics.databaseDiagnostics.timeAsync(name, func);
}

Future<DriftIsolate> _createIsolate(String clientName) async {
  final token = RootIsolateToken.instance!;
  var isolate = await DriftIsolate.spawn(
    () {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);

      return LazyDatabase(() async {
        var path = await AppConfig.getDriftDatabasePath();
        path = p.join(path, clientName, "data.db");
        var dir = p.dirname(path);

        if (!await Directory(dir).exists()) {
          await Directory(dir).create(recursive: true);
        }

        final file = File(path);
        return NativeDatabase(file);
      });
    },
    isolateSpawn: <T>(Function(T message) entryPoint, T message) {
      return Isolate.spawn(entryPoint, message,
          debugName: "Client $clientName DB Isolate");
    },
  );

  IsolateNameServer.registerPortWithName(
      isolate.connectPort, _getIsolateNameForClient(clientName));

  return isolate;
}

String _getIsolateNameForClient(String clientName) {
  return "chat.commet.commetapp.isolate.client_$clientName";
}

Future<DatabaseApi?> getLegacyMatrixDatabaseImplementation(
    String clientName) async {
  return null;
}
