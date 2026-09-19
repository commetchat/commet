// Adversarial review, round 2. Every test here asserts what the design
// promises and demonstrates a bug that remains after the round-1 rework.
//
// The network below has a delivery budget: the bugs include message loops
// that would otherwise spin the microtask queue forever and hang the test.
import 'dart:async';
import 'dart:convert';

import 'package:commet/client/components/dj/dj_engine.dart';
import 'package:commet/client/components/dj/dj_links.dart';
import 'package:commet/client/components/dj/dj_models.dart';
import 'package:commet/client/components/dj/dj_session.dart';
import 'package:commet/client/matrix/components/dj/native/native_dj_engine.dart';
import 'package:test/test.dart';

import '../dj_fakes.dart';

const desktop = DjCaps(canDj: true, platform: 'linux');

class Net {
  final Map<String, NetT> members = {};

  /// Deliveries allowed in the whole test; a loop stops here.
  final int budget;
  int delivered = 0;

  /// (from, to, type) of every delivery.
  final List<(String, String, String)> log = [];

  /// When set, every packet takes this long to leave its sender.
  Duration? packetDelay;

  Net({this.budget = 4000});

  bool get exhausted => delivered >= budget;

  /// Out of the room for now (see [away]).
  final Set<String> awayIds = {};

  NetT join(String identity) {
    final t = NetT(this, identity);
    for (final other in members.values) {
      if (awayIds.contains(other.selfIdentity)) {
        // Neither sees the other until it is back.
        t.hidden.add(other.selfIdentity);
        other.hidden.add(identity);
        continue;
      }
      other.joined.add(identity);
    }
    members[identity] = t;
    return t;
  }

  /// [observer] sees [identity] leave; nothing passes between them.
  void vanish(String observer, String identity) {
    members[observer]!.hidden.add(identity);
    members[observer]!.left.add(identity);
  }

  void reappear(String observer, String identity, {bool announce = true}) {
    members[observer]!.hidden.remove(identity);
    if (announce) members[observer]!.joined.add(identity);
  }

  /// [identity] drops out of the room (a LiveKit full reconnect).
  void away(String identity) {
    awayIds.add(identity);
    for (final o in members.keys.where((k) => k != identity).toList()) {
      vanish(o, identity);
      vanish(identity, o);
    }
  }

  /// ...and is back: the others see it join, it reports a reconnect.
  void back(String identity) {
    awayIds.remove(identity);
    for (final o in members.keys.where((k) => k != identity).toList()) {
      reappear(o, identity);
      // The SDK does not announce join-response participants.
      reappear(identity, o, announce: false);
    }
    members[identity]!.reconnects.add(null);
  }

  int count(String from, String to, String type) =>
      log.where((e) => e.$1 == from && e.$2 == to && e.$3 == type).length;
}

class NetT implements DjTransport {
  final Net net;
  @override
  final String selfIdentity;
  final Set<String> hidden = {};

  /// Senders this member does not hear (messages lost on the way).
  final Set<String> deafTo = {};
  final StreamController<DjIncoming> incomingC = StreamController.broadcast();
  final StreamController<String> joined = StreamController.broadcast();
  final StreamController<String> left = StreamController.broadcast();
  final StreamController<void> reconnects = StreamController.broadcast();

  NetT(this.net, this.selfIdentity);

  @override
  Stream<void> get reconnected => reconnects.stream;

  @override
  Future<void> send(Map<String, Object?> message, {List<String>? to}) async {
    final delay = net.packetDelay;
    if (delay != null) await Future<void>.delayed(delay);
    final wire = jsonEncode(message);
    for (final m in net.members.values.toList()) {
      if (m.selfIdentity == selfIdentity) continue;
      if (to != null && !to.contains(m.selfIdentity)) continue;
      if (hidden.contains(m.selfIdentity) || m.hidden.contains(selfIdentity)) {
        continue;
      }
      if (m.deafTo.contains(selfIdentity)) continue;
      if (net.exhausted) return;
      net.delivered++;
      net.log.add((selfIdentity, m.selfIdentity, message['t'] as String));
      scheduleMicrotask(() {
        if (m.incomingC.isClosed) return;
        m.incomingC.add(
            DjIncoming(selfIdentity, jsonDecode(wire) as Map<String, Object?>));
      });
    }
  }

