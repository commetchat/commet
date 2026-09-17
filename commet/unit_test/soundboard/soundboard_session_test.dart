import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:commet/client/components/soundboard/myinstants_resolver.dart';
import 'package:commet/client/components/soundboard/soundboard_catalog.dart';
import 'package:commet/client/components/soundboard/soundboard_constraints.dart';
import 'package:commet/client/components/soundboard/soundboard_emoji.dart';
import 'package:commet/client/components/soundboard/soundboard_engine.dart';
import 'package:commet/client/components/soundboard/soundboard_import_service.dart';
import 'package:commet/client/components/soundboard/soundboard_normalizer.dart';
import 'package:commet/client/components/soundboard/soundboard_session.dart';
import 'package:commet/client/components/soundboard/soundboard_sound.dart';
import 'package:commet/client/components/soundboard/soundboard_transport.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'mp3_fixtures.dart';

class FakePlayer implements SoundboardPlayer {
  final List<String> started = [];
  final Set<String> playing = {};
  @override
  Future<void> start(String instanceId, String soundId) async {
    started.add(soundId);
    playing.add(instanceId);
  }

  @override
  Future<void> stop(String instanceId) async {
    playing.remove(instanceId);
  }

  @override
  Future<void> stopAll() async => playing.clear();
  @override
  Future<void> setVolumeFor(String instanceId, double volume) async {}
  @override
  bool isPlaying(String instanceId) => playing.contains(instanceId);
}

