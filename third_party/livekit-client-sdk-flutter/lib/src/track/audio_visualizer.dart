import 'package:uuid/uuid.dart' as uuid;

import '../events.dart' show AudioVisualizerEvent;
import '../managers/event.dart' show EventsEmittable;
import '../support/disposable.dart';
import 'audio_visualizer_native.dart' if (dart.library.js_interop) 'audio_visualizer_web.dart';
import 'local/local.dart' show AudioTrack;

final _uuid = uuid.Uuid();

class AudioVisualizerOptions {
  final bool centeredBands;
  final int barCount;
  final bool smoothTransition;
  const AudioVisualizerOptions({
    this.centeredBands = true,
    this.barCount = 7,
    this.smoothTransition = true,
  });
}

abstract class AudioVisualizer extends DisposableChangeNotifier with EventsEmittable<AudioVisualizerEvent> {
  // Unique Id for each visualizer
  final String visualizerId = _uuid.v4();

  Future<void> start();
  Future<void> stop();
}

AudioVisualizer createVisualizer(AudioTrack track, {AudioVisualizerOptions? options}) =>
    createVisualizerImpl(track, options: options);
