import 'dart:async';

import 'package:collection/collection.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/profile/profile_component.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_livekit_voip_session.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:matrix/matrix.dart' as matrix;
import 'package:test/test.dart';

/// The screen capture behind a local screen share track. Stopping the track is
/// what stops the capture: on Windows that is what takes the OS "your screen
/// is being shared" indicator away.
class _Capture {
  bool running = true;
}

class _LocalVideoTrack implements lk.LocalVideoTrack {
  _LocalVideoTrack(this.capture, {this.canStop = true});

  final _Capture capture;

  /// A capture that refuses to stop. When the media track refuses to release,
  /// `Track.stop()` (`third_party/livekit-client-sdk-flutter/lib/src/track/
  /// track.dart`) throws before it clears `_active`: a stuck sender holding
  /// the native track leaves the track active.
  final bool canStop;

  /// Called while the capture is being stopped, for tests that interleave a
  /// republish with a stop still in flight.
  void Function()? onStopping;

  bool _active = false;
  bool _stopped = false;

  @override
  lk.TrackType get kind => lk.TrackType.VIDEO;

  @override
  lk.TrackSource get source => lk.TrackSource.screenShareVideo;

  @override
  bool get isActive => _active;

  /// `publishVideoTrack` starts a track before it announces it, and a
  /// reconnect republishes tracks through the same method. For a stopped
  /// track this only re-arms the wrapper (`Track.start()` flips `_active`):
  /// the capture behind it stays stopped.
  @override
  Future<bool> start() async {
    if (_active) return false;
    _active = true;
    return true;
  }

  @override
  Future<bool> stop() async {
    // `Track.stop()` returns early on an already stopped track, before it
    // touches the media track; `LocalTrack.stop()` remembers the stop.
    if (!_active && _stopped) return false;
    if (!canStop) throw Exception('the capture is stuck');
    onStopping?.call();
    capture.running = false;
    _stopped = true;
    _active = false;
    return true;
  }

  @override
  Future<bool> dispose() async => stop();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The screen audio half of a share: a second capture track the session owns
/// and has to stop too. Faked at [lk.LocalTrack] level rather than
/// `LocalAudioTrack`: the session only ever uses the owned track as a
/// [lk.LocalTrack], and the playback stream its publication builds would
/// otherwise drag the volume and visualizer platform channels into this test.
class _LocalScreenAudioTrack implements lk.LocalTrack {
  _LocalScreenAudioTrack(this.capture);

  final _Capture capture;

  @override
  lk.TrackType get kind => lk.TrackType.AUDIO;

  @override
  lk.TrackSource get source => lk.TrackSource.screenShareAudio;

  @override
  bool get isActive => capture.running;

  @override
  Future<bool> stop() async {
    capture.running = false;
    return true;
  }

