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

import 'dart:math' as math;

import 'package:meta/meta.dart';

/// A simple class that represents dimensions of video.
@immutable
class VideoDimensions {
  final int width;
  final int height;

  const VideoDimensions(
    this.width,
    this.height,
  );

  @override
  String toString() => '${runtimeType}(${width}x${height})';

  VideoDimensions copyWith({
    int? width,
    int? height,
  }) =>
      VideoDimensions(
        width ?? this.width,
        height ?? this.height,
      );

  // ----------------------------------------------------------------------
  // equality

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is VideoDimensions && width == other.width && height == other.height;

  @override
  int get hashCode => Object.hash(width, height);
}

extension VideoDimensionsHelpers on VideoDimensions {
  // aspect ratios
  static const aspect169 = 16.0 / 9.0;
  static const aspect43 = 4.0 / 3.0;

  double aspect() => width > height ? width / height : height / width;

  /// Returns the larger value
  int max() => math.max(width, height);

  /// Returns the smaller value
  int min() => math.min(width, height);

  /// Simply returns the area
  int area() => width * height;
}

extension VideoDimensionsPresets on VideoDimensions {
  // 16:9 aspect ratio presets
  static const h90_169 = VideoDimensions(160, 90);
  static const h180_169 = VideoDimensions(320, 180);
  static const h216_169 = VideoDimensions(384, 216);
  static const h360_169 = VideoDimensions(640, 360);
  static const h540_169 = VideoDimensions(960, 540);
  static const h720_169 = VideoDimensions(1280, 720);
  static const h1080_169 = VideoDimensions(1920, 1080);
  static const h1440_169 = VideoDimensions(2560, 1440);
  static const h2160_169 = VideoDimensions(3840, 2160);

  // 4:3 aspect ratio presets
  static const h120_43 = VideoDimensions(160, 120);
  static const h180_43 = VideoDimensions(240, 180);
  static const h240_43 = VideoDimensions(320, 240);
  static const h360_43 = VideoDimensions(480, 360);
  static const h480_43 = VideoDimensions(640, 480);
  static const h540_43 = VideoDimensions(720, 540);
  static const h720_43 = VideoDimensions(960, 720);
  static const h1080_43 = VideoDimensions(1440, 1080);
  static const h1440_43 = VideoDimensions(1920, 1440);
}
