// Who takes the noise out of a call's microphone: our DSP or WebRTC's (the
// browser's) own suppressor, never both, never neither, through a preference
// flip, mute, a late published microphone and a DSP that never gets audio.
import 'package:commet/client/components/voip/audio_processing/audio_processing_manager_stub.dart';
import 'package:commet/client/components/voip/audio_processing/microphone_noise_suppression.dart';
import 'package:commet/client/matrix/components/voip_room/livekit_microphone.dart';
import 'package:commet/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

class _Dsp extends UnsupportedAudioProcessingManager {
  bool supported = true;
  bool processing = true;
  final List<FakeAudioProcessor> processors = [];

  /// What ensureReady finds out, like the web manager's probe of
  /// audio_dsp.wasm: until it has answered, [isSupported] is optimistic.
  String? probeFailure;

  @override
  Future<bool> ensureReady() async {
    if (probeFailure != null) supported = false;
    return supported;
  }

  @override
  String? get unavailableReason => supported ? null : probeFailure;

  /// Like the web manager: a new processor per microphone, none without
  /// the DSP.
  @override
  lk.TrackProcessor<lk.AudioProcessorOptions>? createTrackProcessor() {
    if (!supported) return null;
    final p = FakeAudioProcessor();
    processors.add(p);
    return p;
  }

  @override
  bool get isSupported => supported;

  @override
  bool get isProcessing => processing;
}

class _Mic implements MicrophoneCapture {
  @override
  bool webrtcNoiseSuppression;
  bool published = true;
  bool muted = false;
  bool failRestarts = false;
  final List<bool> restarts = [];

  _Mic({required this.webrtcNoiseSuppression});

  @override
  bool get live => published && !muted;

  @override
  Future<void> restart({required bool webrtcNoiseSuppression}) async {
    restarts.add(webrtcNoiseSuppression);
    if (failRestarts) throw Exception('no microphone');
    this.webrtcNoiseSuppression = webrtcNoiseSuppression;
  }
}

class _Publication implements lk.LocalTrackPublication<lk.LocalAudioTrack> {
  @override
  final lk.TrackSource source;
  _Publication(this.source);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Participant implements lk.LocalParticipant {
  @override
  final List<lk.LocalTrackPublication<lk.LocalAudioTrack>>
      audioTrackPublications;
  _Participant(this.audioTrackPublications);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Dsp dsp;
  late _Mic? mic;
  late bool preference;
  late DateTime now;
  late int failures;
  late MicrophoneNoiseSuppression ns;

  setUpAll(() async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await preferences.init();
  });

  setUp(() {
    dsp = _Dsp();
    preference = true;
    now = DateTime(2026, 9, 25);
    failures = 0;
    // As MatrixLivekitBackend.join creates it: ours on, WebRTC's off.
    mic = _Mic(webrtcNoiseSuppression: false);
    ns = MicrophoneNoiseSuppression(
      dsp: dsp,
      microphone: () => mic,
      preference: () => preference,
      onDspFailed: () => failures++,
      now: () => now,
    );
  });

  tearDown(() => dsp.dispose());

  group('who suppresses', () {
    test('a new capture has WebRTC\'s suppressor only when ours will not run',
        () {
      expect(
          MicrophoneNoiseSuppression.webrtcSuppressorFor(dsp, preference: true),
          isFalse);
      expect(
          MicrophoneNoiseSuppression.webrtcSuppressorFor(dsp,
              preference: false),
          isTrue);
      dsp.supported = false;
      expect(
          MicrophoneNoiseSuppression.webrtcSuppressorFor(dsp, preference: true),
          isTrue);
    });

    test('the room microphone is created that way', () {
      final options = microphoneCaptureOptions(
          dsp: dsp, noiseSuppressionPreference: true, deviceId: 'mic');
      expect(options.noiseSuppression, isFalse);
      expect(options.deviceId, 'mic');
      dsp.supported = false;
      expect(
          microphoneCaptureOptions(dsp: dsp, noiseSuppressionPreference: true)
              .noiseSuppression,
          isTrue);
    });

    // The web DSP is only known to work once audio_dsp.wasm has been
    // fetched and test-run. Deciding before that turned the browser's
    // suppressor off for a DSP that then passed the microphone through.
    test('a call waits to know whether our DSP can run', () async {
      dsp.probeFailure = 'audio_dsp.wasm: HTTP 404';

      final options = await prepareMicrophoneCaptureOptions(
          dsp: dsp, noiseSuppressionPreference: true);

      expect(options.noiseSuppression, isTrue,
          reason: 'the browser\'s suppressor has to stay on');
      expect(options.processor, isNull);
      expect(dsp.unavailableReason, 'audio_dsp.wasm: HTTP 404');
    });

    test('nothing restarts while the capture already matches', () async {
      await ns.update();
      expect(mic!.restarts, isEmpty);
    });
  });

