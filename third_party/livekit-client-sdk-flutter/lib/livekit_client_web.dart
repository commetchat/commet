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

import 'package:flutter/services.dart' show MethodChannel, StandardMethodCodec, PlatformException, MethodCall;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.

// ignore: unused_import
import 'package:web/web.dart' as web show document, HTMLScriptElement; // import_sorter: keep

/// A web implementation of the Livekit plugin.
class LiveKitWebPlugin {
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'livekit_client',
      const StandardMethodCodec(),
      registrar,
    );

    final pluginInstance = LiveKitWebPlugin();
    channel.setMethodCallHandler(pluginInstance.handleMethodCall);

    // Unofficial method load js as flutter assets (unreliable)
    // html.document.head!.append(html.ScriptElement()
    //   ..src = 'assets/packages/livekit_client/assets/ua-parser.min.js'
    //   ..type = 'application/javascript'
    //   ..defer = true
    //   );
  }

  /// Handles method calls over the MethodChannel of this plugin.
  /// Note: Check the "federated" architecture for a new way of doing this:
  /// https://flutter.dev/go/federated-plugins
  Future<dynamic> handleMethodCall(MethodCall call) async {
    // no-op for now
    throw PlatformException(
      code: 'Unimplemented',
      details: 'livekit for web doesn\'t implement \'${call.method}\'',
    );
  }
}
