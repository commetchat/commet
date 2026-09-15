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

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb, kIsWasm;

import '../platform.dart';

PlatformType lkPlatformImplementation() {
  if (Platform.isWindows) return PlatformType.windows;
  if (Platform.isFuchsia) return PlatformType.fuchsia;
  if (Platform.isMacOS) return PlatformType.macOS;
  if (Platform.isLinux) return PlatformType.linux;
  if (Platform.isIOS) return PlatformType.iOS;
  if (Platform.isAndroid) return PlatformType.android;
  throw UnsupportedError('Unknown Platform');
}

bool lkPlatformIsWebMobileImplementation() {
  return false;
}

bool lkPlatformIsTestImplementation() => !kIsWeb && !kIsWasm && Platform.environment.containsKey('FLUTTER_TEST');

bool lkE2EESupportedImplementation() {
  return [
    PlatformType.windows,
    PlatformType.linux,
    PlatformType.macOS,
    PlatformType.iOS,
    PlatformType.android,
  ].contains(lkPlatformImplementation());
}

BrowserType lkBrowserImplementation() {
  return BrowserType.unknown;
}

BrowserVersion lkBrowserVersionImplementation() {
  return const BrowserVersion(0, 0, 0);
}
