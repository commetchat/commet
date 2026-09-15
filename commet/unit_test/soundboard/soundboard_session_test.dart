import 'dart:io';

import 'package:commet/client/components/soundboard/soundboard_catalog.dart';
import 'package:commet/client/components/soundboard/soundboard_engine.dart';
import 'package:commet/client/components/soundboard/soundboard_import_service.dart';
import 'package:commet/client/components/soundboard/soundboard_session.dart';
import 'package:commet/client/components/soundboard/soundboard_sound.dart';
import 'package:commet/client/components/soundboard/soundboard_transport.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class FakePlayer implements SoundboardPlayer {
  final List<String> started = [];
  final Set<String> playing = {};
  @override
  Future<void> start(String soundId) async {
    started.add(soundId);
    playing.add(soundId);
  }

  @override
  Future<void> stop(String soundId) async {
    playing.remove(soundId);
  }

  @override
  Future<void> stopAll() async => playing.clear();
  @override
  Future<void> setVolumeFor(String soundId, double volume) async {}
  @override
  bool isPlaying(String soundId) => playing.contains(soundId);
}

SoundboardSound _s(String id) => SoundboardSound(
      soundId: id,
      name: 'S $id',
      emoji: '🔊',
      mediaUri: 'mxc://h/$id',
      mimeType: 'audio/mpeg',
      durationMs: 1500,
      normalizedGain: 1.0,
    );

http.Response _html(String body, [int code = 200]) =>
    http.Response(body, code, headers: {'content-type': 'text/html'});

http.Response _audio(List<int> bytes, String ct) =>
    http.Response.bytes(bytes, 200, headers: {'content-type': ct});

