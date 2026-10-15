import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/debug/log.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Note: Weird
///
/// This transceiver passes messages by storing the json data in
/// The Webview SessionStorage, and then passing the corresponding key.
/// This is to avoid sending large blobs through `evaluateJavascript`, which was causing
/// performance issues on windows.
///

class MatrixInAppWebViewWidgetTransceiver implements WidgetTransceiver {
  InAppWebViewController controller;
  MatrixInAppWebViewWidgetTransceiver(this.controller) {
    controller.addJavaScriptHandler(
        handlerName: "widget_handler", callback: onJsCallback);
  }

  onJsCallback(List<dynamic> arguments) async {
    var string = arguments.firstOrNull;

    if (string is! String) return;

    Log.i("Received message id: $string");
    final msg = await controller.webStorage.sessionStorage.getItem(key: string);

    await controller.webStorage.sessionStorage.removeItem(key: string);

    if (msg is! String) return;

    if (msg.startsWith("_") == false) return;

    final trimmed = msg.substring(1);

    _messageController.add(Utf8Encoder().convert(trimmed));
  }

  StreamController<Uint8List> _messageController = StreamController.broadcast();

  @override
  Stream<Uint8List> get onReceived => _messageController.stream;

  int msgCount = 0;

  @override
  void send(Uint8List data) async {
    var str = Utf8Decoder().convert(data);

    msgCount += 1;

    String id = "chat.commet.toWidget:" + msgCount.toString();

    await controller.webStorage.sessionStorage.setItem(key: id, value: str);

    Log.i("Sending message id: $id");

    var script = """
    var data = sessionStorage.getItem('${id}');
    window.onMessagePolyfill(data);
    sessionStorage.removeItem('${id}');
    """;

    controller.evaluateJavascript(source: script);
  }
}
