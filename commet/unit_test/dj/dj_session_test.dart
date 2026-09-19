import 'dart:async';

import 'package:commet/client/components/dj/dj_engine.dart';
import 'package:commet/client/components/dj/dj_models.dart';
import 'package:commet/client/components/dj/dj_session.dart';
import 'package:test/test.dart';

import 'dj_fakes.dart';

const desktop = DjCaps(canDj: true, platform: 'linux');
const web = DjCaps(canDj: false, platform: 'web');

class Client {
  final DjSession session;
  final FakeDjTransport transport;
  final List<FakeEngine> engines;
  final List<DjNotice> notices = [];

  Client(this.session, this.transport, this.engines) {
    session.notices.listen(notices.add);
  }

  FakeEngine? get engine => engines.isEmpty ? null : engines.last;
}

Client connect(FakeCall call, String identity,
    {DjCaps caps = desktop,
    FakeResolver? resolver,
    Duration passTimeout = const Duration(seconds: 90),
    void Function(FakeEngine)? onEngine}) {
  final transport = call.join(identity);
  final engines = <FakeEngine>[];
  final session = DjSession(
    transport: transport,
    caps: caps,
    selfUserId: djUserIdOf(identity),
    engineFactory: caps.canDj
        ? () {
            final engine = FakeEngine(identity);
            onEngine?.call(engine);
            engines.add(engine);
            return engine;
          }
        : null,
    resolver: resolver ?? FakeResolver(),
    passTimeout: passTimeout,
    tickInterval: const Duration(milliseconds: 40),
    pollInterval: const Duration(milliseconds: 10),
  )..start();
  return Client(session, transport, engines);
}