  @override
  Stream<DjIncoming> get incoming => incomingC.stream;
  @override
  Stream<String> get participantJoined => joined.stream;
  @override
  Stream<String> get participantLeft => left.stream;
  @override
  bool isPresent(String identity) =>
      identity == selfIdentity ||
      (net.members.containsKey(identity) && !hidden.contains(identity));
  @override
  Future<void> dispose() async => incomingC.close();
}

/// Resolves to [count] tracks whose JSON does not shrink.
class BigResolver extends FakeResolver {
  BigResolver(int count) : super(count: count);

  @override
  Future<List<DjTrack>> resolve(DjLink link, {required String addedBy}) async {
    var seed = 7;
    String noise() => List.generate(40, (_) {
          seed = (seed * 1103515245 + 12345) & 0x7fffffff;
          return String.fromCharCode(97 + seed % 26);
        }).join();
    return [
      for (var i = 0; i < count; i++)
        DjTrack(
            id: 'n$i',
            source: 'https://www.youtube.com/watch?v=${noise()}',
            kind: DjSource.youtube,
            title: noise(),
            addedBy: addedBy,
            durationMs: 180000),
    ];
  }
}

void main() {
  final sessions = <DjSession>[];

  DjSession make(DjTransport t,
      {DjPlaybackEngine Function()? engine, FakeResolver? resolver}) {
    final s = DjSession(
      transport: t,
      caps: desktop,
      selfUserId: djUserIdOf(t.selfIdentity),
      engineFactory: engine ?? () => FakeEngine(t.selfIdentity),
      resolver: resolver ?? FakeResolver(),
      tickInterval: const Duration(milliseconds: 40),
      pollInterval: const Duration(milliseconds: 10),
    )..start();
    sessions.add(s);
    return s;
  }

  tearDown(() async {
    for (final s in sessions) {
      await s.dispose();
    }
    sessions.clear();
  });

  test(
      'N1: a newcomer who joined while the DJ was reconnecting ping-pongs '
      'states with the DJ forever', () async {
    final net = Net();
    final d = make(net.join('@d:x:D'));
    final l = make(net.join('@l:x:L'));
    await settle();
    await d.becomeDj();
    d.addLinks('https://youtu.be/aaaaaaaaaaa');
    await settle();
    expect(l.djIdentity, '@d:x:D');

    // The DJ's connection restarts: everyone sees it leave.
    net.away('@d:x:D');
    await settle();
    expect(l.djIdentity, isNull);

    // Someone joins meanwhile, and learns the "empty" booth from l.
    final n = make(net.join('@n:x:N'));
    await settle();
    expect(n.snapshot.epoch, d.snapshot.epoch);
    expect(n.djIdentity, isNull);

    // The DJ is back and says so.
    net.back('@d:x:D');
    await settle();

    final ping = net.count('@n:x:N', '@d:x:D', 'state');
    final pong = net.count('@d:x:D', '@n:x:N', 'state');
    expect(net.exhausted, isFalse,
        reason: 'n->d states: $ping, d->n states: $pong, '
            '${net.delivered} deliveries');
    expect(n.djIdentity, '@d:x:D',
        reason: 'n shows an empty booth ("Become DJ") while d plays');
  });

  test(
      'N2: the DJ stops (or hangs up) just as the pass target announces: '
      'endless state loop and a split room', () async {
    final net = Net();
    final a = make(net.join('@a:x:A'));
    final gate = Completer<void>();
    final b = make(net.join('@b:x:B'),
        engine: () => FakeEngine('@b:x:B')..gate = gate);
    final c = make(net.join('@c:x:C'));
    await settle();
    await a.becomeDj();
    a.addLinks('https://youtu.be/aaaaaaaaaaa');
    await settle();

    a.passTo('@b:x:B');
    await settle();
    expect(b.isJoining, isTrue);

    // The two messages cross: b announces before a's release reaches it.
    net.members['@b:x:B']!.deafTo.add('@a:x:A');
    await a.stopDjing();
    await settle();
    expect(c.djIdentity, isNull);
    gate.complete();
    await settle();
    net.members['@b:x:B']!.deafTo.clear();
    await settle();

    expect(net.exhausted, isFalse,
        reason: 'b<->c states: ${net.count('@b:x:B', '@c:x:C', 'state')}/'
            '${net.count('@c:x:C', '@b:x:B', 'state')}');
    expect(c.djIdentity, b.djIdentity,
        reason: 'b thinks the DJ is ${b.djIdentity}, c ${c.djIdentity}');
  });

  test('N3: passing the booth and then hanging up loses the pass', () async {
    final net = Net();
    final a = make(net.join('@a:x:A'));
    final gate = Completer<void>();
    final b = make(net.join('@b:x:B'),
        engine: () => FakeEngine('@b:x:B')..gate = gate);
    final c = make(net.join('@c:x:C'));
    await settle();
    await a.becomeDj();
    a.addLinks('https://youtu.be/aaaaaaaaaaa');
    await settle();

    a.passTo('@b:x:B');
    await settle();
    expect(b.isJoining, isTrue);

    // "Here, you take it" -- and the DJ leaves the call while b downloads.
    sessions.remove(a);
    await a.dispose();
    net.members.remove('@a:x:A');
    for (final m in net.members.values) {
      m.left.add('@a:x:A');
    }
    await settle();
    gate.complete();
    await settle();

    expect(b.isDj, isTrue, reason: 'the pass was called off by the hang up');
    expect(c.djIdentity, '@b:x:B');
  });

  test(
      'N4: a listener that missed the DJ coming back ignores its ticks and '
      'keeps offering the booth', () async {
    final net = Net();
    final d = make(net.join('@d:x:D'));
    final l = make(net.join('@l:x:L'));
    await settle();
    await d.becomeDj();
    d.addLinks('https://youtu.be/aaaaaaaaaaa');
    await settle();

    // l sees the DJ leave; the state the DJ sends on its way back is lost.
    net.vanish('@l:x:L', '@d:x:D');
    net.members['@d:x:D']!.reconnects.add(null);
    await settle();
    net.reappear('@l:x:L', '@d:x:D');
    await settle();

    // Ticks keep coming, "the next state or tick repairs what was lost".
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await settle();
    expect(net.count('@d:x:D', '@l:x:L', 'tick'), greaterThan(2));
    expect(l.djIdentity, '@d:x:D',
        reason: 'l shows an empty booth while d plays; isVacant=${l.isVacant}');
  });

  test(
      'N5: with a long queue the new DJ unpauses before the old DJ has even '
      'received the handoff (both play)', () async {
    final net = Net(budget: 100000);
    late FakeEngine aEngine;
    final a = make(net.join('@a:x:A'),
        resolver: BigResolver(900), engine: () => aEngine = FakeEngine('A'));
    bool? oldStoppedWhenNewStarted;
    final b = make(net.join('@b:x:B'),
        engine: () => _SpyEngine('B', (paused) {
              if (!paused) oldStoppedWhenNewStarted ??= aEngine.shutDown;
            }));
    await settle();
    await a.becomeDj();
    a.addLinks('https://www.youtube.com/playlist?list=PLbig');
    await settle();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await settle();
    expect(b.queue.length, 899);

    // A few ms per packet, as publishData on a real data channel.
    net.packetDelay = const Duration(milliseconds: 8);
    a.passTo('@b:x:B');
    await Future<void>.delayed(const Duration(seconds: 3));
    await settle();

    expect(b.isDj, isTrue);
    expect(oldStoppedWhenNewStarted, isTrue,
        reason: "b's music started while a's was still playing");
  });

  // The guard is meant to keep a peer's state from pointing yt-dlp at a
  // machine; glibc (and Python's socket) read these as 127.0.0.1.
  for (final url in [
    'https://127.1/x',
    'https://0x7f.1/x',
    'https://127.0.0.1.nip.io/x',
  ]) {
    test('N6: a loopback address is never fetched: $url', () async {
      // Refused outright, or (a DNS name) refused once resolved; either way
      // yt-dlp never sees it.
      final host = Uri.parse(url).host;
      expect(
          !DjSongCache.isFetchable(url) ||
              !await DjSongCache.hostIsPublic(host),
          isTrue);
    });
  }
}

class _SpyEngine extends FakeEngine {
  final void Function(bool paused) onPaused;
  _SpyEngine(super.name, this.onPaused);

  @override
  void setPaused(bool paused) {
    onPaused(paused);
    super.setPaused(paused);
  }
}
