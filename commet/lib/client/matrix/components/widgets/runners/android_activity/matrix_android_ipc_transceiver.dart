import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/debug/log.dart';
import 'package:mutex/mutex.dart';

class MatrixAndroidIpcTransceiver implements WidgetTransceiver {
  final ServerSocket socket;
  Socket? client;

  late int seperator;

  StreamController<Uint8List> _messageController = StreamController.broadcast();

  late Mutex mutex;

  MatrixAndroidIpcTransceiver(this.socket) {
    seperator = "\n".codeUnits.first;
    mutex = Mutex();
    startConnection();
  }

  @override
  Stream<Uint8List> get onReceived => _messageController.stream;

  Future<void> dispose() async {
    this.socket.close();
    client?.close();
  }

  @override
  void send(Uint8List data) async {
    Log.i("Waiting for mutex to send data");
    mutex.protect(() async {
      if (client != null) {
        Log.i("Sending data!");
        client!.writeln(Utf8Decoder().convert(data));
        await client!.flush();
      } else {
        Log.e("Client was null when trying to send data");
      }
    });
  }

  Future<void> startConnection() async {
    client = await socket.first;

    client!.listen(onData);
  }

  List<int> messageBuffer = List.empty(growable: true);

  void onData(Uint8List event) {
    messageBuffer += event;
    while (true) {
      int split = messageBuffer.indexOf(seperator);

      if (split != -1) {
        var msg = messageBuffer.sublist(0, split);
        messageBuffer.removeRange(0, split + 1);
        _messageController.add(Uint8List.fromList(msg));
      } else {
        return;
      }
    }
  }
}
