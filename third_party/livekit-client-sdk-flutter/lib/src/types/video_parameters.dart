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

import 'package:meta/meta.dart';

import 'video_dimensions.dart';
import 'video_encoding.dart';

@immutable
class VideoParameters implements Comparable<VideoParameters> {
  final String? description;
  final VideoDimensions dimensions;
  final VideoEncoding? encoding;

  const VideoParameters({
    required this.dimensions,
    this.description,
    this.encoding,
  });

  // ----------------------------------------------------------------------
  // equality

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoParameters &&
          description == other.description &&
          dimensions == other.dimensions &&
          encoding == other.encoding;

  @override
  int get hashCode => Object.hash(description, dimensions, encoding);

  // ----------------------------------------------------------------------
  // Comparable

  @override
  int compareTo(VideoParameters other) {
    // compare by dimension's area
    final result = dimensions.area().compareTo(other.dimensions.area());
    // if dimensions have equal area, compare by encoding
    if (result == 0 && encoding != null && other.encoding != null) {
      return encoding!.compareTo(other.encoding!);
    }

    return result;
  }

  //
  // TODO: Return constraints that will work for all platforms (Web & Mobile)
  // https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia
  //
  Map<String, dynamic> toMediaConstraintsMap() => <String, dynamic>{
        'width': dimensions.width,
        'height': dimensions.height,
        'frameRate': encoding?.maxFramerate ?? 30,
      };
}

extension VideoParametersPresets on VideoParameters {
  // 16:9 default
  static final List<VideoParameters> defaultSimulcast169 = [
    h180_169,
    h360_169,
  ];

  // 4:3 default
  static final List<VideoParameters> defaultSimulcast43 = [
    h180_43,
    h360_43,
  ];

  // all 16:9 presets
  static final List<VideoParameters> all169 = [
    h90_169,
    h180_169,
    h216_169,
    h360_169,
    h540_169,
    h720_169,
    h1080_169,
    h1440_169,
    h2160_169,
  ];

  // all 4:3 presets
  static final List<VideoParameters> all43 = [
    h120_43,
    h180_43,
    h240_43,
    h360_43,
    h480_43,
    h540_43,
    h720_43,
    h1080_43,
    h1440_43,
  ];

  // all screen share presets
  static final List<VideoParameters> allScreenShare = [
    screenShareH360FPS3,
    screenShareH720FPS5,
    screenShareH720FPS15,
    screenShareH1080FPS15,
    screenShareH1080FPS30,
  ];

  // 16:9 Presets
  static const h90_169 = VideoParameters(
    dimensions: VideoDimensionsPresets.h90_169,
    encoding: VideoEncoding(
      maxBitrate: 90 * 1000,
      maxFramerate: 15,
    ),
  );
  static const h180_169 = VideoParameters(
    dimensions: VideoDimensionsPresets.h180_169,
    encoding: VideoEncoding(
      maxBitrate: 160 * 1000,
      maxFramerate: 15,
    ),
  );

  static const h216_169 = VideoParameters(
    dimensions: VideoDimensionsPresets.h216_169,
    encoding: VideoEncoding(
      maxBitrate: 180 * 1000,
      maxFramerate: 15,
    ),
  );

  static const h360_169 = VideoParameters(
    dimensions: VideoDimensionsPresets.h360_169,
    encoding: VideoEncoding(
      maxBitrate: 450 * 1000,
      maxFramerate: 20,
    ),
  );

  static const h540_169 = VideoParameters(
    dimensions: VideoDimensionsPresets.h540_169,
    encoding: VideoEncoding(
      maxBitrate: 800 * 1000,
      maxFramerate: 25,
    ),
  );

  static const h720_169 = VideoParameters(
    dimensions: VideoDimensionsPresets.h720_169,
    encoding: VideoEncoding(
      maxBitrate: 1700 * 1000,
      maxFramerate: 30,
    ),
  );

  static const h1080_169 = VideoParameters(
    dimensions: VideoDimensionsPresets.h1080_169,
    encoding: VideoEncoding(
      maxBitrate: 3000 * 1000,
      maxFramerate: 30,
    ),
  );

