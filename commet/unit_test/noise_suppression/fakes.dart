// Test doubles for the noise suppression tests: the flutter_webrtc method
// channel, an RTP sender that remembers what it is sending, and a track
// processor standing in for the web AudioWorklet.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart' as lk;

/// Answers flutter_webrtc's platform calls: every getUserMedia returns a new
/// microphone track, and the constraints it was asked for are kept.
class FakeWebrtcChannel {
  static const channel = MethodChannel('FlutterWebRTC.Method');

  final List<Map<String, dynamic>> getUserMediaCalls = [];
  final List<String> stoppedTracks = [];

  /// `trackId=enabled` for every mediaStreamTrackSetEnable, in order.
  final List<String> enableCalls = [];

  /// Runs while the platform handles a mediaStreamTrackSetEnable.
  void Function(String trackId, bool enabled)? onEnable;
  int _next = 0;

  /// How many of the next getUserMedia calls fail, as one does when the
  /// device is gone or held by another application.
  int failGetUserMedia = 0;

  /// Runs while the platform opens a capture.
  Future<void> Function()? onGetUserMedia;

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
      switch (call.method) {
        case 'getUserMedia':
          getUserMediaCalls
              .add(Map<String, dynamic>.from(args['constraints'] as Map));
          await onGetUserMedia?.call();
          if (failGetUserMedia > 0) {
            failGetUserMedia--;
            throw PlatformException(
                code: 'getUserMediaFailed', message: 'device unavailable');
          }
          final n = ++_next;
          return {
            'streamId': 'mic-stream-$n',
            'audioTracks': [
              {'id': 'mic-$n', 'label': 'mic', 'kind': 'audio', 'enabled': true}
            ],
            'videoTracks': [],
          };
        case 'mediaStreamTrackSetEnable':
          enableCalls.add('${args['trackId']}=${args['enabled']}');
          onEnable?.call(args['trackId'] as String, args['enabled'] as bool);
          return null;
        // MediaStreamTrackNative.stop().
        case 'trackDispose':
        case 'mediaStreamTrackStop':
          stoppedTracks.add(args['trackId'] as String);
          return null;
        default:
          return null;
      }
    });
  }

  void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  }

  /// The audio constraints of the last getUserMedia call, with LiveKit's
  /// `optional` list flattened the way the platform code reads it.
  Map<String, dynamic> lastAudioConstraints() {
    final audio = getUserMediaCalls.last['audio'];
    if (audio is! Map) return {};
    final flat = <String, dynamic>{};
    for (final entry in audio.entries) {
      if (entry.key == 'optional' && entry.value is List) {
        for (final m in entry.value as List) {
          flat.addAll(Map<String, dynamic>.from(m as Map));
        }
      } else if (entry.key == 'mandatory' && entry.value is Map) {
        flat.addAll(Map<String, dynamic>.from(entry.value as Map));
      } else {
        flat[entry.key as String] = entry.value;
      }
    }
    return flat;
  }
}

class FakeSender implements rtc.RTCRtpSender {
  @override
  rtc.MediaStreamTrack? track;

  final List<rtc.MediaStreamTrack?> history = [];

  /// What getStats answers.
  List<rtc.StatsReport> stats = [];

  @override
  Future<void> replaceTrack(rtc.MediaStreamTrack? t) async {
    track = t;
    history.add(t);
  }

  @override
  Future<List<rtc.StatsReport>> getStats() async => stats;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTransceiver implements rtc.RTCRtpTransceiver {
  @override
  final FakeSender sender;

  FakeTransceiver(this.sender);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A processed track that is not backed by the platform.
class FakeProcessedTrack implements rtc.MediaStreamTrack {
  @override
  final String id;

  FakeProcessedTrack(this.id);

  @override
  String get kind => 'audio';

  @override
  bool enabled = true;

  bool stopped = false;

  @override
  Future<void> stop() async => stopped = true;

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => 'FakeProcessedTrack($id)';
}

/// Stands in for CommetWebTrackProcessor: every init builds a new graph with
/// a new processed track, fed by the microphone track it was given.
class FakeAudioProcessor
    implements lk.TrackProcessor<lk.AudioProcessorOptions> {
  final List<String> initInputs = [];
  int destroyed = 0;
  FakeProcessedTrack? _processed;

  /// Makes the next init fail the way a missing audio_dsp.wasm does.
  bool failNextInit = false;

  @override
  String get name => 'fake-dsp';

  @override
  rtc.MediaStreamTrack? get processedTrack => _processed;

  bool get running => _processed != null;

  @override
  Future<void> init(lk.AudioProcessorOptions options) async {
    initInputs.add(options.track.id!);
    if (failNextInit) {
      failNextInit = false;
      return;
    }
    _processed = FakeProcessedTrack('processed-${initInputs.length}');
  }

  @override
  Future<void> restart(lk.AudioProcessorOptions options) async {
    await destroy();
    await init(options);
  }

  @override
  Future<void> destroy() async {
    destroyed++;
    _processed = null;
  }

  @override
  Future<void> onPublish(lk.Room room) async {}

  @override
  Future<void> onUnpublish() async {}
}

/// A LiveKit microphone track created with [options] and put on a sender,
/// as publishing does.
Future<(lk.LocalAudioTrack, FakeSender)> publishedMicrophone(
    lk.AudioCaptureOptions options) async {
  final track = await lk.LocalAudioTrack.create(options);
  final sender = FakeSender();
  track.transceiver = FakeTransceiver(sender);
  await sender.replaceTrack(track.mediaStreamTrack);
  await track.start();
  return (track, sender);
}