void main() {
  group('SoundboardImportService', () {
    test('rejects non-allowlisted page URL without network', () async {
      var called = false;
      final svc = SoundboardImportService(fetcher: (_) async {
        called = true;
        return _html('');
      });
      await expectLater(
          svc.importFromPageUrl('https://evil.com/x'), throwsA(anything));
      expect(called, isFalse);
    });

    test('resolves play() hook and validates audio bytes', () async {
      final svc = SoundboardImportService(fetcher: (uri) async {
        if (uri.path.contains('instant')) {
          return _html(
              '<a onclick="play(\'/media/sounds/ok.mp3\')">x</a>');
        }
        return _audio(List.filled(5000, 1), 'audio/mpeg');
      });
      final out = await svc.importFromPageUrl(
          'https://www.myinstants.com/en/instant/ok-1/');
      expect(out.mimeType, 'audio/mpeg');
      expect(out.bytes.length, 5000);
    });

    test('rejects missing audio on page', () async {
      final svc = SoundboardImportService(
          fetcher: (_) async => _html('<html>nothing</html>'));
      await expectLater(
          svc.importFromPageUrl(
              'https://www.myinstants.com/en/instant/empty-1/'),
          throwsA(anything));
    });

    test('rejects non-audio content', () async {
      final svc = SoundboardImportService(fetcher: (uri) async {
        if (uri.path.contains('instant')) {
          return _html('<a onclick="play(\'/media/sounds/x.mp3\')">x</a>');
        }
        return _audio([1, 2, 3], 'text/html');
      });
      await expectLater(
          svc.importFromPageUrl(
              'https://www.myinstants.com/en/instant/x-1/'),
          throwsA(anything));
    });

    test('rejects oversized file', () async {
      final svc = SoundboardImportService(fetcher: (uri) async {
        if (uri.path.contains('instant')) {
          return _html('<a onclick="play(\'/media/sounds/big.mp3\')">x</a>');
        }
        return _audio(List.filled(2 * 1024 * 1024, 1), 'audio/mpeg');
      });
      await expectLater(
          svc.importFromPageUrl(
              'https://www.myinstants.com/en/instant/big-1/'),
          throwsA(anything));
    });

    test('propagates network failure discretely', () async {
      final svc = SoundboardImportService(fetcher: (_) async {
        throw Exception('offline');
      });
      await expectLater(
          svc.importFromPageUrl(
              'https://www.myinstants.com/en/instant/x-1/'),
          throwsA(anything));
    });

    test('DNS failure surfaces an actionable message', () async {
      final svc = SoundboardImportService(fetcher: (_) async {
        throw SocketException(
            'Failed host lookup: www.myinstants.com',
            address: InternetAddress('93.184.216.34'));
      });
      await expectLater(
          svc.importFromPageUrl(
              'https://www.myinstants.com/en/instant/x-1/'),
          throwsA(predicate(
              (e) => e.toString().contains('internet connection'))));
    });

    test('bot-protection (403) surfaces a specific error', () async {
      final svc = SoundboardImportService(
          fetcher: (_) async => _html('blocked', 403));
      await expectLater(
          svc.importFromPageUrl(
              'https://www.myinstants.com/pt/instant/faaah-63455/'),
          throwsA(predicate((e) =>
              e.toString().contains('bot protection'))));
    });

    test('direct .mp3 URL skips page parsing', () async {
      var pageFetched = false;
      final svc = SoundboardImportService(fetcher: (uri) async {
        if (uri.path.contains('instant')) pageFetched = true;
        return _audio(List.filled(5000, 1), 'audio/mpeg');
      });
      final out = await svc.importFromPageUrl(
          'https://www.myinstants.com/media/sounds/faaah.mp3');
      expect(pageFetched, isFalse);
      expect(out.bytes.length, 5000);
    });
  });

  group('SoundboardSession integration', () {
    test('two users firing rapidly: both sounds land on both engines',
        () async {
      InMemorySoundboardTransport.resetAll();
      final catalogA =
          InMemorySoundboardCatalog([_s('airhorn'), _s('risada')]);
      final catalogB =
          InMemorySoundboardCatalog([_s('airhorn'), _s('risada')]);
      final ea = SoundboardEngine(player: FakePlayer(), nowMs: () => 1000);
      final eb = SoundboardEngine(player: FakePlayer(), nowMs: () => 1010);
      final ta = InMemorySoundboardTransport('@a:x');
      final tb = InMemorySoundboardTransport('@b:x');
      final sa = SoundboardSession(
        catalog: catalogA,
        engine: ea,
        transport: ta,
        selfUserId: '@a:x',
        durationOf: (_) => 1500,
      );
      final sb = SoundboardSession(
        catalog: catalogB,
        engine: eb,
        transport: tb,
        selfUserId: '@b:x',
        durationOf: (_) => 1500,
      );
      await sa.init();
      await sb.init();

      await sa.trigger('airhorn');
      await sb.trigger('risada');
      await Future.delayed(const Duration(milliseconds: 50));

      // Polyphony: each engine holds BOTH sounds (different ids coexist).
      expect(ea.active.keys.toSet(), {'airhorn', 'risada'});
      expect(eb.active.keys.toSet(), {'airhorn', 'risada'});
      // Attribution: latest author per sound is whoever sent it.
      expect(ea.active['airhorn']!.senderId, '@a:x');
      expect(ea.active['risada']!.senderId, '@b:x');

      await sa.dispose();
      await sb.dispose();
      InMemorySoundboardTransport.resetAll();
    });

    test('unknown soundId from remote is ignored safely', () async {
      InMemorySoundboardTransport.resetAll();
      final catalog = InMemorySoundboardCatalog([_s('known')]);
      final engine = SoundboardEngine(player: FakePlayer(), nowMs: () => 1);
      final t = InMemorySoundboardTransport('@a:x');
      final s = SoundboardSession(
        catalog: catalog,
        engine: engine,
        transport: t,
        selfUserId: '@a:x',
      );
      await s.init();
      // Simulate remote ghost event (removed sound) — must not throw/play.
      final peer = InMemorySoundboardTransport('@ghost:x');
      final ghostEngine =
          SoundboardEngine(player: FakePlayer(), nowMs: () => 1);
      final ghostEvent = ghostEngine.localTrigger(
          soundId: 'deleted-sound', senderId: '@ghost:x', eventId: 'g1');
      await peer.send(ghostEvent);
      await Future.delayed(const Duration(milliseconds: 20));
      expect(engine.active.containsKey('deleted-sound'), isFalse);
      await s.dispose();
      await peer.dispose();
      InMemorySoundboardTransport.resetAll();
    });

    test('volume is per-recipient: A quiet, B loud', () async {
      final pa = FakePlayer();
      final pb = FakePlayer();
      final ea = SoundboardEngine(player: pa, nowMs: () => 1);
      final eb = SoundboardEngine(player: pb, nowMs: () => 1);
      ea.setVolume(0.0); // Alice mutes locally
      eb.setVolume(1.0); // Bob full
      ea.localTrigger(soundId: 'x', senderId: '@a:x', eventId: 'e1');
      eb.localTrigger(soundId: 'x', senderId: '@b:x', eventId: 'e2');
      // Volumes stored per engine/player — sender never dictates remote.
      expect(ea.userVolume, 0.0);
      expect(eb.userVolume, 1.0);
    });
  });
}
