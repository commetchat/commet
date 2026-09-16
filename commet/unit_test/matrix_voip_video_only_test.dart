import 'package:commet/client/matrix/components/voip/matrix_voip_stream.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:test/test.dart';

class _Track implements MediaStreamTrack {
  _Track(this.kind);

  @override
  final String kind;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Stream implements MediaStream {
  _Stream({required this.ownerTag, required this.tracks});

  @override
  final String ownerTag;
  final List<MediaStreamTrack> tracks;

  @override
  List<MediaStreamTrack> getAudioTracks() =>
      tracks.where((t) => t.kind == 'audio').toList();

  @override
  List<MediaStreamTrack> getVideoTracks() =>
      tracks.where((t) => t.kind == 'video').toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Behaves like flutter-webrtc's web renderer: assigning a stream with audio
/// creates the renderer's own <audio> element, muted only for local streams,
/// and `muted` only reaches an element that already exists.
class _WebRenderer implements VideoRenderer {
  MediaStream? _source;
  bool _muted = false;

  /// Null while the renderer has no <audio> element.
  bool? audioElementMuted;

  @override
  MediaStream? get srcObject => _source;

  @override
  set srcObject(MediaStream? stream) {
    _source = stream;
    if (stream != null && stream.getAudioTracks().isNotEmpty) {
      audioElementMuted ??= stream.ownerTag == 'local';
    }
  }

  @override
  bool get muted => _muted;

  @override
  set muted(bool mute) {
    _muted = mute;
    if (audioElementMuted != null) audioElementMuted = mute;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Behaves like flutter-webrtc's native renderer, which mutes the track
/// itself and refuses to for remote streams.
class _NativeRenderer implements VideoRenderer {
  @override
  MediaStream? srcObject;

  @override
  set muted(bool mute) =>
      throw Exception('You\'re trying to mute a remote track');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final remoteCall =
      _Stream(ownerTag: 'remote', tracks: [_Track('audio'), _Track('video')]);

  test('on web, a view of a remote stream does not play its audio again', () {
    final renderer = _WebRenderer();

    attachVideoOnly(renderer, remoteCall, isWeb: true);

    expect(renderer.srcObject, remoteCall);
    expect(renderer.audioElementMuted, isTrue);
  });

  test('on web, the view stays silent when the stream gains audio later', () {
    final renderer = _WebRenderer();
    final cameraOnly = _Stream(ownerTag: 'remote', tracks: [_Track('video')]);

    attachVideoOnly(renderer, cameraOnly, isWeb: true);
    attachVideoOnly(renderer, remoteCall, isWeb: true);

    expect(renderer.audioElementMuted, isTrue);
  });

  test('on native, a view leaves the stream\'s audio alone', () {
    final renderer = _NativeRenderer();

    attachVideoOnly(renderer, remoteCall, isWeb: false);

    expect(renderer.srcObject, remoteCall);
  });
}
