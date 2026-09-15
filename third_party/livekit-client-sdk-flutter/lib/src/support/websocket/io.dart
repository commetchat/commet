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
import 'dart:io' as io;

import '../../extensions.dart';
import '../../logger.dart';
import '../websocket.dart';

Future<LiveKitWebSocketIO> lkWebSocketConnect(
  Uri uri, {
  WebSocketEventHandlers? options,
  Map<String, String>? headers,
}) =>
    LiveKitWebSocketIO.connect(uri, options: options, headers: headers);

class LiveKitWebSocketIO extends LiveKitWebSocket {
  final io.WebSocket _ws;
  final WebSocketEventHandlers? options;
  late final StreamSubscription _subscription;

  LiveKitWebSocketIO._(
    this._ws, [
    this.options,
  ]) {
    _subscription = _ws.listen(
      (dynamic data) {
        if (isDisposed) {
          logger.warning('$objectId already disposed, ignoring received data.');
          return;
        }
        options?.onData?.call(data);
      },
      onDone: () async {
        await _subscription.cancel();
        options?.onDispose?.call();
      },
    );

    onDispose(() async {
      if (_ws.readyState != io.WebSocket.closed) {
        await _ws.close();
      }
    });
  }

  @override
  void send(List<int> data) {
    if (_ws.readyState != io.WebSocket.open) {
      logger.fine('[$objectId] Socket not open (state: ${_ws.readyState})');
      return;
    }

    try {
      _ws.add(data);
    } catch (e) {
      logger.fine('[$objectId] send did throw $e');
    }
  }

  static Future<LiveKitWebSocketIO> connect(
    Uri uri, {
    WebSocketEventHandlers? options,
    Map<String, String>? headers,
  }) async {
    logger.fine('[WebSocketIO] Connecting(uri: ${uri.toString()})...');
    try {
      final ws = await io.WebSocket.connect(uri.toString(), headers: headers);
      logger.fine('[WebSocketIO] Connected');
      return LiveKitWebSocketIO._(ws, options);
    } catch (err) {
      logger.severe('[WebSocketIO] did throw $err');
      throw WebSocketException('Failed to connect', err);
    }
  }
}
