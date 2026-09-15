import 'dart:async';

import 'package:flutter/services.dart' show EventChannel;

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../events.dart' show AudioVisualizerEvent;
import '../support/native.dart' show Native;
import '../track/local/local.dart';
import 'audio_visualizer.dart';

class AudioVisualizerNative extends AudioVisualizer {
  EventChannel? _eventChannel;
  StreamSubscription? _streamSubscription;

  final AudioTrack? _audioTrack;
  final AudioVisualizerOptions visualizerOptions;

  MediaStreamTrack get mediaStreamTrack => _audioTrack!.mediaStreamTrack;

  AudioVisualizerNative(this._audioTrack, {required this.visualizerOptions}) {
    onDispose(() async {
      await events.dispose();
    });
  }

  @override
  Future<void> start() async {
    if (_eventChannel != null) {
      return;
    }

    await Native.startVisualizer(
      mediaStreamTrack.id!,
      isCentered: visualizerOptions.centeredBands,
      barCount: visualizerOptions.barCount,
      visualizerId: visualizerId,
      smoothTransition: visualizerOptions.smoothTransition,
    );

    _eventChannel = EventChannel('io.livekit.audio.visualizer/eventChannel-${mediaStreamTrack.id}-$visualizerId');
    _streamSubscription = _eventChannel?.receiveBroadcastStream().listen((event) {
      events.emit(AudioVisualizerEvent(
        track: _audioTrack!,
        event: event,
      ));
    });
  }

  @override
  Future<void> stop() async {
    if (_eventChannel == null) {
      return;
    }

    // Cancel subscription before native stop, otherwise the native
    // StreamHandler is already removed and cancel throws MissingPluginException.
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    _eventChannel = null;

    await Native.stopVisualizer(mediaStreamTrack.id!, visualizerId: visualizerId);
  }
}

AudioVisualizer createVisualizerImpl(AudioTrack track, {AudioVisualizerOptions? options}) =>
    AudioVisualizerNative(track, visualizerOptions: options ?? AudioVisualizerOptions());