  group('the preference flipping mid-call', () {
    test('turning ours off gives the capture WebRTC\'s suppressor', () async {
      preference = false;
      await ns.update();
      expect(mic!.restarts, [true]);
    });

    test('turning ours on takes WebRTC\'s off', () async {
      mic = _Mic(webrtcNoiseSuppression: true);
      await ns.update();
      expect(mic!.restarts, [false]);
    });

    // Since 24f5669f unmuting only re-enables the capture, so nothing used
    // to apply a flip that happened while muted: ours off and WebRTC's off.
    test('a flip while muted is applied on unmute', () async {
      mic!.muted = true;
      preference = false;
      await ns.update();
      expect(mic!.restarts, isEmpty,
          reason: 'a restart would bring the muted capture back enabled');

      mic!.muted = false;
      await ns.update();
      expect(mic!.restarts, [true]);
    });

    test('a flip before the microphone is published is applied once it is',
        () async {
      mic!.published = false;
      preference = false;
      await ns.update();
      mic!.published = true;
      await ns.update();
      expect(mic!.restarts, [true]);
    });

    test('a failed restart is retried, not every second', () async {
      mic!.failRestarts = true;
      preference = false;
      await ns.update();
      now = now.add(const Duration(seconds: 1));
      await ns.update();
      expect(mic!.restarts, [true]);
      mic!.failRestarts = false;
      now = now.add(MicrophoneNoiseSuppression.retryAfter);
      await ns.update();
      expect(mic!.restarts, [true, true]);
      expect(mic!.webrtcNoiseSuppression, isTrue);
    });
  });

