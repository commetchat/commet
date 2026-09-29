import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:commet/client/components/widgets/widget_component.dart';

class MatrixSubprocessWidgetTransceiver implements WidgetTransceiver {
  List<int> messageBuffer = List.empty(growable: true);

  late int seperator;

  Process process;

  StreamController<Uint8List> _messageController = StreamController.broadcast();

  MatrixSubprocessWidgetTransceiver({required this.process}) {
    seperator = "\n".codeUnits.first;

    process.stdout.listen((d) {
      messageBuffer += d;

      print("Received data: ${Utf8Decoder().convert(d)}-----------");

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
    });
  }

  @override
  Stream<Uint8List> get onReceived => _messageController.stream;

  @override
  void send(Uint8List data) {
    List<int> ints = List.from(data, growable: true);
    ints.add(seperator);

    process.stdin.add(ints);
  }
}
