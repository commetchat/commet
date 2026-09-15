import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math' as math;

import 'package:dart_webrtc/dart_webrtc.dart' show MediaStreamTrackWeb, MediaStreamWeb;
import 'package:web/web.dart' as web;

import '../../track/local/local.dart' show AudioTrack;

// ignore: implementation_imports

class AudioAnalyser {
  final double Function() calculateVolume;
  final web.AnalyserNode analyser;
  final Future<void> Function() cleanup;
  AudioAnalyser({
    required this.calculateVolume,
    required this.analyser,
    required this.cleanup,
  });
}

class AudioAnalyserOptions {
  final bool? cloneTrack;
  final num? fftSize;
  final num? smoothingTimeConstant;
  final num? minDecibels;
  final num? maxDecibels;
  const AudioAnalyserOptions({
    this.cloneTrack = false,
    this.fftSize = 2048,
    this.smoothingTimeConstant = 0.8,
    this.minDecibels = -100,
    this.maxDecibels = -80,
  });

  factory AudioAnalyserOptions.from(AudioAnalyserOptions? options) {
    return AudioAnalyserOptions(
      cloneTrack: options?.cloneTrack,
      fftSize: options?.fftSize,
      smoothingTimeConstant: options?.smoothingTimeConstant,
      minDecibels: options?.minDecibels,
      maxDecibels: options?.maxDecibels,
    );
  }
}

web.AudioContext? getNewAudioContext() {
  if (web.window.hasProperty('AudioContext'.toJS).isDefinedAndNotNull) {
    return web.AudioContext(web.AudioContextOptions(
      latencyHint: 'interactive'.toJS,
    ));
  }
  return null;
}

AudioAnalyser? createAudioAnalyser(
  AudioTrack track,
  AudioAnalyserOptions? options,
) {
  final opts = options ?? AudioAnalyserOptions();

  final audioContext = getNewAudioContext();

  if (audioContext == null) {
    throw Exception('Audio Context not supported on this browser');
  }
  final streamTrack = opts.cloneTrack == true ? track.mediaStreamTrack.clone() : track.mediaStreamTrack;
  final mediaStreamSource = audioContext.createMediaStreamSource(
      MediaStreamWeb(web.MediaStream([(streamTrack as MediaStreamTrackWeb).jsTrack].toJS), '').jsStream);
  final analyser = audioContext.createAnalyser();
  analyser.minDecibels = opts.minDecibels ?? -100;
  analyser.maxDecibels = opts.maxDecibels ?? -80;
  analyser.fftSize = opts.fftSize?.toInt() ?? 2048;
  analyser.smoothingTimeConstant = opts.smoothingTimeConstant ?? 0.8;

  mediaStreamSource.connect(analyser);

  /// Calculates the current volume of the track in the range from 0 to 1
  double calculateVolume() {
    final JSUint8Array dataArray = JSUint8Array.withLength(analyser.frequencyBinCount);

    analyser.getByteFrequencyData(dataArray);
    num sum = 0;
    for (var amplitude in dataArray.toDart) {
      sum += math.pow(amplitude / 255, 2);
    }
    final volume = math.sqrt(sum / dataArray.toDart.length);
    return volume;
  }

  Future<void> cleanup() async {
    await audioContext.close().toDart;
    if (opts.cloneTrack == true) {
      await streamTrack.stop();
    }
  }

  return AudioAnalyser(
    calculateVolume: calculateVolume,
    analyser: analyser,
    cleanup: cleanup,
  );
}
