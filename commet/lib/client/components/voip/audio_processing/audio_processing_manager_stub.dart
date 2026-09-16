import 'package:commet/client/components/voip/audio_processing/audio_dsp_settings.dart';
import 'package:commet/client/components/voip/audio_processing/audio_processing_manager.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

AudioProcessingManager createAudioProcessingManager() =>
    UnsupportedAudioProcessingManager();

/// Platforms without a DSP build. Everything is a no-op.
class UnsupportedAudioProcessingManager extends AudioProcessingManager {
  @override
  bool get isSupported => false;

  @override
  bool get isActive => false;

  @override
  bool get isInCall => false;

  @override
  bool get isTesting => false;

  @override
  bool get micTestMonitor => false;

  @override
  Future<void> onSessionStarted(VoipSession session) async {}

  @override
  Future<void> onSessionEnded() async {}

  @override
  lk.TrackProcessor<lk.AudioProcessorOptions>? createTrackProcessor() => null;

  @override
  Future<void> applySettings(AudioDspSettings settings) async {}

  @override
  Future<bool> startMicTest() async => false;

  @override
  Future<void> stopMicTest() async {}

  @override
  Future<void> setMicTestMonitor(bool enabled) async {}
}
