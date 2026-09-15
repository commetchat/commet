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

import 'dart:async';
import 'dart:typed_data' show Uint8List;

import 'package:flutter/services.dart' show EventChannel;

import 'package:flutter_webrtc/flutter_webrtc.dart' show MediaStreamTrack;

import '../logger.dart';
import '../support/native.dart';
import 'audio_frame_capture.dart';

/// Native (iOS/Android/macOS) implementation using MethodChannel + EventChannel.
class AudioFrameCaptureNative implements AudioFrameCapture {
  EventChannel? _eventChannel;
  StreamSubscription? _streamSubscription;
  final _controller = StreamController<AudioFrame>.broadcast();
  String? _rendererId;

  @override
  Stream<AudioFrame> get frameStream => _controller.stream;

  @override
  Future<bool> start({
    required MediaStreamTrack track,
    required String rendererId,
    required int sampleRate,
    required int channels,
    required AudioFormat format,
  }) async {
    final result = await Native.startAudioRenderer(
      trackId: track.id!,
      rendererId: rendererId,
      format: {
        'commonFormat': format.value,
        'sampleRate': sampleRate,
        'channels': channels,
      },
    );

    if (result != true) return false;

    _rendererId = rendererId;

    _eventChannel = EventChannel('io.livekit.audio.renderer/channel-$rendererId');
    _streamSubscription = _eventChannel?.receiveBroadcastStream().listen((event) {
      try {
        final rawFormat = event['commonFormat'] as String?;
        _controller.add(AudioFrame(
          sampleRate: event['sampleRate'] as int,
          channels: event['channels'] as int,
          data: event['data'] as Uint8List,
          format: rawFormat == AudioFormat.Float32.value ? AudioFormat.Float32 : AudioFormat.Int16,
        ));
      } catch (e) {
        logger.warning('[AudioFrameCapture] Error parsing native event: $e');
      }
    });

    return true;
  }

  @override
  Future<void> stop() async {
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    _eventChannel = null;

    final rendererId = _rendererId;
    if (rendererId != null) {
      await Native.stopAudioRenderer(rendererId: rendererId);
      _rendererId = null;
    }

    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}

AudioFrameCapture createAudioFrameCaptureImpl() => AudioFrameCaptureNative();
