import 'package:commet/client/matrix/components/voip_room/matrix_livekit_voip_stream.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';
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
  @override
  final String sid = 'TR_bob_mic';

  @override
  final TrackType kind = TrackType.AUDIO;

  @override
  final TrackSource source = TrackSource.microphone;

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
      setTrackVolume: (volume, track) async => volumes.add((volume, track.id)),
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
}
