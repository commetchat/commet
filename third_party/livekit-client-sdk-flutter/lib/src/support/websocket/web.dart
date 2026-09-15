// Copyright 2024 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../../extensions.dart';
import '../../logger.dart';
import '../websocket.dart';

// ignore: avoid_web_libraries_in_flutter

Future<LiveKitWebSocketWeb> lkWebSocketConnect(
  Uri uri, {
  WebSocketEventHandlers? options,
  Map<String, String>? headers, // |headers| will be ignored on web
}) =>
    LiveKitWebSocketWeb.connect(uri, options);

class LiveKitWebSocketWeb extends LiveKitWebSocket {
  final web.WebSocket _ws;
  final WebSocketEventHandlers? options;
  late final StreamSubscription _messageSubscription;
  late final StreamSubscription _closeSubscription;

  LiveKitWebSocketWeb._(
    this._ws, [
    this.options,
    Map<String, String>? headers, // ignore: unused_element_parameter
  ]) {
    _ws.binaryType = 'arraybuffer';
    _messageSubscription = _ws.onMessage.listen((event) {
      if (isDisposed) {
        logger.warning('$objectId already disposed, ignoring received data.');
        return;
      }
      final dynamic data =
          event.data.instanceOfString('ArrayBuffer') ? (event.data as JSArrayBuffer).toDart.asUint8List() : event.data;
      options?.onData?.call(data);
    });
    _closeSubscription = _ws.onClose.listen((_) async {
      await _messageSubscription.cancel();
      await _closeSubscription.cancel();
      options?.onDispose?.call();
    });

    onDispose(() async {
      if (_ws.readyState != web.WebSocket.CLOSED) {
        _ws.close();
      }
    });
  }

  @override
  void send(List<int> data) {
    _ws.send(Uint8List.fromList(data).toJS);
  }

  static Future<LiveKitWebSocketWeb> connect(
    Uri uri, [
    WebSocketEventHandlers? options,
  ]) async {
    final completer = Completer<LiveKitWebSocketWeb>();
    final ws = web.WebSocket(uri.toString());
    ws.onOpen.listen((_) => completer.complete(LiveKitWebSocketWeb._(ws, options)));
    ws.onError.listen((e) => completer.completeError(WebSocketException('Failed to connect', e)));
    return completer.future;
  }
}
