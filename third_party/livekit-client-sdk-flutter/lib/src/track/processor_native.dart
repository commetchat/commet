import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../types/other.dart';
import 'processor.dart';

class AudioProcessorOptions extends ProcessorOptions {
  AudioProcessorOptions({
    required MediaStreamTrack track,
  }) : super(kind: TrackType.AUDIO, track: track);
}

class VideoProcessorOptions extends ProcessorOptions {
  VideoProcessorOptions({
    required MediaStreamTrack track,
  }) : super(kind: TrackType.VIDEO, track: track);
}