  static const h1440_169 = VideoParameters(
    dimensions: VideoDimensionsPresets.h1440_169,
    encoding: VideoEncoding(
      maxBitrate: 5000 * 1000,
      maxFramerate: 30,
    ),
  );

  static const h2160_169 = VideoParameters(
    dimensions: VideoDimensionsPresets.h2160_169,
    encoding: VideoEncoding(
      maxBitrate: 8000 * 1000,
      maxFramerate: 30,
    ),
  );

  // 4:3 presets
  static const h120_43 = VideoParameters(
    dimensions: VideoDimensionsPresets.h120_43,
    encoding: VideoEncoding(
      maxBitrate: 70 * 1000,
      maxFramerate: 15,
    ),
  );

  static const h180_43 = VideoParameters(
    dimensions: VideoDimensionsPresets.h180_43,
    encoding: VideoEncoding(
      maxBitrate: 125 * 1000,
      maxFramerate: 15,
    ),
  );

  static const h240_43 = VideoParameters(
    dimensions: VideoDimensionsPresets.h240_43,
    encoding: VideoEncoding(
      maxBitrate: 140 * 1000,
      maxFramerate: 15,
    ),
  );

  static const h360_43 = VideoParameters(
    dimensions: VideoDimensionsPresets.h360_43,
    encoding: VideoEncoding(
      maxBitrate: 330 * 1000,
      maxFramerate: 20,
    ),
  );

  static const h480_43 = VideoParameters(
    dimensions: VideoDimensionsPresets.h480_43,
    encoding: VideoEncoding(
      maxBitrate: 500 * 1000,
      maxFramerate: 20,
    ),
  );

  static const h540_43 = VideoParameters(
    dimensions: VideoDimensionsPresets.h540_43,
    encoding: VideoEncoding(
      maxBitrate: 600 * 1000,
      maxFramerate: 25,
    ),
  );

  static const h720_43 = VideoParameters(
    dimensions: VideoDimensionsPresets.h720_43,
    encoding: VideoEncoding(
      maxBitrate: 1300 * 1000,
      maxFramerate: 30,
    ),
  );

  static const h1080_43 = VideoParameters(
    dimensions: VideoDimensionsPresets.h1080_43,
    encoding: VideoEncoding(
      maxBitrate: 2300 * 1000,
      maxFramerate: 30,
    ),
  );

  static const h1440_43 = VideoParameters(
    dimensions: VideoDimensionsPresets.h1440_43,
    encoding: VideoEncoding(
      maxBitrate: 3800 * 1000,
      maxFramerate: 30,
    ),
  );

  // Screen share
  static const screenShareH360FPS3 = VideoParameters(
    dimensions: VideoDimensionsPresets.h360_169,
    encoding: VideoEncoding(
      maxBitrate: 200 * 1000,
      maxFramerate: 3,
    ),
  );

  static const screenShareH720FPS5 = VideoParameters(
    dimensions: VideoDimensionsPresets.h720_169,
    encoding: VideoEncoding(
      maxBitrate: 400 * 1000,
      maxFramerate: 5,
    ),
  );

  static const screenShareH720FPS15 = VideoParameters(
    dimensions: VideoDimensionsPresets.h720_169,
    encoding: VideoEncoding(
      maxBitrate: 1500 * 1000,
      maxFramerate: 15,
    ),
  );

  static const screenShareH1080FPS15 = VideoParameters(
    dimensions: VideoDimensionsPresets.h1080_169,
    encoding: VideoEncoding(
      maxBitrate: 2500 * 1000,
      maxFramerate: 15,
    ),
  );

  static const screenShareH1080FPS30 = VideoParameters(
    dimensions: VideoDimensionsPresets.h1080_169,
    encoding: VideoEncoding(
      maxBitrate: 4000 * 1000,
      maxFramerate: 30,
    ),
  );

  static const screenShareH1440FPS30 = VideoParameters(
    dimensions: VideoDimensionsPresets.h1440_169,
    encoding: VideoEncoding(
      maxBitrate: 6000 * 1000,
      maxFramerate: 30,
    ),
  );

  static const screenShareH2160FPS30 = VideoParameters(
    dimensions: VideoDimensionsPresets.h2160_169,
    encoding: VideoEncoding(
      maxBitrate: 8000 * 1000,
      maxFramerate: 30,
    ),
  );
}
