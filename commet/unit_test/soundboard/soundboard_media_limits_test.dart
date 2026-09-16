import 'dart:async';
import 'dart:typed_data';

import 'package:commet/client/components/soundboard/soundboard_media_limits.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('fetchCapped', () {
    Future<Uint8List> fetch(StreamController<List<int>> body,
            {int? contentLength, int statusCode = 200}) =>
        fetchCapped(
          MockClient.streaming((_, __) async => http.StreamedResponse(
              body.stream, statusCode,
              contentLength: contentLength)),
          http.Request('GET', Uri.parse('https://hs.example/media')),
          maxBytes: 1000,
        );

    test('returns a file within the limit', () async {
      final body = StreamController<List<int>>();
      final result = fetch(body);
      body
        ..add(List.filled(600, 1))
        ..add(List.filled(400, 2));
      await body.close();

      expect(await result, hasLength(1000));
    });

    test('stops downloading once a file goes over the limit', () async {
      var cancelled = false;
      final body = StreamController<List<int>>(onCancel: () {
        cancelled = true;
      });
      final result = fetch(body);
      body
        ..add(List.filled(600, 1))
        ..add(List.filled(600, 2));

      await expectLater(result, throwsA(isA<SoundboardMediaRejected>()));
      expect(cancelled, isTrue);
    });

    test('refuses a file declared over the limit without reading it', () async {
      // The body never arrives: reading it would hang the test.
      final body = StreamController<List<int>>();

      await expectLater(fetch(body, contentLength: 100 * 1024 * 1024),
          throwsA(isA<SoundboardMediaRejected>()));
    });

    test('fails on an error response', () async {
      final body = StreamController<List<int>>();
      unawaited(body.close());

      await expectLater(
          fetch(body, statusCode: 404), throwsA(isA<http.ClientException>()));
    });
  });

  group('SoundboardBufferCache', () {
    late SoundboardBufferCache<String> cache;
    late Map<String, int> loads;

    setUp(() {
      cache = SoundboardBufferCache(maxEntries: 2);
      loads = {};
    });

    Future<String> play(String key) => cache.get(key, () async {
          loads[key] = (loads[key] ?? 0) + 1;
          return 'decoded $key';
        });

    test('keeps the most recently played sounds', () async {
      await play('airhorn');
      await play('bruh');
      await play('airhorn');
      await play('horse'); // drops bruh, played least recently

      await play('airhorn');
      await play('bruh');

      expect(loads, {'airhorn': 1, 'bruh': 2, 'horse': 1});
    });

    test('a sound still loading is shared by every play', () async {
      final loading = Completer<String>();
      var started = 0;
      Future<String> load() {
        started++;
        return loading.future;
      }

      final first = cache.get('airhorn', load);
      final second = cache.get('airhorn', load);
      loading.complete('decoded airhorn');

      expect(await first, 'decoded airhorn');
      expect(await second, 'decoded airhorn');
      expect(started, 1);
    });

    test('a load that failed is tried again on the next play', () async {
      await expectLater(
          cache.get('airhorn', () async => throw Exception('offline')),
          throwsException);

      expect(await play('airhorn'), 'decoded airhorn');
    });

    test('a sound that can never play is not downloaded again', () async {
      await expectLater(
          cache.get('huge',
              () async => throw const SoundboardMediaRejected('too large')),
          throwsA(isA<SoundboardMediaRejected>()));

      await expectLater(play('huge'), throwsA(isA<SoundboardMediaRejected>()));
      expect(loads['huge'], isNull);
    });
  });
}
