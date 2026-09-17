import 'package:commet/client/matrix/components/voip_room/matrix_livekit_voip_stream.dart';
import 'package:commet/client/matrix/components/voip_room/screen_share_watch_list.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:test/test.dart';

class _Participant implements RemoteParticipant {
  _Participant(this.identity);

  @override
  final String identity;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RemotePublication implements RemoteTrackPublication<RemoteTrack> {
  _RemotePublication(this.participant, this.kind, this.source);

  @override
  final RemoteParticipant participant;

  @override
  final TrackType kind;

  @override
  final TrackSource source;

  @override
  final String sid = 'TR_screen';

  @override
  RemoteTrack? get track => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LocalPublication implements LocalTrackPublication<LocalTrack> {
  @override
  final TrackType kind = TrackType.VIDEO;

  @override
  final TrackSource source = TrackSource.screenShareVideo;

  @override
  LocalTrack? get track => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Stands in for the session.
class _Watching implements ScreenShareWatching {
  final list = ScreenShareWatchList();
  final calls = <(String, bool)>[];

  @override
  bool isWatchingScreenShare(String participantIdentity) =>
      list.isWatching(participantIdentity);

  @override
  Future<void> setWatchingScreenShare(
      String participantIdentity, bool watch) async {
    calls.add((participantIdentity, watch));
    watch
        ? list.watch(participantIdentity)
        : list.stopWatching(participantIdentity);
  }
}

void main() {
  const alice = '@alice:example.org:DEVICE';
  const bob = '@bob:example.org:DEVICE';

  group('ScreenShareWatchList', () {
    test('screen shares are not subscribed until watched', () {
      final list = ScreenShareWatchList();
      list.onScreenSharePublished(alice);

      expect(
          list.shouldSubscribe(alice, TrackSource.screenShareVideo), isFalse);
      expect(
          list.shouldSubscribe(alice, TrackSource.screenShareAudio), isFalse);
    });

    test('mic and camera are always subscribed', () {
      final list = ScreenShareWatchList();

      expect(list.shouldSubscribe(alice, TrackSource.microphone), isTrue);
      expect(list.shouldSubscribe(alice, TrackSource.camera), isTrue);
    });

    test('watching subscribes to screen video and screen audio', () {
      final list = ScreenShareWatchList();

      expect(list.watch(alice), isTrue);

      expect(list.shouldSubscribe(alice, TrackSource.screenShareVideo), isTrue);
      expect(list.shouldSubscribe(alice, TrackSource.screenShareAudio), isTrue);
    });

    test('stopping watching unsubscribes both but keeps the mic', () {
      final list = ScreenShareWatchList()..watch(alice);

      expect(list.stopWatching(alice), isTrue);

      expect(
          list.shouldSubscribe(alice, TrackSource.screenShareVideo), isFalse);
      expect(
          list.shouldSubscribe(alice, TrackSource.screenShareAudio), isFalse);
      expect(list.shouldSubscribe(alice, TrackSource.microphone), isTrue);
    });

    test('watching one sharer does not watch another', () {
      final list = ScreenShareWatchList()..watch(alice);

      expect(list.shouldSubscribe(bob, TrackSource.screenShareVideo), isFalse);
    });

    test('watching twice reports no change', () {
      final list = ScreenShareWatchList()..watch(alice);

      expect(list.watch(alice), isFalse);
      expect(list.stopWatching(bob), isFalse);
    });

    test('the next share needs opting in again once the share ends', () {
      final list = ScreenShareWatchList()..watch(alice);

      list.onScreenShareEnded(alice);
      list.onScreenSharePublished(alice);

      expect(list.isWatching(alice), isFalse);
    });

    test('auto-watch plays new screen shares straight away', () {
      var autoWatch = true;
      final list = ScreenShareWatchList(autoWatch: () => autoWatch);

      list.onScreenSharePublished(alice);
      autoWatch = false;
      list.onScreenSharePublished(bob);

      expect(list.isWatching(alice), isTrue);
      expect(list.isWatching(bob), isFalse);
    });
  });

  group('MatrixLivekitVoipStream watching', () {
    late _Watching watching;

    setUp(() => watching = _Watching());

    MatrixLivekitVoipStream remote(TrackType kind, TrackSource source) =>
        MatrixLivekitVoipStream(
            _RemotePublication(_Participant(alice), kind, source),
            '@alice:example.org',
            watching: watching);

    test('a remote screen share needs watching and starts unwatched', () {
      final stream = remote(TrackType.VIDEO, TrackSource.screenShareVideo);

      expect(stream.requiresWatching, isTrue);
      expect(stream.isWatching, isFalse);
    });

    test('watch and stop watching go through the session', () async {
      final screen = remote(TrackType.VIDEO, TrackSource.screenShareVideo);
      final screenAudio = remote(TrackType.AUDIO, TrackSource.screenShareAudio);

      await screen.watch();
      expect(screen.isWatching, isTrue);
      expect(screenAudio.isWatching, isTrue);

      await screen.stopWatching();
      expect(screen.isWatching, isFalse);
      expect(screenAudio.isWatching, isFalse);

      expect(watching.calls, [(alice, true), (alice, false)]);
    });

    test('mic and camera always play', () async {
      final mic = remote(TrackType.AUDIO, TrackSource.microphone);
      final camera = remote(TrackType.VIDEO, TrackSource.camera);

      expect(mic.requiresWatching, isFalse);
      expect(mic.isWatching, isTrue);
      expect(camera.requiresWatching, isFalse);

      await mic.stopWatching();
      expect(watching.calls, isEmpty);
    });

    test('your own screen share always plays', () {
      final stream = MatrixLivekitVoipStream(
          _LocalPublication(), '@me:example.org',
          watching: watching);

      expect(stream.requiresWatching, isFalse);
      expect(stream.isWatching, isTrue);
    });
  });
}
