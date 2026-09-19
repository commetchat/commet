// Adversarial review of the DJ booth protocol. Every test here demonstrates a
// bug: it asserts the behaviour the design promises and fails today.
import 'dart:async';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:commet/client/components/dj/dj_engine.dart';
import 'package:commet/client/components/dj/dj_links.dart';
import 'package:commet/client/components/dj/dj_models.dart';
import 'package:commet/client/components/dj/dj_protocol.dart';
import 'package:commet/client/components/dj/dj_session.dart';
import 'package:test/test.dart';

import '../dj_fakes.dart';

const desktop = DjCaps(canDj: true, platform: 'linux');

/// A FakeEngine whose fetch of chosen tracks waits for a gate (the slow
/// part of playing a song).
class GatedEngine extends FakeEngine {
  final Map<String, Completer<void>> playGates = {};
  GatedEngine(super.name);

  @override
  Future<DjTrackInfo> prepare(DjTrack track) async {
    final gate = playGates[track.id];
    if (gate != null) await gate.future;
    return super.prepare(track);
  }
}

/// Resolves to [count] tracks with titles that do not compress well.
class NoisyResolver extends FakeResolver {
  NoisyResolver(int count) : super(count: count);

  @override
  Future<List<DjTrack>> resolve(DjLink link, {required String addedBy}) async {
    var seed = 12345;
    String noise() => List.generate(40, (_) {
          seed = (seed * 1103515245 + 12345) & 0x7fffffff;
          return String.fromCharCode(33 + seed % 90);
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

/// A network where each observer has its own view of who is present, so a
/// participant can vanish for one observer (a LiveKit full reconnect).
class Net {
  final Map<String, NetTransport> members = {};

  NetTransport join(String identity) {
    final t = NetTransport(this, identity);
    for (final other in members.values) {
      other.joined.add(identity);
    }
    members[identity] = t;
    return t;
  }

  /// [observer] sees [identity] leave; messages between them are lost.
  void vanish(String observer, String identity) {
    members[observer]!.hidden.add(identity);
    members[observer]!.left.add(identity);
  }

  /// [identity] is back for [observer]; [announce] says whether the SDK
  /// emits ParticipantConnected (it does not for join-response participants).
  void reappear(String observer, String identity, {bool announce = true}) {
    members[observer]!.hidden.remove(identity);
    if (announce) members[observer]!.joined.add(identity);
  }
}

class NetTransport implements DjTransport {
  final Net net;
  @override
  final String selfIdentity;
  final Set<String> hidden = {};
  final StreamController<DjIncoming> incomingC = StreamController.broadcast();
  final StreamController<String> joined = StreamController.broadcast();
  final StreamController<String> left = StreamController.broadcast();
  final StreamController<void> reconnects = StreamController.broadcast();

  NetTransport(this.net, this.selfIdentity);

  @override
  Stream<void> get reconnected => reconnects.stream;

  @override
  Future<void> send(Map<String, Object?> message, {List<String>? to}) async {
    final wire = jsonEncode(message);
    for (final m in net.members.values.toList()) {
      if (m.selfIdentity == selfIdentity) continue;
      if (to != null && !to.contains(m.selfIdentity)) continue;
      if (hidden.contains(m.selfIdentity) || m.hidden.contains(selfIdentity)) {
        continue;
      }
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

void main() {
  final sessions = <DjSession>[];

  DjSession make(DjTransport t,
      {DjPlaybackEngine Function()? engine,
      FakeResolver? resolver,
      Duration passTimeout = const Duration(seconds: 90)}) {
    final s = DjSession(
      transport: t,
      caps: desktop,
      selfUserId: djUserIdOf(t.selfIdentity),
      engineFactory: engine ?? () => FakeEngine(t.selfIdentity),
      resolver: resolver ?? FakeResolver(),
      passTimeout: passTimeout,
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

  test('R1: DJ cancels a pass while the target is in engine.play -> two DJs',
      () async {
    final call = FakeCall();
    final a = make(call.join('@a:x:A'));
    final gate = Completer<void>();
    final b = make(call.join('@b:x:B'), engine: () {
      final e = GatedEngine('@b:x:B');
      e.playGates['track0'] = gate;
      return e;
    });
    await settle();
    await a.becomeDj();
    a.addLinks('https://youtu.be/aaaaaaaaaaa');
    await settle();
    expect(a.current?.id, 'track0');

    a.passTo('@b:x:B');
    await settle();
    // b fetched the song, bumped its own epoch locally and is inside play().
    expect(b.isJoining, isTrue);

    // The DJ changes its mind (or the 90 s pass timeout fires) now.
    a.cancelPass();
    await settle();
    gate.complete();
    await settle();

    expect(a.isDj && b.isDj, isFalse,
        reason: 'a.isDj=${a.isDj} b.isDj=${b.isDj} '
            'a.dj=${a.djIdentity} b.dj=${b.djIdentity}');
  });

  test('R2: newcomer claims a released booth with a stale epoch', () async {
    final call = FakeCall();
    final a = make(call.join('@a:x:A'));
    final b = make(call.join('@b:x:B'));
    await settle();
    await a.becomeDj();
    a.addLinks('https://youtu.be/aaaaaaaaaaa https://youtu.be/bbbbbbbbbbb');
    await settle();
    await a.stopDjing();
    await settle();
    expect(b.snapshot.epoch, 2);
    expect(b.current, isNotNull);

    final n = make(call.join('@n:x:N'));
    await settle();
    // Whoever knows the empty booth tells the newcomer about it.
    expect(n.snapshot.epoch, 2);
    expect(n.current, isNotNull, reason: 'the kept queue reaches n');

    await n.becomeDj(); // epoch 1 < 2
    await settle();
    final nThinksDj = n.isDj;
    final bSeesN = b.djIdentity == '@n:x:N';

    await b.becomeDj(); // b: vacant from its view, epoch 3
    await settle();
    expect(n.isDj && b.isDj, isFalse,
        reason: 'n thinks DJ=$nThinksDj, b saw n=$bSeesN; now both DJ');
  });

  test('R3: DJ briefly invisible (full reconnect) ignores the claim made then',
      () async {
    final net = Net();
    final a = make(net.join('@a:x:A'));
    final b = make(net.join('@b:x:B'));
    await settle();
    await a.becomeDj();
    a.addLinks('https://youtu.be/aaaaaaaaaaa');
    await settle();

    // a reconnects: b sees it leave and the booth vacant.
    net.vanish('@b:x:B', '@a:x:A');
    await settle();
    expect(b.isVacant, isTrue);
    net.reappear('@b:x:B', '@a:x:A');
    await b.becomeDj(); // b claims epoch 2, a hears it
    await settle();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await settle();

    expect(a.isDj && b.isDj, isFalse,
        reason: 'a.dj=${a.djIdentity} b.dj=${b.djIdentity}');
  });

  test('R4: DJ full reconnect drops caps, passTo silently does nothing',
      () async {
    final net = Net();
    final a = make(net.join('@a:x:A'));
    make(net.join('@b:x:B'));
    await settle();
    await a.becomeDj();
    await settle();
    expect(a.capsOf('@b:x:B')?.canDj, isTrue);

    // a's room emits ParticipantDisconnected for everyone on a full restart,
    // then re-creates them from the join response without ParticipantConnected.
    net.vanish('@a:x:A', '@b:x:B');
    net.reappear('@a:x:A', '@b:x:B', announce: false);
    await settle();

    a.passTo('@b:x:B');
    expect(a.passTarget, '@b:x:B');
  });

  test('R5: re-passing to a target that failed once in this epoch is ignored',
      () async {
    final call = FakeCall();
    final a = make(call.join('@a:x:A'));
    var made = 0;
    final b = make(call.join('@b:x:B'), engine: () {
      final e = FakeEngine('@b:x:B');
      if (made++ == 0) e.failing.add('track0'); // first attempt fails
      return e;
    });
    await settle();
    await a.becomeDj();
    a.addLinks('https://youtu.be/aaaaaaaaaaa');
    await settle();

    a.passTo('@b:x:B');
    await settle();
    expect(a.passTarget, isNull); // pfail arrived
    expect(b.isDj, isFalse);

    a.passTo('@b:x:B'); // try again, network is fine now
    await settle();
    expect(b.isDj, isTrue,
        reason: 'b made $made engines; a.passTarget=${a.passTarget}');
  });

  test('R6: a multi-part state overtaken by a single-packet state wins',
      () async {
    final call = FakeCall();
    final a = make(call.join('@a:x:A'), resolver: NoisyResolver(900));
    final b = make(call.join('@b:x:B'));
    await settle();
    await a.becomeDj();
    a.addLinks('https://www.youtube.com/playlist?list=PLlong');
    await settle();
    final parts = DjProtocol.split({'t': 'state', ...a.snapshot.toJson()})!;
    expect(parts.length, greaterThan(1));
    expect(b.queue.length, 899);

    a.shuffle();
    a.clearQueue();
    await settle();
    expect(a.queue, isEmpty);
    expect(b.queue.length, 0, reason: 'b applied the older shuffled state');
  });

  test('R7: skip during a slow load: the superseded load lands last', () async {
    final call = FakeCall();
    final gate = Completer<void>();
    late GatedEngine engine;
    final a = make(call.join('@a:x:A'),
        resolver: FakeResolver(count: 2),
        engine: () => engine = GatedEngine('@a:x:A')
          ..playGates['track0'] = gate);
    await settle();
    await a.becomeDj();
    a.addLinks('https://www.youtube.com/playlist?list=PL2');
    await settle();
    expect(a.current?.id, 'track0');
    expect(a.isBuffering, isTrue);

    a.skip();
    await settle();
    expect(a.current?.id, 'track1');
    expect(engine.loadedId, 'track1');

    gate.complete(); // track0's download finishes late
    await settle();
    expect(engine.loadedId, a.current?.id,
        reason: 'engine plays ${engine.loadedId}, booth shows ${a.current?.id}');
  });

  test('R8: part assembler inflates without a size limit (gzip bomb)', () {
    final json = '{"t":"x","pad":"${'0' * (40 * 1024 * 1024)}"}';
    final packed =
        base64.encode(GZipEncoder().encode(utf8.encode(json))!);
    final n = (packed.length / DjProtocol.partChars).ceil();
    expect(n, lessThanOrEqualTo(DjProtocol.maxParts));
    final assembler = DjPartAssembler();
    Map<String, Object?>? whole;
    for (var i = 0; i < n; i++) {
      whole = assembler.add('@evil:x:E', {
        't': 'part',
        'id': 'z',
        'i': i,
        'n': n,
        'd': packed.substring(i * DjProtocol.partChars,
            (i + 1) * DjProtocol.partChars > packed.length
                ? packed.length
                : (i + 1) * DjProtocol.partChars),
      });
    }
    expect(whole, isNull,
        reason: '$n parts (${packed.length} chars) inflated to 40 MB');
  });

  test('R9a: DjSnapshot.fromJson throws on a non-string kind', () {
    expect(
        () => DjSnapshot.fromJson({
              'e': 1,
              's': 1,
              'q': [
                {'i': 'x', 'u': 'y', 't': 'z', 'k': 5}
              ]
            }),
        returnsNormally);
  });

  test('R9b: DjSnapshot.fromJson throws on an epoch of 1e999', () {
    final json = jsonDecode('{"t":"state","e":1e999,"s":0}');
    expect(() => DjSnapshot.fromJson(json), returnsNormally);
  });

  test('R9c: DjLinks.parseAll on malformed percent-encoding', () {
    expect(() => DjLinks.parseAll('https://www.youtube.com/watch?v=%zz'),
        returnsNormally);
    expect(() => DjLinks.parseAll('https://example.com/a?b=%E0%A4%A'),
        returnsNormally);
  });
}
