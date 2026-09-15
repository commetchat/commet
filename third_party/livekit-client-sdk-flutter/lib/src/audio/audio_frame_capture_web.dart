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
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data' show Uint8List;

import 'package:dart_webrtc/dart_webrtc.dart' show MediaStreamTrackWeb;
import 'package:flutter_webrtc/flutter_webrtc.dart' show MediaStreamTrack;
import 'package:web/web.dart' as web;

import '../logger.dart';
import 'audio_frame_capture.dart';
import 'audio_pcm_utils.dart';

/// JavaScript source for the AudioWorkletProcessor.
///
/// Runs on the audio rendering thread. Forwards raw float32 input samples
/// to the main thread via MessagePort.
const _workletProcessorJs = '''
class AudioRendererProcessor extends AudioWorkletProcessor {
  process(inputs, outputs, parameters) {
    const input = inputs[0];
    if (input && input.length > 0 && input[0].length > 0) {
      const channels = input.length;
      const frames = input[0].length;

      // Interleave channels into a single Float32Array.
      const interleaved = new Float32Array(frames * channels);
      for (let frame = 0; frame < frames; frame++) {
        for (let ch = 0; ch < channels; ch++) {
          interleaved[frame * channels + ch] = input[ch][frame];
        }
      }

      this.port.postMessage({
        samples: interleaved.buffer,
        channels: channels,
        frames: frames,
      }, [interleaved.buffer]);
    }
    return true;
  }
}
registerProcessor('audio-renderer-processor', AudioRendererProcessor);
''';

/// Web implementation using AudioWorklet to capture raw PCM frames.
class AudioFrameCaptureWeb implements AudioFrameCapture {
  web.AudioContext? _audioContext;
  web.AudioWorkletNode? _workletNode;
  web.AudioNode? _sourceNode;
  StreamController<AudioFrame>? _controller;
  AudioFormat _targetFormat = AudioFormat.Int16;
  int _targetChannels = 1;

  @override
  Stream<AudioFrame> get frameStream => (_controller ??= StreamController<AudioFrame>.broadcast()).stream;

  @override
  Future<bool> start({
    required MediaStreamTrack track,
    required String rendererId,
    required int sampleRate,
    required int channels,
    required AudioFormat format,
  }) async {
    _targetFormat = format;
    _targetChannels = channels;
    _controller ??= StreamController<AudioFrame>.broadcast();

    try {
      // 1. Get the underlying JS MediaStreamTrack.
      final jsTrack = (track as MediaStreamTrackWeb).jsTrack;
      final mediaStream = web.MediaStream([jsTrack].toJS);

      // 2. Create AudioContext at the requested sample rate and best-effort resume it because some browsers require a user gesture and may reject or stall resume()
      _audioContext = web.AudioContext(web.AudioContextOptions(sampleRate: sampleRate.toDouble()));
      final ctx = _audioContext!;
      try {
        await ctx.resume().toDart.timeout(const Duration(seconds: 3));
      } on TimeoutException {
        logger.warning('[AudioFrameCapture] AudioContext resume timed out, continuing setup');
      } catch (e) {
        logger.warning('[AudioFrameCapture] AudioContext resume failed: $e, continuing setup');
      }

      // 3. Register worklet processor via Blob URL.
      final blob = web.Blob(
        [_workletProcessorJs.toJS].toJS,
        web.BlobPropertyBag(type: 'application/javascript'),
      );
      final blobUrl = web.URL.createObjectURL(blob);
      try {
        await ctx.audioWorklet.addModule(blobUrl).toDart;
      } finally {
        web.URL.revokeObjectURL(blobUrl);
      }

      // 4. Create audio pipeline: source → worklet → destination.
      _sourceNode = ctx.createMediaStreamSource(mediaStream);
      _workletNode = web.AudioWorkletNode(ctx, 'audio-renderer-processor');

      _sourceNode!.connect(_workletNode!);
      // No destination connection needed — process() is called as long as
      // there is input flowing and it returns true. Connecting to
      // ctx.destination would route mic audio to speakers (echo/feedback).

      // 5. Listen for PCM frames from the worklet thread.
      _workletNode!.port.onmessage = _onWorkletMessage.toJS;

      return true;
    } catch (e) {
      logger.warning('[AudioFrameCapture] Failed to start web capture: $e');
      await stop();
      return false;
    }
  }

  void _onWorkletMessage(web.MessageEvent event) {
    final controller = _controller;
    if (controller == null || controller.isClosed) return;

    try {
      final data = event.data as JSObject;
      final samplesBuffer = (data.getProperty('samples'.toJS) as JSArrayBuffer).toDart;
      final channels = (data.getProperty('channels'.toJS) as JSNumber).toDartInt;
      final frames = (data.getProperty('frames'.toJS) as JSNumber).toDartInt;

      final outChannels = _targetChannels.clamp(1, channels);
      final actualSampleRate = _audioContext?.sampleRate.toInt() ?? 48000;
      final srcFloat32 = samplesBuffer.asFloat32List();

      final Uint8List bytes;
      if (_targetFormat == AudioFormat.Float32) {
        bytes = float32ToFloat32Bytes(srcFloat32, channels, outChannels, frames);
      } else {
        bytes = float32ToInt16Bytes(srcFloat32, channels, outChannels, frames);
      }

      controller.add(AudioFrame(
        sampleRate: actualSampleRate,
        channels: outChannels,
        data: bytes,
        format: _targetFormat,
      ));
    } catch (e) {
      logger.warning('[AudioFrameCapture] Error processing worklet frame: $e');
    }
  }

  @override
  Future<void> stop() async {
    _workletNode?.port.onmessage = null;

    try {
      _workletNode?.disconnect();
    } catch (_) {}
    _workletNode = null;

    try {
      _sourceNode?.disconnect();
    } catch (_) {}
    _sourceNode = null;

    try {
      if (_audioContext?.state != 'closed') {
        await _audioContext?.close().toDart;
      }
    } catch (_) {}
    _audioContext = null;

    final controller = _controller;
    _controller = null;
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
  }
}

AudioFrameCapture createAudioFrameCaptureImpl() => AudioFrameCaptureWeb();