void main() {
  late FakeCall call;
  final clients = <Client>[];

  Client join(String identity,
      {DjCaps caps = desktop,
      FakeResolver? resolver,
      Duration passTimeout = const Duration(seconds: 90),
      void Function(FakeEngine)? onEngine}) {
    final client = connect(call, identity,
        caps: caps,
        resolver: resolver,
        passTimeout: passTimeout,
        onEngine: onEngine);
    clients.add(client);
    return client;
  }

  setUp(() {
    call = FakeCall();
    clients.clear();
  });

  tearDown(() async {
    for (final c in clients) {
      await c.session.dispose();
    }
  });

  /// A DJ'ing, with [tracks] queued and the first one playing.
  Future<Client> djWith(String identity, List<String> links) async {
    final dj = join(identity);
    await settle();
    await dj.session.becomeDj();
    await settle();
    dj.session.addLinks(links.join('\n'));
    await settle();
    return dj;
  }

  group('claiming the booth', () {
    test('the claimant becomes the DJ everywhere', () async {
      final a = join('@a:x:DEV1');
      final b = join('@b:x:DEV2');
      await settle();

      await a.session.becomeDj();
      await settle();

      expect(a.session.isDj, isTrue);
      expect(a.engine!.started, isTrue);
      expect(b.session.djIdentity, '@a:x:DEV1');
      expect(b.session.djUserId, '@a:x');
      expect(b.session.isDjUser('@a:x'), isTrue);
    });

    test('songs added to an empty booth start playing, in pasted order',
        () async {
      final a = await djWith('@a:x:DEV1', [
        'https://youtu.be/aaaaaaaaaaa',
        'https://soundcloud.com/artist/song',
        'https://open.spotify.com/track/4cOdK2wGLETKBW3PvgPWqT',
      ]);
      final b = join('@b:x:DEV2');
      await settle();

      expect(a.session.current?.source, 'https://www.youtube.com/watch?v=aaaaaaaaaaa');
      expect(a.session.isPlaying, isTrue);
      expect(a.engine!.played.single.$1, a.session.current!.id);
      expect(b.session.current?.id, a.session.current!.id);
      expect(b.session.queue.map((t) => t.kind),
          [DjSource.soundcloud, DjSource.spotify]);
      expect(b.session.isPlaying, isTrue);
    });

    test('what fetching learned is announced (the title of a set entry)',
        () async {
      final a = await djWith('@a:x:DEV1', ['https://youtu.be/aaaaaaaaaaa']);
      expect(a.session.current!.title,
          startsWith('Fetched https://www.youtube.com/watch'));
    });

    test('two claims at once end with the smaller identity as DJ', () async {
      final a = join('@a:x:DEV1');
      final b = join('@b:x:DEV2');
      final c = join('@c:x:DEV3');
      await settle();

      final claims = [b.session.becomeDj(), a.session.becomeDj()];
      await Future.wait(claims);
      await settle();

      for (final client in [a, b, c]) {
        expect(client.session.djIdentity, '@a:x:DEV1',
            reason: client.transport.selfIdentity);
      }
      expect(a.session.isDj, isTrue);
      expect(b.session.isDj, isFalse);
      expect(b.engine!.shutDown, isTrue);
    });

    test('a web client cannot claim', () async {
      final w = join('@w:x:WEB', caps: web);
      await settle();
      await w.session.becomeDj();
      await settle();
      expect(w.session.djIdentity, isNull);
      expect(w.session.isDj, isFalse);
    });

    test('a newer epoch wins everywhere, so the room never has two DJs',
        () async {
      // Honest clients only claim an empty booth; whatever happens, every
      // client applies the same rule and they end up agreeing.
      final a = await djWith('@a:x:DEV1', ['https://youtu.be/aaaaaaaaaaa']);
      final b = join('@b:x:DEV2');
      final c = join('@c:x:DEV3');
      await settle();

      await c.transport.send({
        't': 'state',
        ...a.session.snapshot
            .copyWith(epoch: a.session.snapshot.epoch + 1, dj: '@c:x:DEV3')
            .toJson(),
      });
      await settle();

      expect(b.session.djIdentity, '@c:x:DEV3');
      expect(a.session.djIdentity, '@c:x:DEV3');
      expect(a.session.isDj, isFalse);
      expect(a.engine!.shutDown, isTrue);
    });

    test('a newcomer who claims without knowing the DJ steps down', () async {
      final a = await djWith('@a:x:DEV1', ['https://youtu.be/aaaaaaaaaaa']);
      // n hears nothing from the DJ at first: it believes the booth is
      // empty and claims epoch 1.
      final t = call.join('@n:x:N');
      t.deafTo.add('@a:x:DEV1');
      final n = DjSession(
        transport: t,
        caps: desktop,
        selfUserId: '@n:x',
        engineFactory: () => FakeEngine('@n:x:N'),
        resolver: FakeResolver(),
      )..start();
      await settle();
      expect(n.djIdentity, isNull);
      t.deafTo.clear();
      await n.becomeDj();
      await settle();

      expect(n.isDj, isFalse, reason: 'the DJ answered the stale claim');
      expect(n.djIdentity, '@a:x:DEV1');
      expect(a.session.isDj, isTrue);
      await n.dispose();
    });

    test('a listener that reconnects asks for the booth again', () async {
      final a = await djWith('@a:x:DEV1', ['https://youtu.be/aaaaaaaaaaa']);
      final b = join('@b:x:DEV2');
      await settle();
      // LiveKit made the DJ "leave" during b's reconnect.
      b.transport.receiveLeft('@a:x:DEV1');
      await settle();
      expect(b.session.djIdentity, isNull);
      b.transport.reconnects.add(null);
      await settle();
      expect(b.session.djIdentity, '@a:x:DEV1');
      expect(a.session.isDj, isTrue);
    });
  });

  group('requests and passing', () {
    test('a request shows for everyone and the DJ can pass to them',
        () async {
      final a = await djWith('@a:x:DEV1', [
        'https://youtu.be/aaaaaaaaaaa',
        'https://youtu.be/bbbbbbbbbbb',
        'https://youtu.be/ccccccccccc',
      ]);
      final b = join('@b:x:DEV2');
      final c = join('@c:x:DEV3');
      await settle();

      b.session.requestDj(true);
      await settle();
      expect(a.session.requests, ['@b:x:DEV2']);
      expect(c.session.hasRequestedUser('@b:x'), isTrue);

      a.engine!.advance(42000);
      final queueBefore = a.session.queue.map((t) => t.id).toList();
      final currentBefore = a.session.current!.id;

      a.session.passTo('@b:x:DEV2');
      await settle();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await settle();

      // b took over: same song, same queue, near 0:42, loaded paused for a
      // moment so the room never hears both DJs, then playing.
      expect(b.session.isDj, isTrue);
      expect(b.engine!.played.last.$1, currentBefore);
      expect(b.engine!.played.last.$2, inInclusiveRange(40000, 44500));
      expect(b.engine!.played.last.$3, isTrue);
      await Future<void>.delayed(
          DjSession.handoffLead + const Duration(milliseconds: 50));
      expect(b.engine!.isPaused, isFalse);
      for (final client in [a, b, c]) {
        expect(client.session.djIdentity, '@b:x:DEV2');
        expect(client.session.current!.id, currentBefore);
        expect(client.session.queue.map((t) => t.id), queueBefore);
        expect(client.session.isPlaying, isTrue);
        expect(client.session.requests, isEmpty);
        expect(client.session.passTarget, isNull);
      }
      // a stopped its own music.
      expect(a.session.isDj, isFalse);
      expect(a.engine!.shutDown, isTrue);
    });

    test('the DJ keeps playing while the target fetches the song', () async {
      final a = await djWith('@a:x:DEV1', ['https://youtu.be/aaaaaaaaaaa']);
      FakeEngine? bEngine;
      final b = join('@b:x:DEV2', onEngine: (e) {
        bEngine = e;
        e.gate = Completer<void>();
      });
      await settle();

      a.session.passTo('@b:x:DEV2');
      await settle();
      expect(b.session.isJoining, isTrue);
      expect(a.session.isDj, isTrue);
      expect(a.engine!.shutDown, isFalse);
      // Editing is locked while the booth changes hands.
      a.session.skip();
      expect(a.engine!.played.length, 1);

      bEngine!.gate!.complete();
      await settle();
      expect(b.session.isDj, isTrue);
      expect(a.engine!.shutDown, isTrue);
    });

    test('a paused booth is handed over paused', () async {
      final a = await djWith('@a:x:DEV1', ['https://youtu.be/aaaaaaaaaaa']);
      final b = join('@b:x:DEV2');
      await settle();
      a.session.setPaused(true);
      await settle();

      a.session.passTo('@b:x:DEV2');
      await settle();

      expect(b.session.isDj, isTrue);
      expect(b.engine!.played.last.$3, isTrue);
      expect(b.session.isPlaying, isFalse);
    });

    test('a failed takeover leaves the DJ in charge and tells them',
        () async {
      final a = await djWith('@a:x:DEV1', ['https://youtu.be/aaaaaaaaaaa']);
      final current = a.session.current!.id;
      final b = join('@b:x:DEV2', onEngine: (e) => e.failing.add(current));
      await settle();

      a.session.passTo('@b:x:DEV2');
      await settle();

      expect(a.session.isDj, isTrue);
      expect(a.session.passTarget, isNull);
      expect(a.notices.single.isError, isTrue);
      expect(b.session.isDj, isFalse);
      expect(b.engine!.shutDown, isTrue);
      expect(b.session.djIdentity, '@a:x:DEV1');
      // One attempt per pass, not one per state that still names b.
      expect(b.engines.length, 1);
    });

    test('passing to a web client is refused', () async {
      final a = await djWith('@a:x:DEV1', ['https://youtu.be/aaaaaaaaaaa']);
      final w = join('@w:x:WEB', caps: web);
      await settle();

      expect(a.session.capsOf('@w:x:WEB')?.canDj, isFalse);
      a.session.passTo('@w:x:WEB');
      await settle();
      expect(a.session.passTarget, isNull);
      expect(w.session.djIdentity, '@a:x:DEV1');
    });

    test('a web client cannot ask for the booth', () async {
      final a = await djWith('@a:x:DEV1', ['https://youtu.be/aaaaaaaaaaa']);
      final w = join('@w:x:WEB', caps: web);
      await settle();
      w.session.requestDj(true);
      await settle();
      expect(a.session.requests, isEmpty);
    });

    test('a pass nobody takes is called off', () async {
      final a = join('@a:x:DEV1', passTimeout: const Duration(milliseconds: 60));
      final b = join('@b:x:DEV2');
      await settle();
      await a.session.becomeDj();
      await settle();
      b.transport.drop.add('state'); // b never announces itself
      b.session.dispose(); // and never reacts
      clients.remove(b);
      await settle();
      // b still counts as present (it did not leave the call).
      a.session.passTo('@b:x:DEV2');
      expect(a.session.passTarget, '@b:x:DEV2');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(a.session.passTarget, isNull);
      expect(a.session.isDj, isTrue);
    });

    test('the DJ can call a pass off', () async {
      final a = await djWith('@a:x:DEV1', ['https://youtu.be/aaaaaaaaaaa']);
      FakeEngine? bEngine;
      final b = join('@b:x:DEV2', onEngine: (e) {
        bEngine = e;
        e.gate = Completer<void>();
      });
      await settle();
      a.session.passTo('@b:x:DEV2');
      await settle();
      a.session.cancelPass();
      await settle();
      bEngine!.gate!.complete();
      await settle();

      expect(a.session.isDj, isTrue);
      expect(b.session.isDj, isFalse);
      expect(bEngine!.shutDown, isTrue);
      expect(b.session.djIdentity, '@a:x:DEV1');
    });
  });

  group('the DJ leaving', () {
    test('keeps the queue, paused, and the next DJ carries on from it',
        () async {
      final a = await djWith('@a:x:DEV1', [
        'https://youtu.be/aaaaaaaaaaa',
        'https://youtu.be/bbbbbbbbbbb',
      ]);
      final b = join('@b:x:DEV2');
      await settle();
      a.engine!.advance(30000);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await settle();
      final current = a.session.current!.id;

      // a drops out of the call without a word.
      a.transport.drop.addAll(['state', 'tick']);
      call.leave('@a:x:DEV1');
      await settle();

      expect(b.session.djIdentity, isNull);
      expect(b.session.isVacant, isTrue);
      expect(b.session.current!.id, current);
      expect(b.session.queue.length, 1);
      expect(b.session.isPlaying, isFalse);

      await b.session.becomeDj();
      await settle();
      expect(b.session.isDj, isTrue);
      expect(b.engine!.played.single.$1, current);
      expect(b.engine!.played.single.$2, inInclusiveRange(29000, 32000));
      expect(b.engine!.played.single.$3, isTrue, reason: 'resumes paused');
    });

    test('stopping DJing hands the room an empty booth', () async {
      final a = await djWith('@a:x:DEV1', ['https://youtu.be/aaaaaaaaaaa']);
      final b = join('@b:x:DEV2');
      await settle();
      await a.session.stopDjing();
      await settle();
      expect(b.session.djIdentity, isNull);
      expect(b.session.current, isNotNull);
      expect(a.engine!.shutDown, isTrue);
    });

    test('a newcomer gets the booth from the DJ', () async {
      final a = await djWith('@a:x:DEV1', [
        'https://youtu.be/aaaaaaaaaaa',
        'https://youtu.be/bbbbbbbbbbb',
      ]);
      final late = join('@late:x:DEV9', caps: web);
      await settle();
      expect(late.session.djIdentity, '@a:x:DEV1');
      expect(late.session.queue.length, 1);
      expect(a.session.capsOf('@late:x:DEV9')?.platform, 'web');
      expect(late.session.capsOf('@a:x:DEV1')?.canDj, isTrue);
    });
  });

  group('the queue', () {
    test('moves, removes, play next and play now', () async {
      final resolver = FakeResolver(count: 4);
      final a = join('@a:x:DEV1', resolver: resolver);
      await settle();
      await a.session.becomeDj();
      a.session.addLinks('https://www.youtube.com/playlist?list=PL1');
      await settle();
      // track0 plays, track1..3 queued.
      expect(a.session.queue.map((t) => t.id), ['track1', 'track2', 'track3']);

      a.session.move(2, 0);
      expect(a.session.queue.map((t) => t.id), ['track3', 'track1', 'track2']);
      a.session.move(0, 3);
      expect(a.session.queue.map((t) => t.id), ['track1', 'track2', 'track3']);

      a.session.playNext('track3');
      expect(a.session.queue.map((t) => t.id), ['track3', 'track1', 'track2']);

      a.session.remove('track1');
      expect(a.session.queue.map((t) => t.id), ['track3', 'track2']);

      a.session.playNow('track2');
      await settle();
      expect(a.session.current!.id, 'track2');
      expect(a.session.queue.map((t) => t.id), ['track3']);
      expect(a.engine!.played.last.$1, 'track2');

      a.session.rename('track3', '  My edit ');
      expect(a.session.queue.single.title, 'My edit');
    });

    test('the next song starts when one ends, and the booth idles after the last',
        () async {
      final a = await djWith('@a:x:DEV1', [
        'https://youtu.be/aaaaaaaaaaa',
        'https://youtu.be/bbbbbbbbbbb',
      ]);
      final first = a.session.current!.id;
      a.engine!.finish();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      await settle();
      expect(a.session.current!.id, isNot(first));
      expect(a.session.queue, isEmpty);

      a.engine!.finish();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      await settle();
      expect(a.session.current, isNull);
      expect(a.session.isPlaying, isFalse);
    });

    test('a song that fails to play is skipped with a notice', () async {
      final a = join('@a:x:DEV1', onEngine: (e) => e.failing.add('track0'));
      await settle();
      await a.session.becomeDj();
      a.session.addLinks('https://youtu.be/aaaaaaaaaaa https://youtu.be/bbbbbbbbbbb');
      await settle();
      expect(a.session.current!.id, 'track1');
      expect(a.notices.single.message, contains("Couldn't play"));
    });

    test('pause and resume reach the engine and the room', () async {
      final a = await djWith('@a:x:DEV1', ['https://youtu.be/aaaaaaaaaaa']);
      final b = join('@b:x:DEV2');
      await settle();
      a.session.togglePause();
      await settle();
      expect(a.engine!.isPaused, isTrue);
      expect(b.session.isPlaying, isFalse);
      a.session.togglePause();
      await settle();
      expect(a.engine!.isPaused, isFalse);
      expect(b.session.isPlaying, isTrue);
    });

    test('a long queue reaches everyone in one piece', () async {
      final resolver = FakeResolver(count: 400);
      final a = join('@a:x:DEV1', resolver: resolver);
      final b = join('@b:x:DEV2');
      await settle();
      await a.session.becomeDj();
      a.session.addLinks('https://www.youtube.com/playlist?list=PLlong');
      await settle();
      expect(call.log.any((m) => m.$2['t'] == 'part'), isTrue);
      expect(b.session.queue.length, 399);
      expect(b.session.queue.last.id, a.session.queue.last.id);
    });

    test('listeners follow the position from ticks', () async {
      final a = await djWith('@a:x:DEV1', ['https://youtu.be/aaaaaaaaaaa']);
      final b = join('@b:x:DEV2');
      await settle();
      a.engine!.advance(60000);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await settle();
      expect(b.session.positionMs, inInclusiveRange(60000, 61000));
    });

    test('a link that cannot be resolved is reported, the others are added',
        () async {
      final resolver = FakeResolver()
        ..failing.add('https://www.youtube.com/watch?v=bbbbbbbbbbb');
      final a = join('@a:x:DEV1', resolver: resolver);
      await settle();
      await a.session.becomeDj();
      final found = a.session.addLinks(
          'https://youtu.be/aaaaaaaaaaa https://youtu.be/bbbbbbbbbbb https://youtu.be/ccccccccccc');
      expect(found, 3);
      expect(a.session.pendingAdds.length, 3);
      await settle();
      expect(a.session.pendingAdds, isEmpty);
      expect(a.notices.single.isError, isTrue);
      expect(a.session.current, isNotNull);
      expect(a.session.queue.length, 1);
    });
  });
}