  group('our DSP getting no audio', () {
    Future<void> liveFor(Duration d) async {
      final end = now.add(d);
      while (now.isBefore(end)) {
        await ns.update();
        now = now.add(const Duration(seconds: 1));
      }
      await ns.update();
    }

    test('WebRTC\'s suppressor takes over after the stall limit', () async {
      dsp.processing = false;
      await liveFor(const Duration(seconds: 3));
      expect(mic!.restarts, isEmpty);

      await liveFor(const Duration(seconds: 2));
      expect(ns.dspFailed, isTrue);
      expect(mic!.restarts, [true]);
      expect(failures, 1);

      // For the rest of the call, even if the DSP comes back.
      dsp.processing = true;
      await liveFor(const Duration(seconds: 5));
      expect(mic!.restarts, [true]);
      expect(failures, 1);
    });

    // Windows' capture thread dying starves the DSP along with everything
    // else. The microphone watch repairs the capture; giving up on our DSP
    // for it spent the call's only fallback, and the next death had no
    // watchdog left to restart anything.
    test('a capture that went quiet is not blamed on the DSP', () async {
      bool? flowing = false;
      ns = MicrophoneNoiseSuppression(
        dsp: dsp,
        microphone: () => mic,
        preference: () => preference,
        onDspFailed: () => failures++,
        captureFlowing: () => flowing,
        now: () => now,
      );
      dsp.processing = false;
      await liveFor(const Duration(seconds: 30));
      expect(ns.dspFailed, isFalse);
      expect(mic!.restarts, isEmpty);

      // The capture flows again and the DSP still gets nothing: that is ours.
      flowing = true;
      await liveFor(const Duration(seconds: 5));
      expect(ns.dspFailed, isTrue);
      expect(failures, 1);
    });

    // Just after a repair the watch does not know yet whether the capture
    // flows; a repair that takes a few seconds must not make us give up on
    // the DSP.
    test(
        'while the watch does not know whether the capture flows, the DSP '
        'is not blamed', () async {
      ns = MicrophoneNoiseSuppression(
        dsp: dsp,
        microphone: () => mic,
        preference: () => preference,
        onDspFailed: () => failures++,
        captureFlowing: () => null,
        now: () => now,
      );
      dsp.processing = false;
      await liveFor(const Duration(seconds: 30));
      expect(ns.dspFailed, isFalse);
    });

    test('muted time is not a stall', () async {
      dsp.processing = false;
      mic!.muted = true;
      await liveFor(const Duration(seconds: 10));
      expect(ns.dspFailed, isFalse);
      expect(mic!.restarts, isEmpty);
    });

    test('a DSP that is processing is left alone', () async {
      await liveFor(const Duration(seconds: 10));
      expect(ns.dspFailed, isFalse);
    });

    test('without our DSP there is nothing to watch', () async {
      dsp.supported = false;
      dsp.processing = false;
      mic = _Mic(webrtcNoiseSuppression: true);
      await liveFor(const Duration(seconds: 10));
      expect(ns.dspFailed, isFalse);
      expect(mic!.restarts, isEmpty);
    });
  });

  group('muting and unmuting', () {
    Future<lk.AudioCaptureOptions?> toggle(lk.LocalParticipant participant,
            {required bool enabling}) =>
        microphoneOptionsToToggle(participant,
            enabling: enabling,
            dsp: dsp,
            noiseSuppressionPreference: preference,
            deviceId: () async => 'picked-mic');

    // The join could not publish the microphone (denied, no device yet): the
    // first unmute creates it, and it has to be a room microphone.
    test('unmuting a microphone that was never published creates it with ours',
        () async {
      final options = await toggle(_Participant([]), enabling: true);
      expect(options, isNotNull);
      expect(options!.processor, same(dsp.processors.single));
      expect(options.noiseSuppression, isFalse);
      expect(options.deviceId, 'picked-mic');
      expect(options.stopAudioCaptureOnMute, isFalse);
    });

    test('muting a microphone that was never published makes no processor',
        () async {
      expect(await toggle(_Participant([]), enabling: false), isNull);
      expect(dsp.processors, isEmpty);
    });
  });

  // flutter-webrtc on desktop selects an input only from
  // `optional: [{sourceId}]` and records from its device 0 otherwise: the
  // microphone test and legacy calls used `deviceId: {exact}`.
  test('captures that are not LiveKit tracks name the device like LiveKit', () {
    final constraints =
        microphoneConstraints(webrtcNoiseSuppression: false, deviceId: 'mic-7');
    final optional = (constraints['optional'] as List).cast<Map>();
    expect(optional, contains(equals({'sourceId': 'mic-7'})));
    expect(optional, contains(equals({'noiseSuppression': false})));
    expect(optional, contains(equals({'echoCancellation': true})));
    expect(constraints.containsKey('deviceId'), isFalse);
    expect(
        (microphoneConstraints(webrtcNoiseSuppression: true)['optional']
                as List)
            .cast<Map>(),
        contains(equals({'noiseSuppression': true})));
  });

  test('the microphone is found by its source, not as the first audio track',
      () {
    final microphone = _Publication(lk.TrackSource.microphone);
    final participant = _Participant([
      // The DJ booth's music and the screen's audio, published while the
      // microphone had failed at join.
      _Publication(lk.TrackSource.unknown),
      _Publication(lk.TrackSource.screenShareAudio),
      microphone,
    ]);
    expect(microphonePublication(participant), same(microphone));
    expect(microphonePublication(_Participant([])), isNull);
  });
}
