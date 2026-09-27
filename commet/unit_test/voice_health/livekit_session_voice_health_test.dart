// A voice room's session, second by second: its microphone going quiet is
// repaired without the user leaving the call, a mute is respected, someone
// we stopped receiving is asked for again, and the mute button follows the
// microphone even with the DJ booth's music published first.
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/profile/profile_component.dart';
import 'package:commet/client/components/voip/audio_processing/audio_processing_manager.dart';
import 'package:commet/client/components/voip/audio_processing/audio_processing_manager_stub.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_livekit_voip_session.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:matrix/matrix.dart' as matrix;
import 'package:shared_preferences/shared_preferences.dart';

import '../noise_suppression/fakes.dart';

class _LocalPublication
    implements lk.LocalTrackPublication<lk.LocalAudioTrack> {
  _LocalPublication(this.sid, this.track, this.source, this.participant);

  @override
  final lk.LocalParticipant participant;

  @override
  final String sid;

  @override
  lk.LocalAudioTrack? track;

  @override
  final lk.TrackSource source;

  @override
  bool muted = false;

  @override
  lk.TrackType get kind => lk.TrackType.AUDIO;

  @override
  String get name => source.name;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LocalParticipant implements lk.LocalParticipant {
  final List<_LocalPublication> publications = [];

  @override
  String get identity => '@me:example.org:DEVICE';

  @override
  Map<String, lk.LocalTrackPublication> get trackPublications =>
      {for (final p in publications) p.sid: p};

  @override
  List<lk.LocalTrackPublication<lk.LocalAudioTrack>>
      get audioTrackPublications => publications;

  @override
  bool get isMuted => publications.firstOrNull?.muted ?? true;

  @override
  bool isCameraEnabled() => false;

  @override
  bool isScreenShareEnabled() => false;

  @override
  lk.LocalTrackPublication? getTrackPublicationBySource(
          lk.TrackSource source) =>
      publications.firstWhereOrNull((p) => p.source == source);

  @override
  Future<lk.LocalTrackPublication?> setMicrophoneEnabled(bool enabled,
      {lk.AudioCaptureOptions? audioCaptureOptions}) async {
    final mic = getTrackPublicationBySource(lk.TrackSource.microphone)
        as _LocalPublication?;
    if (mic == null) return null;
    mic.muted = !enabled;
    mic.track?.mediaStreamTrack.enabled = enabled;
    return mic;
  }

  @override
  Future<void> publishData(List<int> data,
      {bool? reliable,
      List<String>? destinationIdentities,
      String? topic}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RemotePublication implements lk.RemoteTrackPublication {
  _RemotePublication(this.sid, this.participant);

  @override
  final String sid;

  @override
  final lk.RemoteParticipant participant;

  int resubscribes = 0;

  @override
  lk.TrackSource get source => lk.TrackSource.microphone;

  @override
  lk.TrackType get kind => lk.TrackType.AUDIO;

  @override
  bool get muted => false;

  @override
  bool get subscribed => false;

  @override
  lk.RemoteTrack? get track => null;

  @override
  lk.TrackSubscriptionState get subscriptionState =>
      lk.TrackSubscriptionState.unsubscribed;

  @override
  Future<void> subscribe() async {}

  @override
  Future<void> resubscribe(
      {Duration delay = const Duration(seconds: 1),
      bool Function()? stillWanted}) async {
    resubscribes++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RemoteParticipant implements lk.RemoteParticipant {
  @override
  String get identity => '@bob:example.org:BOB';

  @override
  bool get isSpeaking => false;

  late final _RemotePublication mic = _RemotePublication('TR_bob', this);

  @override
  Map<String, lk.RemoteTrackPublication> get trackPublications =>
      {mic.sid: mic};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Listener implements lk.EventsListener<lk.RoomEvent> {
  @override
  Future<void> Function() on<E>(FutureOr<void> Function(E) then,
          {bool Function(E)? filter}) =>
      () async {};

  @override
  Future<bool> dispose() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Room implements lk.Room {
  _Room(this.localParticipant);

  @override
  final lk.LocalParticipant? localParticipant;

  final Map<String, lk.RemoteParticipant> remote = {};

  @override
  lk.ConnectionState connectionState = lk.ConnectionState.connected;

  @override
  UnmodifiableMapView<String, lk.RemoteParticipant> get remoteParticipants =>
      UnmodifiableMapView(remote);

  @override
  lk.EventsListener<lk.RoomEvent> createListener({bool synchronized = false}) =>
      _Listener();

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> dispose() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MatrixSdkClient implements matrix.Client {
  @override
  final String? deviceID = 'DEVICE';

  @override
  final String? userID = '@me:example.org';

  @override
  Future<matrix.GetVersionsResponse> getVersions({
    Duration cacheLifetime = const Duration(days: 3),
    bool throwOnUpdateFailure = false,
  }) async =>
      matrix.GetVersionsResponse(versions: const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MatrixSdkRoom implements matrix.Room {
  @override
  final String id = '!room:example.org';

  @override
  final matrix.Client client = _MatrixSdkClient();

  @override
  final Map<String, Map<String, matrix.Event>> states = {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profile implements Profile {
  @override
  final String identifier = '@me:example.org';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Client implements Client {
  @override
  final String identifier = '@me:example.org';

  @override
  final Profile? self = _Profile();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MatrixRoomImpl implements MatrixRoom {
  @override
  final matrix.Room matrixRoom = _MatrixSdkRoom();

  @override
  final Client client = _Client();

  @override
  final String identifier = '!room:example.org';

  @override
  final String displayName = 'Voice';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

rtc.StatsReport _report(String type, Map<String, dynamic> values) =>
    rtc.StatsReport('$type-1', type, 0, values);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeWebrtcChannel webrtc;
  late _LocalParticipant participant;
  late _Room room;
  late lk.LocalAudioTrack mic;
  late FakeSender sender;
  late MatrixLivekitVoipSession session;
  late DateTime now;
  var captured = 0.0;

  setUpAll(() async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await preferences.init();
    // ignore: invalid_use_of_visible_for_testing_member
    AudioProcessingManager.debugInstance = UnsupportedAudioProcessingManager();
  });

  setUp(() async {
    (webrtc = FakeWebrtcChannel()).install();
    // WebRTC's suppressor on: without our DSP that is what the call wants,
    // so nothing restarts the capture for noise suppression.
    (mic, sender) = await publishedMicrophone(
        const lk.AudioCaptureOptions(noiseSuppression: true));
    participant = _LocalParticipant();
    participant.publications.add(_LocalPublication(
        'TR_mic', mic, lk.TrackSource.microphone, participant));
    room = _Room(participant);
    now = DateTime(2026, 9, 26, 12);
    captured = 0;
    session = MatrixLivekitVoipSession(_MatrixRoomImpl(), room,
        // ignore: invalid_use_of_visible_for_testing_member
        now: () => now);
  });

  tearDown(() async {
    session.state = VoipState.ended;
    webrtc.uninstall();
  });

  /// Seconds of call; the capture hands over [rate] seconds a second.
  Future<void> run(int seconds, {double rate = 1}) async {
    for (var i = 0; i < seconds; i++) {
      now = now.add(const Duration(seconds: 1));
      captured += rate;
      sender.stats = [
        _report('media-source',
            {'kind': 'audio', 'totalSamplesDuration': captured}),
      ];
      // ignore: invalid_use_of_visible_for_testing_member
      await session.debugWatchVoice();
    }
  }

  test('a microphone whose capture died is reopened, the user still in',
      () async {
    await run(5);
    webrtc.enableCalls.clear();
    await run(3, rate: 0);
    expect(webrtc.enableCalls, ['mic-1=false', 'mic-1=true'],
        reason: 'the capture has to be restarted without a rejoin');
  });

  test('a muted microphone is left alone', () async {
    await run(5);
    await session.setMicrophoneMute(true);
    webrtc.enableCalls.clear();
    await run(30, rate: 0);
    expect(webrtc.enableCalls, isEmpty);
    expect(session.isMicrophoneMuted, isTrue);
  });

  test('a deafened user\'s microphone is left alone', () async {
    await run(5);
    await session.setDeafened(true);
    webrtc.enableCalls.clear();
    await run(30, rate: 0);
    expect(webrtc.enableCalls, isEmpty);
  });

  test('someone whose microphone never arrives is asked for again', () async {
    final bob = _RemoteParticipant();
    room.remote[bob.identity] = bob;
    await run(8);
    expect(bob.mic.resubscribes, greaterThanOrEqualTo(1));
  });

  test('nothing is repaired while the room reconnects', () async {
    await run(5);
    room.connectionState = lk.ConnectionState.reconnecting;
    webrtc.enableCalls.clear();
    final bob = _RemoteParticipant();
    room.remote[bob.identity] = bob;
    await run(30, rate: 0);
    expect(webrtc.enableCalls, isEmpty);
    expect(bob.mic.resubscribes, 0);
  });

  test('nothing is repaired once the call is being left', () async {
    await run(5);
    webrtc.enableCalls.clear();
    unawaited(session.hangUpCall());
    await run(10, rate: 0);
    expect(webrtc.enableCalls, isEmpty);
  });

  test('a microphone being published again shows as not muted', () async {
    await run(5);
    participant.publications.clear();
    expect(session.isMicrophoneMuted, isFalse,
        reason: 'the user did not mute; the watch is publishing it again');
    await session.setMicrophoneMute(true);
    expect(session.isMicrophoneMuted, isTrue);
  });

  test('a call that never had a microphone shows as muted', () async {
    participant.publications.clear();
    expect(session.isMicrophoneMuted, isTrue);
  });

  test('the mute button follows the microphone, not music published first',
      () async {
    final (music, _) = await publishedMicrophone(
        const lk.AudioCaptureOptions(noiseSuppression: false));
    participant.publications.insert(
        0,
        _LocalPublication(
            'TR_music', music, lk.TrackSource.unknown, participant));
    participant.publications.last.muted = true;
    expect(session.isMicrophoneMuted, isTrue);
    participant.publications.last.muted = false;
    expect(session.isMicrophoneMuted, isFalse);
  });
}
