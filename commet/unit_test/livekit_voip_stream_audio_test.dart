import 'package:commet/client/matrix/components/voip_room/matrix_livekit_voip_stream.dart';
import 'package:commet/main.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

class _MediaTrack implements rtc.MediaStreamTrack {
  _MediaTrack(this.id);

  @override
  final String id;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AudioTrack implements RemoteAudioTrack {
  _AudioTrack(String id) : mediaStreamTrack = _MediaTrack(id);

  @override
  final rtc.MediaStreamTrack mediaStreamTrack;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A remote publication whose track arrives when LiveKit subscribes to it,
/// after the publication was announced.
class _Publication implements RemoteTrackPublication<RemoteTrack> {
  _Publication([this.source = TrackSource.microphone]);

  @override
  final String sid = 'TR_bob_mic';

  @override
  final TrackType kind = TrackType.AUDIO;

  @override
  final TrackSource source;

  @override
  RemoteTrack? track;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Visualizer extends AudioVisualizer {
  int starts = 0;
  int stops = 0;

  @override
  Future<void> start() async => starts++;

  @override
  Future<void> stop() async => stops++;
}

void main() {
  late _Publication publication;
  late List<(double, String?)> volumes;
  late List<_Visualizer> visualizers;
  late MatrixLivekitVoipStream stream;

  setUp(() {
    publication = _Publication();
    volumes = [];
    visualizers = [];
    stream = MatrixLivekitVoipStream(
      publication,
      '@bob:example.org',
      setTrackVolume: (volume, track) async =>
          volumes.add((volume, track.mediaStreamTrack.id)),
      createAudioVisualizer: (track) {
        final visualizer = _Visualizer();
        visualizers.add(visualizer);
        return visualizer;
      },
    );
  });

  test('a track that arrives later plays at the volume chosen before', () {
    stream.applyVolume(0.3);
    expect(volumes, isEmpty);

    publication.track = _AudioTrack('bob-mic');
    stream.onTrackSubscribed();

    expect(volumes, [(0.3, 'bob-mic')]);
  });

  test('a deafened listener does not hear a track that arrives later', () {
    stream.applyVolume(0.0);

    publication.track = _AudioTrack('bob-mic');
    stream.onTrackSubscribed();

    expect(volumes.last, (0.0, 'bob-mic'));
  });

  test('the speaking indicator starts listening once the track arrives', () {
    expect(visualizers, isEmpty);

    publication.track = _AudioTrack('bob-mic');
    stream.onTrackSubscribed();
    stream.onTrackSubscribed();

    expect(visualizers, hasLength(1));
    expect(visualizers.single.starts, 1);
  });

  test('a stream that goes away stops listening', () async {
    publication.track = _AudioTrack('bob-mic');
    stream.onTrackSubscribed();

    await stream.dispose();

    expect(visualizers.single.stops, 1);
  });

  test('a new track after unsubscribing gets its own listener', () async {
    publication.track = _AudioTrack('bob-mic');
    stream.onTrackSubscribed();

    publication.track = null;
    await stream.onTrackUnsubscribed();
    publication.track = _AudioTrack('bob-mic-2');
    stream.onTrackSubscribed();

    expect(visualizers, hasLength(2));
    expect(visualizers.first.stops, 1);
    expect(visualizers.last.starts, 1);
  });

  group('saved volume', () {
    late MatrixLivekitVoipStream screenAudio;

    setUp(() async {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      await preferences.init();

      screenAudio = MatrixLivekitVoipStream(
        _Publication(TrackSource.screenShareAudio)
          ..track = _AudioTrack('bob-screen'),
        '@bob:example.org',
        setTrackVolume: (volume, track) async =>
            volumes.add((volume, track.mediaStreamTrack.id)),
        createAudioVisualizer: (_) => _Visualizer(),
      );
    });

    test('screen share volume is kept apart from the voice volume', () async {
      await screenAudio.setVolume(0.2);
      await stream.setVolume(1.5);

      expect(screenAudio.volume, 0.2);
      expect(stream.volume, 1.5);
      expect(preferences.getVoipScreenShareVolume('@bob:example.org'), 0.2);
      expect(preferences.getVoipUserVolume('@bob:example.org'), 1.5);
    });

    test('a later screen share from the same user gets the saved volume',
        () async {
      await screenAudio.setVolume(0.4);
      volumes.clear();

      MatrixLivekitVoipStream(
        _Publication(TrackSource.screenShareAudio)
          ..track = _AudioTrack('bob-screen-2'),
        '@bob:example.org',
        setTrackVolume: (volume, track) async =>
            volumes.add((volume, track.mediaStreamTrack.id)),
        createAudioVisualizer: (_) => _Visualizer(),
      );

      expect(volumes, [(0.4, 'bob-screen-2')]);
    });

    test('changing the volume while deafened is saved but stays silent',
        () async {
      screenAudio.listenerDeafened = true;
      volumes.clear();

      await screenAudio.setVolume(0.8);

      expect(screenAudio.volume, 0.8);
      expect(volumes, [(0.0, 'bob-screen')]);
    });
  });
}
