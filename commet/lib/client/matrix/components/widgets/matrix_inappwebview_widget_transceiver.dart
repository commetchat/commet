import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/debug/log.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class MatrixInAppWebViewWidgetTransceiver implements WidgetTransceiver {
  InAppWebViewController controller;
  MatrixInAppWebViewWidgetTransceiver(this.controller) {
    controller.addJavaScriptHandler(
        handlerName: "widget_handler", callback: onJsCallback);
  }

  onJsCallback(List<dynamic> arguments) {
    var string = arguments.firstOrNull;
    Log.i(string);
    if (string is String) {
      Log.i("JS Callback Received Data: ${string}");

      _messageController.add(Utf8Encoder().convert(string));
    }
  }

  StreamController<Uint8List> _messageController = StreamController.broadcast();

  @override
  Stream<Uint8List> get onReceived => _messageController.stream;

  @override
  void send(Uint8List data) {
    var str = Utf8Decoder().convert(data);

    var script = """
    window.onMessagePolyfill(${jsonEncode(str)});
    """;

    Log.i("Executing Script: $script");

    controller.evaluateJavascript(source: script);
  }
}
