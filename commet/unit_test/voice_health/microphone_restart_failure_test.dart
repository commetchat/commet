// A call restarts its microphone mid-call: when noise suppression changes
// hands, when the voice DSP watchdog gives up, and to bring a stalled
// capture back. A restart whose new capture cannot be opened (the device
// vanished for a moment, another application holds it) used to stop the
// old capture first, so the call went on sending a stopped track: silence
// until the user left and rejoined the room.
import 'package:commet/client/matrix/components/voip_room/livekit_microphone.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
// TrackEndedEvent is the SDK's own.
// ignore: implementation_imports, invalid_use_of_internal_member
import 'package:livekit_client/src/internal/events.dart' show TrackEndedEvent;

import '../noise_suppression/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeWebrtcChannel webrtc;

  setUp(() => (webrtc = FakeWebrtcChannel()).install());
  tearDown(() => webrtc.uninstall());

  test('a restart that cannot open the device keeps the old capture going',
      () async {
    final (track, sender) = await publishedMicrophone(
        const lk.AudioCaptureOptions(noiseSuppression: false));
    final before = sender.track!.id;

    webrtc.failGetUserMedia = 1;
    await expectLater(
        track.restartTrack(
            track.currentOptions.copyWith(noiseSuppression: true)),
        throwsA(anything));

    expect(sender.track?.id, before,
        reason: 'the sender must keep the capture it had');
    expect(webrtc.stoppedTracks, isNot(contains(before)),
        reason: 'the old capture was stopped before the new one existed');
    expect(track.currentOptions.noiseSuppression, isFalse,
        reason: 'options of a capture that was never made must not stick, '
            'or nothing ever retries the restart');
  });

  test('the restart is tried again once the device is back', () async {
    final (track, sender) = await publishedMicrophone(
        const lk.AudioCaptureOptions(noiseSuppression: false));
    final microphone = LivekitMicrophone(_Publication(track));

    webrtc.failGetUserMedia = 1;
    await expectLater(
        microphone.restart(webrtcNoiseSuppression: true), throwsA(anything));
    expect(microphone.webrtcNoiseSuppression, isFalse);

    await microphone.restart(webrtcNoiseSuppression: true);
    expect(microphone.webrtcNoiseSuppression, isTrue);
    expect(sender.track?.id, isNot('mic-1'));
    expect(webrtc.stoppedTracks, contains('mic-1'),
        reason: 'the replaced capture is released');
  });

  // LiveKit only watched the first capture for its end: after any restart
  // a capture that ended (unplugged, permission revoked) went unnoticed.
  test('a capture made by a restart is watched for its end', () async {
    final (track, _) = await publishedMicrophone(
        const lk.AudioCaptureOptions(noiseSuppression: false));
    await track.restartTrack();
    // ignore: invalid_use_of_internal_member
    final ended = <TrackEndedEvent>[];
    final listener = track.createListener()
      // ignore: invalid_use_of_internal_member
      ..on<TrackEndedEvent>(ended.add);
    track.mediaStreamTrack.onEnded!();
    await Future<void>.delayed(Duration.zero);
    expect(ended, hasLength(1));
    await listener.dispose();
  });

  // Track.disable() does nothing while the track is stopped, which a
  // restart makes it for a moment: a mute then was lost and the new
  // capture went out enabled.
  test('a track muted during its restart stays muted', () async {
    final (track, sender) = await publishedMicrophone(
        const lk.AudioCaptureOptions(noiseSuppression: false));
    webrtc.onGetUserMedia = () async {
      webrtc.onGetUserMedia = null;
      await track.mute(stopOnMute: false);
    };
    await track.restartTrack();
    expect(sender.track?.id, 'mic-2');
    expect(track.mediaStreamTrack.enabled, isFalse);
    expect(webrtc.enableCalls, contains('mic-2=false'));
  });

  test('a successful restart releases the capture it replaced', () async {
    final (track, sender) = await publishedMicrophone(
        const lk.AudioCaptureOptions(noiseSuppression: false));

    await track.restartTrack();

    expect(sender.track?.id, 'mic-2');
    expect(webrtc.stoppedTracks, contains('mic-1'));
    expect(webrtc.stoppedTracks, isNot(contains('mic-2')));
  });
}

class _Publication implements lk.LocalTrackPublication<lk.LocalAudioTrack> {
  @override
  final lk.LocalAudioTrack track;

  _Publication(this.track);

  @override
  bool get muted => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
