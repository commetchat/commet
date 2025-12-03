import 'dart:async';
import 'dart:convert';

import 'package:matrix_widget_api/matrix_widget_api.dart';
import 'package:js_interop_utils/js_interop_utils.dart';
import 'package:matrix_widget_api/types.dart';
import 'package:web/web.dart' as web;

// All top-level JS interop APIs need the @JS annotation.
@JS('dart_mx_widgets.WidgetApi')
extension type WidgetApi._(JSObject _) implements JSObject {
  external WidgetApi(String? id, String? targetOrigin);

  external void requestCapability(String capability);

  external void start();

  external void setContentLoaded();

  external void on(String event, JSAny callback);

  external MXTransport transport;
}

@JS()
extension type MXTransport._(JSObject _) implements JSObject {
  external JSPromise<JSObject> send(String fromWidgetAction, JSObject data);

  external void reply(JSObject detail, JSObject response);
}

class MatrixWidgetApiWeb implements MatrixWidgetApi {
  late WidgetApi w;

  @override
  String userId;

  StreamController _onReady = StreamController.broadcast();

  @override
  Stream<void> get onReady => _onReady.stream;

  MatrixWidgetApiWeb(
    String widgetId, {
    required this.userId,
    String supportedOrigins = "*",
  }) {
    print("Starting Widget API: $widgetId");
    w = WidgetApi(widgetId, supportedOrigins);
  }

  @override
  Future<void> requestCapabilities(List<String> capabilities) async {
    await w.transport
        .send(
          FromWidgetAction.renegotiateCapabilities,
          {"capabilities": capabilities}.toJSDeep,
        )
        .toDart;
  }

  void on(
    String event,
    Map<String, dynamic>? Function(Map<String, dynamic> data) callback, {
    preventDefaultHandler = false,
  }) {
    print("Listening to event: $event");
    void result(web.CustomEvent result) {
      var data = jsonDecode(jsonEncode(result.detail.asJSObject?.toMap()));
      var reply = callback(data ?? {});

      if (reply != null || preventDefaultHandler) {
        result.preventDefault();
      }

      if (reply != null) {
        w.transport.reply(result.detail.asJSObject!, reply.toJSDeep);
      }
    }

    w.on(event, result.toJS);
  }

  @override
  void onAction(
    String toWidgetAction,
    Map<String, dynamic>? Function(Map<String, dynamic> data) callback, {
    preventDefaultHandler = false,
  }) {
    on(
      "action:$toWidgetAction",
      callback,
      preventDefaultHandler: preventDefaultHandler,
    );
  }

  @override
  void start() {
    w.start();

    _onReady.add(());
  }

  @override
  Future<Map<String, dynamic>> sendAction(
    String fromWidgetAction,
    Map<String, dynamic> data,
  ) async {
    print("Sending data: $fromWidgetAction  $data");
    var promise = w.transport.send(fromWidgetAction, data.toJSDeep);
    var result = (await promise.toDart).toMap();
    print("Received result: $result");

    return result;
  }

  @override
  void stop() {
    // TODO: implement stop
  }
}
