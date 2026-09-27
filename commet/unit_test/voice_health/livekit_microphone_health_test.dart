// The microphone watch on a LiveKit room's real microphone track: what it
// reads from the sender, and what each repair does to the capture and to
// the user's mute.
import 'package:commet/client/components/voip/microphone_health.dart';
import 'package:commet/client/matrix/components/voip_room/livekit_microphone.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart' as lk;

import '../noise_suppression/fakes.dart';

class _Publication implements lk.LocalTrackPublication<lk.LocalAudioTrack> {
  _Publication(this.track, {this.sid = 'TR_mic'});

  @override
  lk.LocalAudioTrack? track;

  @override
  final String sid;

  @override
  bool muted = false;

  lk.TrackSource sourceOverride = lk.TrackSource.microphone;

  @override
  lk.TrackSource get source => sourceOverride;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Participant implements lk.LocalParticipant {
  final List<_Publication> publications = [];
  final List<String> calls = [];

  /// What setMicrophoneEnabled(true) publishes when there is no microphone.
  Future<_Publication> Function()? publish;

  /// Runs while a publication is being removed.
  void Function()? onRemove;

  /// Published through publishAudioTrack, as a republish does.
  final List<lk.LocalAudioTrack> published = [];

  /// Makes publishAudioTrack fail, as it does once the room is gone.
  bool failPublish = false;

  FakeSender? lastSender;

  @override
  Future<lk.LocalTrackPublication<lk.LocalAudioTrack>> publishAudioTrack(
      lk.LocalAudioTrack track,
      {lk.AudioPublishOptions? publishOptions}) async {
    calls.add('publish ${track.source.name}');
    if (failPublish) throw StateError('the room is gone');
    // As publishing does: on a sender, started.
    final sender = lastSender = FakeSender();
    track.transceiver = FakeTransceiver(sender);
    await sender.replaceTrack(track.mediaStreamTrack);
    await track.start();
    published.add(track);
    final publication = _Publication(track, sid: 'TR_new');
    publications.add(publication);
    return publication;
  }

  @override
  List<lk.LocalTrackPublication<lk.LocalAudioTrack>>
      get audioTrackPublications => publications;

  @override
  Future<void> removePublishedTrack(String trackSid,
      {bool notify = true}) async {
    calls.add('remove $trackSid');
    onRemove?.call();
    publications.removeWhere((p) => p.sid == trackSid);
  }

  @override
  Future<lk.LocalTrackPublication?> setMicrophoneEnabled(bool enabled,
      {lk.AudioCaptureOptions? audioCaptureOptions}) async {
    calls.add('microphone $enabled '
        'stopOnMute=${audioCaptureOptions?.stopAudioCaptureOnMute}');
    if (enabled && publications.isEmpty && publish != null) {
      publications.add(await publish!());
    } else if (publications.isNotEmpty) {
      publications.first.muted = !enabled;
    }
    return publications.firstOrNull;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

rtc.StatsReport _report(String type, Map<String, dynamic> values) =>
    rtc.StatsReport('$type-1', type, 0, values);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeWebrtcChannel webrtc;
  late _Participant participant;
  late lk.LocalAudioTrack track;
  late FakeSender sender;
  late bool wanted;
  late DateTime now;
  late LivekitMicrophoneHealth health;
  late List<MicrophoneFault> gaveUp;

  setUp(() async {
    (webrtc = FakeWebrtcChannel()).install();
    (track, sender) = await publishedMicrophone(
        const lk.AudioCaptureOptions(noiseSuppression: false));
    participant = _Participant()..publications.add(_Publication(track));
    wanted = true;
    now = DateTime(2026, 9, 26);
    gaveUp = [];
    health = LivekitMicrophoneHealth(
      participant: () => participant,
      wanted: () => wanted,
      captureOptions: () async =>
          const lk.AudioCaptureOptions(noiseSuppression: false),
      ladder: MicrophoneRepair.values,
      onGaveUp: gaveUp.add,
      now: () => now,
    );
  });

  tearDown(() => webrtc.uninstall());

  /// Seconds of call where the sender's source hands over [rate] seconds of
  /// audio per second.
  Future<void> run(int seconds, {double rate = 1, double from = 0}) async {
    var captured = from;
    for (var i = 0; i < seconds; i++) {
      now = now.add(const Duration(seconds: 1));
      captured += rate;
      sender.stats = [
        _report('media-source',
            {'kind': 'audio', 'totalSamplesDuration': captured}),
        _report('outbound-rtp', {'kind': 'audio', 'packetsSent': i * 50}),
      ];
      await health.check();
    }
  }

  test('reads how much audio the sender got', () async {
    await run(10);
    expect(health.monitor.captureFlowing, isTrue);
    expect(health.monitor.fault, isNull);
  });

  test('a capture that stops is reopened: off, then on again', () async {
    await run(5);
    webrtc.enableCalls.clear();
    await run(3, rate: 0, from: 5);
    expect(health.monitor.fault, MicrophoneFault.captureStalled);
    expect(webrtc.enableCalls, ['mic-1=false', 'mic-1=true']);
    expect(track.mediaStreamTrack.enabled, isTrue);
  });

  test('a muted microphone is not reopened', () async {
    await run(5);
    webrtc.enableCalls.clear();
    await track.mute(stopOnMute: false);
    participant.publications.first.muted = true;
    webrtc.enableCalls.clear();
    await run(10, rate: 0, from: 5);
    expect(webrtc.enableCalls, isEmpty);
  });

  test('a mute that lands during a reopen stays muted', () async {
    await run(5);
    webrtc.enableCalls.clear();
    // The mute arrives while the platform handles the reopen's first call.
    webrtc.onEnable = (trackId, enabled) {
      if (enabled) return;
      webrtc.onEnable = null;
      track.mediaStreamTrack.enabled = false;
    };
    await run(3, rate: 0, from: 5);
    expect(webrtc.enableCalls.last, 'mic-1=false',
        reason: 'the capture must end up off, as the user asked');
  });

  test('the second repair opens a new capture for the same sender', () async {
    await run(5);
    await run(6, rate: 0, from: 5);
    expect(sender.track?.id, 'mic-2');
    expect(webrtc.stoppedTracks, contains('mic-1'));
  });

  test('the third repair publishes a new microphone', () async {
    participant.publish = () async {
      final (t, s) = await publishedMicrophone(
          const lk.AudioCaptureOptions(noiseSuppression: false));
      sender = s;
      return _Publication(t, sid: 'TR_new');
    };
    await run(5);
    await run(9, rate: 0, from: 5);
    expect(participant.calls, ['remove TR_mic', 'publish microphone']);
    expect(participant.publications.single.sid, 'TR_new');
    expect(gaveUp, [MicrophoneFault.captureStalled]);
  });

  group('a republish does not unmute someone who muted meanwhile', () {
    Future<void> republishWith(
        {void Function()? whilePreparing,
        void Function()? whileRemoving}) async {
      health = LivekitMicrophoneHealth(
        participant: () => participant,
        wanted: () => wanted,
        captureOptions: () async {
          whilePreparing?.call();
          return const lk.AudioCaptureOptions(noiseSuppression: false);
        },
        ladder: const [MicrophoneRepair.republish],
        now: () => now,
      );
      participant.onRemove = whileRemoving;
      participant.publish = () async => _Publication(track, sid: 'TR_new');
      await run(5);
      await run(2, rate: 0, from: 5);
    }

    test('muted while the new capture was being prepared', () async {
      await republishWith(whilePreparing: () => wanted = false);
      expect(participant.calls, ['remove TR_mic'],
          reason: 'the old microphone goes, no new one comes');
    });

    test('muted while the old microphone was being removed', () async {
      await republishWith(whileRemoving: () => wanted = false);
      expect(participant.calls, ['remove TR_mic']);
    });
  });

  // The DJ booth's music is published without a source, and LiveKit's
  // lookup by source used to take it for the microphone when there was
  // none: "publishing" a microphone unmuted the music and nothing else.
  test('a microphone is published again next to the DJ booth\'s music',
      () async {
    final (music, _) = await publishedMicrophone(
        const lk.AudioCaptureOptions(noiseSuppression: false));
    participant.publications.insert(
        0,
        _Publication(music, sid: 'TR_music')
          ..sourceOverride = lk.TrackSource.unknown);
    await run(5);
    participant.publications.removeWhere((p) => p.sid == 'TR_mic');
    await run(4);
    expect(participant.calls, ['publish microphone']);
    expect(participant.published.single.source, lk.TrackSource.microphone);
  });

  test('a microphone opened for a publish that fails is closed again',
      () async {
    await run(5);
    participant.publications.clear();
    participant.failPublish = true;
    webrtc.stoppedTracks.clear();
    await run(4);
    expect(participant.calls, ['publish microphone']);
    expect(webrtc.stoppedTracks, isNotEmpty,
        reason: 'the capture opened for it would stay open');
  });

  test('nothing is repaired while the room is not connected', () async {
    var connected = true;
    health = LivekitMicrophoneHealth(
      participant: () => participant,
      wanted: () => wanted,
      connected: () => connected,
      captureOptions: () async =>
          const lk.AudioCaptureOptions(noiseSuppression: false),
      ladder: MicrophoneRepair.values,
      now: () => now,
    );
    await run(5);
    connected = false;
    webrtc.enableCalls.clear();
    participant.publications.clear();
    await run(30, rate: 0);
    expect(webrtc.enableCalls, isEmpty);
    expect(participant.calls, isEmpty,
        reason: 'LiveKit unpublishes everything when it gives up');
  });

  test('a mute that lands during a restart holds on the new capture', () async {
    health = LivekitMicrophoneHealth(
      participant: () => participant,
      wanted: () => wanted,
      captureOptions: () async =>
          const lk.AudioCaptureOptions(noiseSuppression: false),
      ladder: const [MicrophoneRepair.restart],
      now: () => now,
    );
    await run(5);
    webrtc.onGetUserMedia = () async {
      webrtc.onGetUserMedia = null;
      await track.mute(stopOnMute: false);
      participant.publications.first.muted = true;
    };
    webrtc.enableCalls.clear();
    await run(3, rate: 0, from: 5);
    expect(webrtc.getUserMediaCalls, hasLength(2), reason: 'a restart ran');
    expect(track.mediaStreamTrack.id, 'mic-2');
    expect(track.mediaStreamTrack.enabled, isFalse,
        reason: 'the new capture went out although the user muted');
    expect(webrtc.enableCalls.last, 'mic-2=false');
  });

  test('nothing is read or repaired while the user does not want it', () async {
    wanted = false;
    await run(20, rate: 0);
    expect(webrtc.enableCalls, isEmpty);
    expect(health.monitor.fault, isNull);
  });

  test('a microphone that disappeared while wanted is published again',
      () async {
    participant.publish = () async => _Publication(track, sid: 'TR_new');
    await run(5);
    participant.publications.clear();
    await run(2);
    expect(participant.calls, isEmpty,
        reason: 'gone for a moment is LiveKit republishing it');
    await run(2);
    expect(health.monitor.fault, MicrophoneFault.missing);
    expect(participant.calls, ['publish microphone']);
    expect(participant.publications.single.sid, 'TR_new');
    sender = participant.lastSender!;
    await run(5);
    expect(health.monitor.fault, isNull);
  });

  test('a call that never had a microphone is not given one', () async {
    participant.publications.clear();
    participant.publish = () async => _Publication(track, sid: 'TR_new');
    await run(30);
    expect(participant.calls, isEmpty,
        reason: 'no device or permission denied: publishing is the '
            'user\'s unmute, not ours');
  });

  test('a missing microphone the user muted is not brought back', () async {
    await run(5);
    participant.publications.clear();
    wanted = false;
    await run(30);
    expect(participant.calls, isEmpty);
  });

  test('a stopped capture track counts as ended', () async {
    await run(5);
    await track.stop();
    await run(1, from: 5);
    expect(health.monitor.fault, MicrophoneFault.captureEnded);
  });
}
