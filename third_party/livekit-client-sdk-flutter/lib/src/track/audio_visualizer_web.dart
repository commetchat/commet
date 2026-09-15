import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../events.dart' show AudioVisualizerEvent;
import '../logger.dart' show logger;
import 'audio_visualizer.dart';
import 'local/local.dart' show AudioTrack;
import 'web/_audio_analyser.dart';

class AudioVisualizerWeb extends AudioVisualizer {
  AudioAnalyser? _audioAnalyser;
  MultiBandTrackVolumeOptions options = MultiBandTrackVolumeOptions();
  Timer? _timer;
  final AudioTrack? _audioTrack;
  MediaStreamTrack get mediaStreamTrack => _audioTrack!.mediaStreamTrack;

  final AudioVisualizerOptions visualizerOptions;

  AudioVisualizerWeb(this._audioTrack, {required this.visualizerOptions}) {
    onDispose(() async {
      await events.dispose();
    });
  }

  @override
  Future<void> start() async {
    if (_audioAnalyser != null) {
      return;
    }

    final bands = visualizerOptions.barCount;

    // Override smoothingTimeConstant to a very low valiue if smoothTransition is false
    var currentAnalyserOptions = options.analyserOptions ?? const AudioAnalyserOptions();
    if (!visualizerOptions.smoothTransition) {
      currentAnalyserOptions = AudioAnalyserOptions(
        fftSize: currentAnalyserOptions.fftSize,
        maxDecibels: currentAnalyserOptions.maxDecibels,
        minDecibels: currentAnalyserOptions.minDecibels,
        smoothingTimeConstant: 0.02,
      );
    }

    _audioAnalyser = createAudioAnalyser(_audioTrack!, currentAnalyserOptions);

    final bufferLength = _audioAnalyser?.analyser.frequencyBinCount;

    _timer = Timer.periodic(
      Duration(milliseconds: options.updateInterval!.toInt()),
      (timer) {
        try {
          final tmp = JSFloat32Array.withLength(bufferLength ?? 0);
          _audioAnalyser?.analyser.getFloatFrequencyData(tmp);
          Float32List frequencies = Float32List(tmp.toDart.length);
          for (var i = 0; i < tmp.toDart.length; i++) {
            final element = tmp.toDart[i];
            frequencies[i] = element;
          }
          frequencies = frequencies.sublist(options.loPass!.toInt(), options.hiPass!.toInt());

          final normalizedFrequencies = normalizeFrequencies(frequencies);
          final chunkSize = (normalizedFrequencies.length / (bands + 1)).ceil();
          Float32List chunks = Float32List(visualizerOptions.barCount);

          for (var i = 0; i < bands; i++) {
            final summedVolumes =
                normalizedFrequencies.sublist(i * chunkSize, (i + 1) * chunkSize).reduce((acc, val) => (acc += val));
            chunks[i] = (summedVolumes / chunkSize);
          }

          if (visualizerOptions.centeredBands) {
            chunks = centerBands(chunks);
          }

          events.emit(AudioVisualizerEvent(
            track: _audioTrack,
            event: chunks,
          ));
        } catch (e) {
          logger.warning('Error in visualizer: $e');
        }
      },
    );
  }

  Float32List centerBands(Float32List sortedBands) {
    final centeredBands = Float32List(sortedBands.length);
    var leftIndex = sortedBands.length / 2;
    var rightIndex = leftIndex;

    for (var index = 0; index < sortedBands.length; index++) {
      final value = sortedBands[index];
      if (index % 2 == 0) {
        // Place value to the right
        centeredBands[rightIndex.toInt()] = value;
        rightIndex += 1;
      } else {
        // Place value to the left
        leftIndex -= 1;
        centeredBands[leftIndex.toInt()] = value;
      }
    }

    return centeredBands;
  }

  @override
  Future<void> stop() async {
    if (_audioAnalyser == null) {
      return;
    }

    events.emit(AudioVisualizerEvent(
      track: _audioTrack!,
      event: [],
    ));

    _timer?.cancel();
    _timer = null;

    await _audioAnalyser?.cleanup();
    _audioAnalyser = null;
  }
}

class MultiBandTrackVolumeOptions {
  /// cut off of frequency bins on the lower end
  /// Note: this is not a frequency measure, but in relation to analyserOptions.fftSize,
  final num? loPass;

  /// cut off of frequency bins on the higher end
  /// Note: this is not a frequency measure, but in relation to analyserOptions.fftSize,
  final num? hiPass;

  /// update should run every x ms
  final num? updateInterval;

  final AudioAnalyserOptions? analyserOptions;

  const MultiBandTrackVolumeOptions({
    this.loPass = 0,
    this.hiPass = 170,
    this.updateInterval = 32,
    this.analyserOptions = const AudioAnalyserOptions(),
  });
}

double normalizeDb(num value) {
  const minDb = -100.0;
  const maxDb = -10.0;

  var db = 1.0 - (math.max(minDb, math.min(maxDb, value)) * -1.0).toDouble() / 100.0;
  db = math.sqrt(db);

  return db;
}

List<num> normalizeFrequencies(List<double> frequencies) {
  // Normalize all frequency values
  return frequencies.map((value) {
    if (value.isInfinite || value.isNaN) {
      return 0;
    }
    return normalizeDb(value);
  }).toList();
}

AudioVisualizer createVisualizerImpl(AudioTrack track, {AudioVisualizerOptions? options}) =>
    AudioVisualizerWeb(track, visualizerOptions: options ?? AudioVisualizerOptions());
