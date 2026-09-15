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

import '../support/disposable.dart';
import 'websocket/io.dart' if (dart.library.js_interop) 'websocket/web.dart';

class WebSocketException implements Exception {
  final String message;
  final dynamic error;
  const WebSocketException(this.message, [this.error]);
}

typedef WebSocketOnData = Function(dynamic data);
typedef WebSocketOnError = Function(dynamic error);
typedef WebSocketOnDispose = Function();

class WebSocketEventHandlers {
  final WebSocketOnData? onData;
  final WebSocketOnError? onError;
  final WebSocketOnDispose? onDispose;

  const WebSocketEventHandlers({
    this.onData,
    this.onError,
    this.onDispose,
  });
}

typedef WebSocketConnector = Future<LiveKitWebSocket> Function(
  Uri uri, {
  WebSocketEventHandlers? options,
  Map<String, String>? headers,
});

abstract class LiveKitWebSocket extends Disposable {
  void send(List<int> data);

  static Future<LiveKitWebSocket> connect(
    Uri uri, {
    WebSocketEventHandlers? options,
    Map<String, String>? headers,
  }) =>
      lkWebSocketConnect(uri, options: options, headers: headers);
}
