#!/usr/bin/env dart
/*
 * Copyright 2025 LiveKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:io';

import 'package:yaml/yaml.dart';

class _Path {
  static const pubspec = 'pubspec.yaml';
  static const iosPodspec = 'ios/livekit_client.podspec';
  static const macosPodspec = 'macos/livekit_client.podspec';
  static const livekitVersion = 'lib/src/livekit.dart';
}

class _Pattern {
  static final semanticVersion = RegExp(r'(\d+\.\d+\.\d+)');
  static final webrtcSdkVersion = RegExp(r"s\.dependency\s+'WebRTC-SDK',\s+'([^']+)'");
}

class _Color {
  static const reset = '\x1B[0m';
  static const green = '\x1B[32m';
  static const bold = '\x1B[1m';
}

String readFile(String path) {
  try {
    return File(path).readAsStringSync();
  } catch (e) {
    throw Exception('Failed to read $path: $e');
  }
}

String extractVersionFromPubspec() {
  final content = readFile(_Path.pubspec);
  final doc = loadYaml(content);
  final versionStr = doc['version'];

  final match = _Pattern.semanticVersion.firstMatch(versionStr);
  if (match == null) {
    throw Exception('Could not find version in ${_Path.pubspec}');
  }

  return match.group(0)!;
}

void checkVersionConsistency(String expectedVersion) {
  final filesToCheck = [
    _Path.iosPodspec,
    _Path.macosPodspec,
    _Path.livekitVersion,
  ];

  for (final file in filesToCheck) {
    final content = readFile(file);
    if (!content.contains(expectedVersion)) {
      final match = _Pattern.semanticVersion.firstMatch(content);
      final foundVersion = match?.group(0) ?? 'unknown';
      throw Exception('Version mismatch in $file: expected $expectedVersion, found $foundVersion');
    }
  }
}

void checkWebRtcSdkVersions() {
  final iosPodspec = readFile(_Path.iosPodspec);
  final macosPodspec = readFile(_Path.macosPodspec);

  final iosMatch = _Pattern.webrtcSdkVersion.firstMatch(iosPodspec);
  final macosMatch = _Pattern.webrtcSdkVersion.firstMatch(macosPodspec);

  if (iosMatch == null) {
    throw Exception('Could not find WebRTC-SDK version in ${_Path.iosPodspec}');
  }

  if (macosMatch == null) {
    throw Exception('Could not find WebRTC-SDK version in ${_Path.macosPodspec}');
  }

  final iosVersion = iosMatch.group(1)!;
  final macosVersion = macosMatch.group(1)!;

  if (iosVersion != macosVersion) {
    throw Exception('WebRTC-SDK version mismatch: iOS=$iosVersion, macOS=$macosVersion');
  }

  print('${_Color.green}WebRTC-SDK versions match: $iosVersion${_Color.reset}');
}

void main() {
  try {
    final version = extractVersionFromPubspec();
    print('Checking version ${_Color.bold}${_Color.green}$version${_Color.reset}');

    checkVersionConsistency(version);
    checkWebRtcSdkVersions();

    print('${_Color.bold}${_Color.green}All version checks passed ✓${_Color.reset}');
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