SoundboardSound _s(String id) => SoundboardSound(
      soundId: id,
      name: 'S $id',
      emoji: const SoundboardEmoji.unicode('🔊'),
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
          return _html('<a onclick="play(\'/media/sounds/ok.mp3\')">x</a>');
        }
        return _audio(List.filled(5000, 1), 'audio/mpeg');
      });
      final out = await svc
          .importFromPageUrl('https://www.myinstants.com/en/instant/ok-1/');
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
          svc.importFromPageUrl('https://www.myinstants.com/en/instant/x-1/'),
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
          svc.importFromPageUrl('https://www.myinstants.com/en/instant/big-1/'),
          throwsA(anything));
    });

    test('propagates network failure discretely', () async {
      final svc = SoundboardImportService(fetcher: (_) async {
        throw Exception('offline');
      });
      await expectLater(
          svc.importFromPageUrl('https://www.myinstants.com/en/instant/x-1/'),
          throwsA(anything));
    });

    test('DNS failure surfaces an actionable message', () async {
      final svc = SoundboardImportService(fetcher: (_) async {
        throw SocketException('Failed host lookup: www.myinstants.com',
            address: InternetAddress('93.184.216.34'));
      });
      await expectLater(
          svc.importFromPageUrl('https://www.myinstants.com/en/instant/x-1/'),
          throwsA(
              predicate((e) => e.toString().contains('internet connection'))));
    });

    test('bot-protection (403) surfaces a specific error', () async {
      final svc =
          SoundboardImportService(fetcher: (_) async => _html('blocked', 403));
      await expectLater(
          svc.importFromPageUrl(
              'https://www.myinstants.com/pt/instant/faaah-63455/'),
          throwsA(isA<MyInstantsRequestError>().having(
              (e) => e.message, 'message', contains('bot protection'))));
    });

    test('connection errors wrapped by IOClient are actionable', () async {
      final svc = SoundboardImportService(
          fetcher: (uri) async => throw http.ClientException(
              'Connection closed before full header was received', uri));
      await expectLater(
          svc.importFromPageUrl('https://www.myinstants.com/en/instant/x-1/'),
          throwsA(isA<MyInstantsRequestError>().having((e) => e.message,
              'message', contains('Connection closed before full header'))));
    });

    test('duration comes from MP3 frames, not file size', () async {
      // 20 s at 32 kbps is ~80 KB, which the old 128 kbps guess let through.
      final svc = SoundboardImportService(
          fetcher: (_) async =>
              _audio(mpeg1Frames(766, kbps: 32), 'audio/mpeg'));
      await expectLater(
          svc.importFromPageUrl(
              'https://www.myinstants.com/media/sounds/long.mp3'),
          throwsA(isA<MyInstantsValidationError>().having((e) => e.message,
              'message', 'Audio too long (20.0 s, max 15 s)')));
    });

    test('cover art does not push a short clip over the limit', () async {
      // 14.5 s at 320 kbps plus 300 KB of cover art: 55 s by the old guess.
      final bytes = [...id3v2(300000), ...mpeg1Frames(555, kbps: 320)];
      final svc = SoundboardImportService(
          fetcher: (_) async => _audio(bytes, 'audio/mpeg'));
      final out = await svc.importFromPageUrl(
          'https://www.myinstants.com/media/sounds/short.mp3');
      expect(out.durationMs, framesToMs(555));
    });

    test('logs the parsed input and every request', () async {
      final lines = <String>[];
      final svc = SoundboardImportService(
        log: lines.add,
        fetcher: (uri) async {
          if (uri.path.contains('instant')) {
            return _html('<a onclick="play(\'/media/sounds/ok.mp3\')">x</a>');
          }
          return _audio(mpeg1Frames(40), 'audio/mpeg');
        },
      );
      await svc.importFromPageUrl(
          '[ok](https://www.myinstants.com/en/instant/ok-1/)');
      expect(
          lines.first,
          'input "[ok](https://www.myinstants.com/en/instant/ok-1/)" -> '
          'https://www.myinstants.com/en/instant/ok-1/ '
          '(scheme=https host=www.myinstants.com path=/en/instant/ok-1/)');
      expect(
          lines,
          containsAllInOrder([
            'GET https://www.myinstants.com/en/instant/ok-1/',
            'GET https://www.myinstants.com/media/sounds/ok.mp3',
            'duration: ${framesToMs(40)} ms (audio/mpeg)',
          ]));
    });

    group('loudness', () {
      // The -30 LUFS fixture stands in for what the platform decoder
      // returns for an MP3.
      final quiet = SoundboardNormalizer.decodeWav(
          File('unit_test/soundboard/fixtures/noise_-30lufs.wav')
              .readAsBytesSync())!;

      test('an MP3 is measured through the platform decoder', () async {
        final lines = <String>[];
        String? decodedMime;
        final svc = SoundboardImportService(
          log: lines.add,
          fetcher: (_) async => _audio(mpeg1Frames(40), 'audio/mpeg'),
          decoder: (bytes, mime) async {
            decodedMime = mime;
            return quiet;
          },
        );
        final out = await svc
            .importFromPageUrl('https://www.myinstants.com/media/sounds/q.mp3');
        expect(decodedMime, 'audio/mpeg');
        expect(out.loudnessMeasured, isTrue);
        // -30 LUFS needs +14 dB to reach -16.
        expect(20 * math.log(out.normalizedGain) / math.ln10, closeTo(14, 1));
        expect(lines, contains(startsWith('loudness: measured=true lufs=-30')));
      });

      test('an undecodable file is kept at unity gain and logged', () async {
        final lines = <String>[];
        final svc = SoundboardImportService(
          log: lines.add,
          fetcher: (_) async => _audio(mpeg1Frames(40), 'audio/mpeg'),
          decoder: (bytes, mime) async => null,
        );
        final out = await svc
            .importFromPageUrl('https://www.myinstants.com/media/sounds/q.mp3');
        expect(out.loudnessMeasured, isFalse);
        expect(out.normalizedGain, 1.0);
        expect(lines, contains(startsWith('loudness: measured=false')));
      });

      test('a WAV is measured without the platform decoder', () async {
        final wav = File('unit_test/soundboard/fixtures/noise_-6lufs.wav')
            .readAsBytesSync();
        final svc = SoundboardImportService(
          fetcher: (_) async => _audio(wav, 'audio/wav'),
          decoder: (bytes, mime) => fail('WAV must not need a decoder'),
        );
        final out = await svc
            .importFromPageUrl('https://www.myinstants.com/media/sounds/l.wav');
        expect(out.loudnessMeasured, isTrue);
        expect(out.durationMs, 1500);
        expect(20 * math.log(out.normalizedGain) / math.ln10, closeTo(-10, 1));
      });

      test('duration of formats without a frame parser comes from PCM',
          () async {
        final svc = SoundboardImportService(
          fetcher: (_) async => _audio([1, 2, 3, 4], 'audio/ogg'),
          decoder: (bytes, mime) async => PcmAudio(
              sampleRate: 1000,
              channels: [Float32List(16000)..fillRange(0, 16000, 0.1)]),
        );
        await expectLater(
            svc.importFromPageUrl(
                'https://www.myinstants.com/media/sounds/long.ogg'),
            throwsA(isA<MyInstantsValidationError>().having((e) => e.message,
                'message', 'Audio too long (16 s, max 15 s)')));
      });
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

  group('fetchFromMyInstants', () {
    final page =
        Uri.parse('https://www.myinstants.com/pt/instant/faaah-63455/');

    test('does not claim to be a browser', () async {
      // Cloudflare answers 403 to dart:io requests with a browser
      // User-Agent; Dart's default one gets through.
      late http.BaseRequest seen;
      final client = MockClient((request) async {
        seen = request;
        return http.Response('page', 200);
      });
      await fetchFromMyInstants(page, client: client);
      expect(seen.headers.keys.map((k) => k.toLowerCase()),
          isNot(anyOf(contains('user-agent'), contains('sec-fetch-mode'))));
    });

    test('follows redirects that stay on MyInstants', () async {
      final visited = <String>[];
      final client = MockClient((request) async {
        visited.add(request.url.toString());
        expect(request.followRedirects, isFalse);
        return switch (request.url.toString()) {
          'http://myinstants.com/instant/faaah-63455' => http.Response('', 301,
                headers: {
                  'location': 'https://www.myinstants.com/instant/faaah-63455'
                }),
          'https://www.myinstants.com/instant/faaah-63455' => http.Response(
              '', 302,
              headers: {'location': '/en/instant/faaah-63455/'}),
          _ => http.Response('page', 200),
        };
      });
      final res = await fetchFromMyInstants(
          Uri.parse('http://myinstants.com/instant/faaah-63455'),
          client: client);
      expect(res.body, 'page');
      expect(visited, [
        'http://myinstants.com/instant/faaah-63455',
        'https://www.myinstants.com/instant/faaah-63455',
        'https://www.myinstants.com/en/instant/faaah-63455/',
      ]);
    });

    test('refuses a redirect to another site', () async {
      final client = MockClient((_) async => http.Response('', 302,
          headers: {'location': 'https://myinstants.com.evil.org/x.mp3'}));
      await expectLater(fetchFromMyInstants(page, client: client),
          throwsA(isA<MyInstantsRequestError>()));
    });

    test('gives up after the redirect limit', () async {
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response('', 302, headers: {'location': '/loop/$requests'});
      });
      await expectLater(fetchFromMyInstants(page, client: client),
          throwsA(isA<MyInstantsRequestError>()));
      expect(requests, SoundboardConstraints.maxRedirects + 1);
    });
  });

  group('SoundboardSession integration', () {
    test('two users firing rapidly: both sounds land on both engines',
        () async {
      InMemorySoundboardTransport.resetAll();
      final catalogA = InMemorySoundboardCatalog([_s('airhorn'), _s('risada')]);
      final catalogB = InMemorySoundboardCatalog([_s('airhorn'), _s('risada')]);
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
      Map<String, String> senderBySound(SoundboardEngine e) => {
            for (final a in e.active.values) a.soundId: a.senderId,
          };
      // Attribution: each activation belongs to whoever sent it.
      expect(senderBySound(ea), {'airhorn': '@a:x', 'risada': '@b:x'});
      expect(senderBySound(eb), {'airhorn': '@a:x', 'risada': '@b:x'});

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
      expect(engine.active.values.map((a) => a.soundId),
          isNot(contains('deleted-sound')));
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
