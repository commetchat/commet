import 'dart:async';

import 'package:collection/collection.dart';
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

  @override
  lk.TrackType get kind => lk.TrackType.VIDEO;

  @override
  lk.TrackSource get source => lk.TrackSource.screenShareVideo;

  @override
  bool get isActive => capture.running;

  @override
  Future<bool> stop() async {
    if (!canStop) throw Exception('the capture is stuck');
    capture.running = false;
    return true;
  }

  @override
  Future<bool> dispose() async {
    if (!canStop) throw Exception('the capture is stuck');
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
  });

  @override
  final String sid;

  @override
  final lk.LocalParticipant participant;

  @override
  final lk.TrackSource source = lk.TrackSource.screenShareVideo;

  @override
  final lk.TrackType kind = lk.TrackType.VIDEO;

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

  @override
  lk.EventsListener<lk.RoomEvent> createListener({bool synchronized = false}) =>
      listener;

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MatrixRoomImpl implements MatrixRoom {
  @override
  final matrix.Room matrixRoom = _MatrixSdkRoom();

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
  late _LocalParticipant participant;
  late _Room room;
  late MatrixLivekitVoipSession session;

  Future<_Publication> shareScreen({bool canStop = true}) async {
    final publication = _Publication(
      sid: 'TR_screen',
      participant: participant,
      track: _LocalVideoTrack(capture, canStop: canStop),
    );
    participant.trackPublications[publication.sid] = publication;

    room.listener.emit(lk.LocalTrackPublishedEvent(
      participant: participant,
      publication: publication,
    ));
    await Future.delayed(Duration.zero);
    return publication;
  }

  setUp(() {
    capture = _Capture();
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
}
