import 'dart:convert';
import 'dart:typed_data';

import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/utils/notifying_list.dart';

class MatrixWidgetBlob {
  Uint8List bytes;

  MatrixWidgetBlob(this.bytes);
}

class MatrixWidgetTransport implements WidgetMessageTransport {
  WidgetTransceiver transceiver;

  MatrixWidgetTransport(this.transceiver);

  @override
  NotifyingList<(WidgetMessageDirection, Map<String, dynamic>)> messageLogs =
      NotifyingList.empty(growable: true);

  dynamic decodeArrayBuffers(dynamic input) {
    if (input is Map<String, dynamic>) {
      if (input['__type'] == 'ArrayBuffer' && input['data'] is String) {
        return base64Decode(input['data']);
      }

      return input.map(
        (key, value) => MapEntry(key, decodeArrayBuffers(value)),
      );
    }

    if (input is List) {
      return input.map(decodeArrayBuffers).toList();
    }

    return input;
  }

  dynamic encodeArrayBuffers(dynamic input) {
    if (input is Uint8List) {
      return {
        '__type': 'ArrayBuffer',
        'data': base64Encode(input),
      };
    }

    if (input is MatrixWidgetBlob) {
      return {
        '__type': 'Blob',
        'data': base64Encode(input.bytes),
      };
    }

    if (input is List) {
      return input.map(encodeArrayBuffers).toList();
    }

    if (input is Map) {
      return input.map(
        (key, value) => MapEntry(key, encodeArrayBuffers(value)),
      );
    }

    return input;
  }

  @override
  Stream<Map<String, dynamic>> get onReceived =>
      transceiver.onReceived.map((i) {
        var decoded = jsonDecode(Utf8Decoder().convert(i));
        decoded = decodeArrayBuffers(decoded);

        messageLogs.add((WidgetMessageDirection.incoming, decoded));
        return decoded;
      });

  @override
  void send(Map<String, dynamic> msg) {
    var encoded = encodeArrayBuffers(msg);
    messageLogs.add(
        (WidgetMessageDirection.outgoing, Map<String, dynamic>.from(encoded)));

    transceiver.send(Utf8Encoder().convert(jsonEncode(encoded)));
  }
}
