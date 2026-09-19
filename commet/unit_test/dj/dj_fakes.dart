import 'dart:async';
import 'dart:convert';

import 'package:commet/client/components/dj/dj_engine.dart';
import 'package:commet/client/components/dj/dj_links.dart';
import 'package:commet/client/components/dj/dj_models.dart';

/// A call: every transport joined to it hears the others, in order, one
/// microtask later, as JSON that went over the wire.
class FakeCall {
  final Map<String, FakeDjTransport> members = {};

  /// Every message sent, for assertions.
  final List<(String from, Map<String, Object?> message, List<String>? to)>
      log = [];

  FakeDjTransport join(String identity) {
    final transport = FakeDjTransport(this, identity);
    for (final other in members.values) {
      other._joined.add(identity);
    }
    members[identity] = transport;
    return transport;
  }

  void leave(String identity) {
    members.remove(identity);
    for (final other in members.values) {
      other._left.add(identity);
    }
  }
}

class FakeDjTransport implements DjTransport {
  final FakeCall call;
  @override
  final String selfIdentity;

  final StreamController<DjIncoming> _incoming = StreamController.broadcast();
  final StreamController<String> _joined = StreamController.broadcast();
  final StreamController<String> _left = StreamController.broadcast();
  final StreamController<void> reconnects = StreamController.broadcast();

  @override
  Stream<void> get reconnected => reconnects.stream;

  /// LiveKit reports [identity] gone (without them leaving the call).
  void receiveLeft(String identity) => _left.add(identity);

  /// Messages this transport drops instead of sending (by type).
  final Set<String> drop = {};

  /// Senders whose messages never reach this transport.
  final Set<String> deafTo = {};

  FakeDjTransport(this.call, this.selfIdentity);

  @override
  Future<void> send(Map<String, Object?> message, {List<String>? to}) async {
    final type = message['t'] as String;
    if (drop.contains(type)) return;
    final wire = jsonEncode(message);
    call.log.add((selfIdentity, message, to));
    for (final member in call.members.values.toList()) {
      if (member.selfIdentity == selfIdentity) continue;
      if (to != null && !to.contains(member.selfIdentity)) continue;
      scheduleMicrotask(() {
        if (member._incoming.isClosed) return;
        if (member.deafTo.contains(selfIdentity)) return;
        member._incoming.add(DjIncoming(
            selfIdentity, jsonDecode(wire) as Map<String, Object?>));
      });
    }
  }

  @override
  Stream<DjIncoming> get incoming => _incoming.stream;

  @override
  Stream<String> get participantJoined => _joined.stream;

  @override
  Stream<String> get participantLeft => _left.stream;

  @override
  bool isPresent(String identity) => call.members.containsKey(identity);

  @override
  Future<void> dispose() async {
    await _incoming.close();
  }
}

/// A player that "plays" by the clock of the test.
class FakeEngine implements DjPlaybackEngine {
  final String name;
  bool started = false;
  bool shutDown = false;
  final List<String> prepared = [];
  final List<(String id, int position, bool paused)> played = [];

  /// Tracks whose fetch fails.
  final Set<String> failing = {};

  /// When set, prepare waits for it.
  Completer<void>? gate;

  DjTrack? _loaded;
  int _position = 0;
  bool _paused = false;
  DjEngineState _state = DjEngineState.idle;
  double monitor = 1;

  FakeEngine(this.name);

  @override
  Future<void> start() async {
    started = true;
  }

  @override
  Future<void> shutdown() async {
    shutDown = true;
    _loaded = null;
    _state = DjEngineState.idle;
  }

  @override
  Future<DjTrackInfo> prepare(DjTrack track) async {
    prepared.add(track.id);
    if (gate != null) await gate!.future;
    if (failing.contains(track.id)) throw Exception('no such video');
    return DjTrackInfo(durationMs: 180000, title: 'Fetched ${track.title}');
  }

  @override
  void load(DjTrack track, {required int positionMs, required bool paused}) {
    if (!prepared.contains(track.id)) throw StateError('not fetched');
    played.add((track.id, positionMs, paused));
    _loaded = track;
    _position = positionMs;
    _paused = paused;
    _state = paused ? DjEngineState.paused : DjEngineState.playing;
  }

  @override
  void setPaused(bool paused) {
    _paused = paused;
    if (_loaded != null) {
      _state = paused ? DjEngineState.paused : DjEngineState.playing;
    }
  }

  @override
  Future<void> seek(int positionMs) async {
    _position = positionMs;
  }

  @override
  void unload() {
    _loaded = null;
    _state = DjEngineState.idle;
  }

  /// Moves playback on, as the audio thread would.
  void advance(int ms) {
    if (_loaded != null && !_paused) _position += ms;
  }

  void finish() => _state = DjEngineState.ended;

  bool get isPaused => _paused;
  String? get loadedId => _loaded?.id;

  @override
  DjEngineStatus get status => DjEngineStatus(
      state: _state,
      trackId: _loaded?.id,
      positionMs: _position,
      durationMs: 180000);

  @override
  set monitorVolume(double volume) => monitor = volume;
}

/// Turns any link into [count] tracks titled after it.
class FakeResolver implements DjResolver {
  int count;
  int _next = 0;
  final Set<String> failing = {};

  FakeResolver({this.count = 1});

  @override
  Future<List<DjTrack>> resolve(DjLink link, {required String addedBy}) async {
    if (failing.contains(link.url)) throw Exception('not found');
    return [
      for (var i = 0; i < count; i++)
        DjTrack(
          id: 'track${_next++}',
          source: link.url,
          kind: link.source,
          title: '${link.url} #$i',
          addedBy: addedBy,
          durationMs: 180000,
        ),
    ];
  }
}

DjTrack track(String id, {String? title}) => DjTrack(
      id: id,
      source: 'https://www.youtube.com/watch?v=$id',
      kind: DjSource.youtube,
      title: title ?? 'Song $id',
      addedBy: '@a:x',
      durationMs: 180000,
    );

/// Lets queued messages and the futures they start run.
Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
