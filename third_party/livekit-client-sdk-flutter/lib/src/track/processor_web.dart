import 'package:flutter_webrtc/flutter_webrtc.dart' show MediaStreamTrack;
import 'package:web/web.dart' show AudioContext, HTMLAudioElement;

import '../types/other.dart';
import 'processor.dart';

class AudioProcessorOptions extends ProcessorOptions {
  AudioProcessorOptions({
    required MediaStreamTrack track,
    this.audioElement,
    this.audioContext,
  }) : super(kind: TrackType.AUDIO, track: track);

  HTMLAudioElement? audioElement;
  AudioContext? audioContext;
}

class VideoProcessorOptions extends ProcessorOptions {
  VideoProcessorOptions({
    required MediaStreamTrack track,
  }) : super(kind: TrackType.VIDEO, track: track);
}