  @override
  Future<bool> dispose() async {
    capture.running = false;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Publication implements lk.LocalTrackPublication<lk.LocalTrack> {
  _Publication({
    required this.sid,
    required this.participant,
    this.track,
    this.source = lk.TrackSource.screenShareVideo,
    this.kind = lk.TrackType.VIDEO,
  });

  @override
  final String sid;

  @override
  final lk.LocalParticipant participant;

  @override
  final lk.TrackSource source;

  @override
  final lk.TrackType kind;

  @override
  lk.LocalTrack? track;

  @override
  bool get muted => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The bits of `livekit_client`'s `LocalParticipant` the stop path goes
/// through, with the same semantics as livekit_client 2.7.0:
///
/// * `getTrackPublicationBySource` finds a publication by source, then falls
///   back to an untagged publication of the matching kind.
/// * `setScreenShareEnabled(false)` (LocalParticipant.setSourceEnabled) removes
///   the screen share publication and its screen audio. When it finds no
///   publication it returns null and stops nothing, with no error.
/// * `removePublishedTrack` finds the publication in its map, stops its track,
///   and only then announces that it is gone.
class _LocalParticipant implements lk.LocalParticipant {
  _LocalParticipant(this.identity);

  @override
  final String identity;

  @override
  final Map<String, lk.LocalTrackPublication> trackPublications = {};

  /// Where removals are announced, so they reach the session the same way they
  /// do in production.
  _Listener? listener;

  @override
  bool get isMuted => false;

  @override
  bool isCameraEnabled() => false;

  @override
  bool isScreenShareEnabled() =>
      !(getTrackPublicationBySource(lk.TrackSource.screenShareVideo)?.muted ??
          true);

  @override
  lk.LocalTrackPublication? getTrackPublicationBySource(lk.TrackSource source) {
    if (source == lk.TrackSource.unknown) return null;
    final result =
        trackPublications.values.firstWhereOrNull((e) => e.source == source);
    if (result != null) return result;
    return trackPublications.values
        .where((e) => e.source == lk.TrackSource.unknown)
        .firstWhereOrNull((e) =>
            (source == lk.TrackSource.microphone &&
                e.kind == lk.TrackType.AUDIO) ||
            (source == lk.TrackSource.camera && e.kind == lk.TrackType.VIDEO) ||
            (source == lk.TrackSource.screenShareVideo &&
                e.kind == lk.TrackType.VIDEO) ||
            (source == lk.TrackSource.screenShareAudio &&
                e.kind == lk.TrackType.AUDIO));
  }

  @override
  Future<lk.LocalTrackPublication?> setScreenShareEnabled(bool enabled,
      {bool? captureScreenAudio,
      lk.ScreenShareCaptureOptions? screenShareCaptureOptions}) async {
    if (enabled) throw UnimplementedError();

    final publication =
        getTrackPublicationBySource(lk.TrackSource.screenShareVideo);
    if (publication == null) return null;

    await removePublishedTrack(publication.sid);
    final screenAudio =
        getTrackPublicationBySource(lk.TrackSource.screenShareAudio);
    if (screenAudio != null) {
      await removePublishedTrack(screenAudio.sid);
    }
    return publication;
  }

  @override
  Future<void> removePublishedTrack(String trackSid,
      {bool notify = true}) async {
    final publication = trackPublications.remove(trackSid);
    if (publication == null) return;

    await publication.track?.dispose();
    if (notify) {
      listener?.emit(lk.LocalTrackUnpublishedEvent(
          participant: this, publication: publication));
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Listener implements lk.EventsListener<lk.RoomEvent> {
  final List<void Function(lk.RoomEvent)> handlers = [];

  @override
  Future<void> Function() on<E>(FutureOr<void> Function(E) then,
      {bool Function(E)? filter}) {
    handlers.add((event) async {
      if (event is! E) return;
      final typed = event as E;
      if (filter != null && !filter(typed)) return;
      await then(typed);
    });
    return () async {};
  }

  void emit(lk.RoomEvent event) {
    for (final handler in List.of(handlers)) {
      handler(event);
    }
  }

  @override
  Future<bool> dispose() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Room implements lk.Room {
  _Room(this.localParticipant);

  @override
  final lk.LocalParticipant? localParticipant;

  @override
  final UnmodifiableMapView<String, lk.RemoteParticipant> remoteParticipants =
      UnmodifiableMapView({});

  final listener = _Listener();

  bool disconnected = false;

  @override
  lk.EventsListener<lk.RoomEvent> createListener({bool synchronized = false}) =>
      listener;

  @override
  Future<void> disconnect() async {
    disconnected = true;
  }

  @override
  Future<bool> dispose() async => true;

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

class _MatrixSdkClient implements matrix.Client {
  @override
  final String? deviceID = 'DEVICE';

  @override
  final String? userID = '@me:example.org';

  @override
  Future<matrix.GetVersionsResponse> getVersions({
    Duration cacheLifetime = const Duration(days: 3),
    bool throwOnUpdateFailure = false,
  }) async {
    // No delayed events: the heartbeat is not what these tests are about.
    return matrix.GetVersionsResponse(versions: const []);
  }

  @override
  Future<String> setRoomStateWithKey(
    String roomId,
    String eventType,
    String stateKey,
    Map<String, Object?> body,
  ) async =>
      '';

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
  final String displayName = 'Test Room';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const me = '@me:example.org:DEVICE';

  late _Capture capture;
  late _Capture audioCapture;
  late _LocalParticipant participant;
  late _Room room;
  late MatrixLivekitVoipSession session;

  /// What `publishVideoTrack` / `publishAudioTrack` do once the track is
  /// ready: add the publication and announce it.
  Future<_Publication> announce(_Publication publication) async {
    participant.trackPublications[publication.sid] = publication;

    room.listener.emit(lk.LocalTrackPublishedEvent(
      participant: participant,
      publication: publication,
    ));
    await Future.delayed(Duration.zero);

    return publication;
  }

  Future<_Publication> shareScreen(
      {bool canStop = true, bool withAudio = false}) async {
    final track = _LocalVideoTrack(capture, canStop: canStop);
    // `publishVideoTrack` starts the track before it announces it.
    await track.start();
    final publication = await announce(_Publication(
      sid: 'TR_screen',
      participant: participant,
      track: track,
    ));

    if (withAudio) {
      final audio = _Publication(
        sid: 'TR_screen_audio',
        participant: participant,
        track: _LocalScreenAudioTrack(audioCapture),
        source: lk.TrackSource.screenShareAudio,
        kind: lk.TrackType.AUDIO,
      );
      await announce(audio);
    }

    return publication;
  }

  /// `LocalParticipant.rePublishAllTracks()` after a full reconnect: it clears
  /// its publication map and republishes the track objects it held, through
  /// `publishVideoTrack`, so they are started again (the wrapper only) and
  /// announced under a new sid.
  Future<_Publication> republishShare(lk.LocalTrack track,
      {String sid = 'TR_screen_republished'}) async {
    participant.trackPublications.clear();
    await track.start();
    return announce(_Publication(
      sid: sid,
      participant: participant,
      track: track,
    ));
  }

  setUp(() {
    capture = _Capture();
    audioCapture = _Capture();
    participant = _LocalParticipant(me);
    room = _Room(participant);
    participant.listener = room.listener;
    session = MatrixLivekitVoipSession(_MatrixRoomImpl(), room);
  });

  tearDown(() async {
    // The session's volume timer only stops itself once the call has ended.
    session.state = VoipState.ended;
    await Future.delayed(const Duration(milliseconds: 250));
  });

  test('stop while the publication is there stops the capture', () async {
    await shareScreen();

    await session.stopScreenshare();

    expect(capture.running, isFalse);
  });

  test(
      'stop issued once livekit no longer has the publication must still stop '
      'the capture', () async {
    await shareScreen();

    // LocalParticipant.rePublishAllTracks() clears its publications before it
    // republishes the tracks it kept (a full reconnect does this). Clearing
    // the map does not stop the capture.
    participant.trackPublications.clear();

    await session.stopScreenshare();

    expect(capture.running, isFalse,
        reason: 'the stop silently did nothing and the screen is still '
            'being captured');
  });

  test('stopping a share that is already over stays safe and silent', () async {
    await shareScreen();
    await session.stopScreenshare();

    // A second click, or an OS-ended capture: no error, nothing unhandled.
    await session.stopScreenshare();

    expect(capture.running, isFalse);
  });

  test('hanging up mid-share stops the screen and system audio captures',
      () async {
    await shareScreen(withAudio: true);

    // The reconnect window: LiveKit has cleared its publication map, so the
    // room's dispose has nothing to unpublish and the session has to stop
    // the captures itself (issue #66).
    participant.trackPublications.clear();

    await session.hangUpCall();

    expect(capture.running, isFalse,
        reason: 'hanging up left the screen being captured');
    expect(audioCapture.running, isFalse,
        reason: 'hanging up left the system audio being captured');
    expect(room.disconnected, isTrue,
        reason: 'the hang up did not reach the room teardown');
  });

  test('a stop that cannot be verified raises instead of reporting success',
      () async {
    await shareScreen(canStop: false);

    // Same reconnect window: the publication map is empty, and the capture
    // refuses to stop (a stuck sender still holds it). A stop that reports
    // success here would leave the screen captured and nothing to click.
    participant.trackPublications.clear();

    await expectLater(session.stopScreenshare(), throwsA(isA<StateError>()));

    expect(capture.running, isTrue);
  });

  test('a republished share whose capture was stopped is refused', () async {
    final original = await shareScreen();
    await session.stopScreenshare();

    // A full reconnect republishes the track objects LiveKit held before it
    // cleared its map. The user stopped this one right before, so its share
    // must not come back for a second click.
    final republished = await republishShare(original.track!);

    expect(participant.trackPublications.containsKey(republished.sid), isFalse,
        reason: 'the republished publication was not removed through livekit');
    expect(session.streams, isEmpty,
        reason: 'an outgoing stream was added for a share that was stopped');
    expect(capture.running, isFalse,
        reason: 'the republished share restarted the stopped capture');
  });

  test('a republish that lands while the stop is running is still refused',
      () async {
    final original = await shareScreen();
    final track = original.track! as _LocalVideoTrack;

    // The publication map is cleared (a full reconnect) and the republish
    // lands while the capture is being stopped: before the stop can mark it
    // stopped, so the event alone cannot tell it apart from a new share.
    participant.trackPublications.clear();
    track.onStopping = () {
      announce(_Publication(
        sid: 'TR_screen_republished',
        participant: participant,
        track: track,
      ));
    };

    await session.stopScreenshare();

    expect(participant.trackPublications.containsKey('TR_screen_republished'),
        isFalse);
    expect(session.streams.where((s) => s.streamId == 'TR_screen_republished'),
        isEmpty,
        reason: 'a stream from the mid-stop republish stayed on the panel');
    expect(capture.running, isFalse);
  });

  test('a share started after one was stopped is not refused', () async {
    await shareScreen();
    await session.stopScreenshare();

    // A new share creates its own capture tracks, so the refusal check does
    // not match: starting to share again after stopping must still work.
    final fresh = _LocalVideoTrack(_Capture());
    final publication = await republishShare(fresh, sid: 'TR_screen_2');

    expect(participant.trackPublications.containsKey(publication.sid), isTrue);
    expect(session.streams.where((s) => s.streamId == publication.sid),
        isNotEmpty);
  });
}
