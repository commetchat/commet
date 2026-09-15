// Copyright 2025 LiveKit, Inc.
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

import 'dart:typed_data' show Uint8List;

import 'package:flutter_webrtc/flutter_webrtc.dart' show MediaStreamTrack;

import 'audio_frame_capture_native.dart' if (dart.library.js_interop) 'audio_frame_capture_web.dart';

/// PCM sample format for audio frame capture.
enum AudioFormat {
  Int16('int16'),
  Float32('float32');

  final String value;
  const AudioFormat(this.value);
}

/// A single frame of raw PCM audio data.
class AudioFrame {
  final int sampleRate;
  final int channels;
  final Uint8List data;
  final AudioFormat format;

  const AudioFrame({
    required this.sampleRate,
    required this.channels,
    required this.data,
    required this.format,
  });
}

/// Platform-agnostic interface for capturing raw PCM audio frames from a track.
///
/// On native (iOS/Android), this uses MethodChannel + EventChannel.
/// On web, this uses Web Audio API with AudioWorklet.
abstract class AudioFrameCapture {
  /// Stream of raw PCM audio frames.
  Stream<AudioFrame> get frameStream;

  /// Start capturing audio from the given [track].
  ///
  /// Returns `true` if the renderer started successfully.
  Future<bool> start({
    required MediaStreamTrack track,
    required String rendererId,
    required int sampleRate,
    required int channels,
    required AudioFormat format,
  });

  /// Stop capturing and release resources.
  Future<void> stop();
}

/// Callback for receiving audio frames.
typedef AudioFrameCallback = void Function(AudioFrame frame);

/// Options for configuring audio frame capture format.
class AudioRendererOptions {
  final int sampleRate;
  final int channels;
  final AudioFormat format;

  const AudioRendererOptions({
    this.sampleRate = 24000,
    this.channels = 1,
    this.format = AudioFormat.Int16,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioRendererOptions &&
          sampleRate == other.sampleRate &&
          channels == other.channels &&
          format == other.format;

  @override
  int get hashCode => Object.hash(sampleRate, channels, format);
}

/// Factory that returns the platform-appropriate implementation.
AudioFrameCapture createAudioFrameCapture() => createAudioFrameCaptureImpl();
