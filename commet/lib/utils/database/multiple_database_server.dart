import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';

final class MultiDatabaseServer {
  final Map<String, DriftIsolate> _activeIsolates = {};
  final ReceivePort _receiveConnections = ReceivePort();

  MultiDatabaseServer() {
    _receiveConnections.listen((message) {
      if (message is (String, SendPort)) {
        final name = message.$1;
        final isolate = _activeIsolates.putIfAbsent(
          name,
          () {
            return DriftIsolate.inCurrent(
                // obviously you can pass a path instead of a name and use that to open the right NativeDatabase
                () => NativeDatabase(File(name)));
          },
        );

        message.$2.send(isolate.connectPort);
      }
    });
  }
}

class DatabaseIsolate {
  static final receiveConnectPort = ReceivePort();
  static SendPort? connectToServer;
  static const isolateName = "chat.commet.commetapp.database_isolate";

  static Future<void> start() async {
    connectToServer = IsolateNameServer.lookupPortByName(isolateName);
    if (connectToServer == null) {
      Isolate.spawn(
        (SendPort port) {
          final server = MultiDatabaseServer();
          port.send(server._receiveConnections.sendPort);
        },
        receiveConnectPort.sendPort,
        debugName: "Database Isolate",
      );

      connectToServer = await receiveConnectPort.first as SendPort;
      IsolateNameServer.registerPortWithName(connectToServer!, isolateName);
    }
  }

  static Future<DatabaseConnection> connect(String databaseName) async {
    final response = ReceivePort();
    connectToServer!.send((databaseName, response.sendPort));

    final connectPort = await response.first as SendPort;
    return DriftIsolate.fromConnectPort(connectPort, serialize: false)
        .connect();
  }
}
