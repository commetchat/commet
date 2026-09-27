import 'package:commet/client/components/dj/dj_links.dart';
import 'package:commet/client/components/dj/dj_models.dart';
import 'package:commet/client/components/dj/dj_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('DjProtocol', () {
    test('small messages go whole', () {
      final message = {'t': 'tick', 'pos': 1};
      expect(DjProtocol.split(message), [message]);
    });

    test('large messages are split and rebuilt, in any order', () {
      final snapshot = DjSnapshot(epoch: 3, seq: 9, dj: '@a:x:D', queue: [
        for (var i = 0; i < 900; i++)
          DjTrack(
              id: 'id$i',
              source: 'ext:org.example.music:'
                  'https://music.example/${'$i'.padLeft(11, 'x')}',
              kind: 'Example',
              // Long enough to need many parts.
              title: 'Title ${i * 7919 % 10007} ${i.toRadixString(36)}',
              addedBy: '@a:x'),
      ]);
      final message = {'t': 'state', ...snapshot.toJson()};
      final parts = DjProtocol.split(message)!;
      expect(parts.length, greaterThan(1));
      for (final part in parts) {
        expect(DjProtocol.encodePacket(part).length,
            lessThanOrEqualTo(DjProtocol.maxPacketBytes));
      }

      final assembler = DjPartAssembler();
      Map<String, Object?>? whole;
      for (final part in parts.reversed) {
        final decoded = DjProtocol.decodePacket(DjProtocol.encodePacket(part))!;
        whole = assembler.add('@a:x:D', decoded) ?? whole;
      }
      final rebuilt = DjSnapshot.fromJson(whole)!;
      expect(rebuilt.queue.length, 900);
      expect(rebuilt.queue[823], snapshot.queue[823]);
      expect(rebuilt.dj, '@a:x:D');
    });

    test('parts from different senders do not mix', () {
      final assembler = DjPartAssembler();
      final part = {'t': 'part', 'id': 'x', 'i': 0, 'n': 2, 'd': 'AAAA'};
      expect(assembler.add('@a', part), isNull);
      expect(assembler.add('@b', {...part, 'i': 1}), isNull);
    });

    test('nonsense parts are dropped', () {
      final assembler = DjPartAssembler();
      expect(
          assembler
              .add('@a', {'t': 'part', 'id': 'x', 'i': 5, 'n': 2, 'd': ''}),
          isNull);
      expect(
          assembler
              .add('@a', {'t': 'part', 'id': 'x', 'i': 0, 'n': 1, 'd': '!!'}),
          isNull);
      expect(DjProtocol.decodePacket(DjProtocol.encodePacket({'no': 'type'})),
          isNull);
    });

    test('a snapshot survives the round trip', () {
      const track = DjTrack(
          id: 'a',
          source: 'ext:org.example.music:search:Rick Astley - Never Gonna',
          link: 'https://songs.example/track/1',
          kind: 'Songs',
          title: 'Never Gonna Give You Up',
          artist: 'Rick Astley',
          durationMs: 213573,
          addedBy: '@a:x');
      const snapshot = DjSnapshot(
          epoch: 2,
          seq: 5,
          dj: '@a:x:D',
          current: track,
          queue: [track],
          playing: true,
          buffering: true,
          positionMs: 1234,
          requests: ['@b:x:E'],
          passTo: '@b:x:E');
      final back = DjSnapshot.fromJson(snapshot.toJson())!;
      expect(back.current, track);
      expect(back.queue, [track]);
      expect(back.playing, isTrue);
      expect(back.buffering, isTrue);
      expect(back.positionMs, 1234);
      expect(back.requests, ['@b:x:E']);
      expect(back.passTo, '@b:x:E');
      expect(track.pageUrl, 'https://songs.example/track/1');
    });
  });

  group('DjTrack sources', () {
    DjTrack t(String source, {String? link}) =>
        DjTrack(id: 'a', source: source, link: link, kind: 'x', title: 'T', addedBy: '@a:x');

    test("an extension's track names the extension and its own source", () {
      final track = t('ext:org.example.music:https://music.example/a?b=c:d');
      expect(track.extensionId, 'org.example.music');
      expect(track.extensionSource, 'https://music.example/a?b=c:d');
      expect(track.isLocalFile, isFalse);
      expect(track.pageUrl, 'https://music.example/a?b=c:d');
    });

    test('a page to open only when there is a web one', () {
      expect(t('ext:org.example.music:search:x').pageUrl, isNull);
      expect(t('ext:org.example.music:search:x', link: 'https://songs.example/1').pageUrl,
          'https://songs.example/1');
      expect(t('file:0123456789abcdef0123').pageUrl, isNull);
      // Queued by a client from before extensions.
      expect(t('https://music.example/a').pageUrl, 'https://music.example/a');
      expect(t('https://music.example/a').extensionId, isNull);
    });

    test('local files', () {
      final track = t('file:0123456789abcdef0123');
      expect(track.isLocalFile, isTrue);
      expect(track.extensionId, isNull);
    });

    test('a kind from an older client is kept as it came', () {
      final back = DjTrack.fromJson({'i': 'a', 'u': 'https://x.example/1', 't': 'T', 'k': 'youtube'})!;
      expect(back.kind, 'youtube');
      final none = DjTrack.fromJson({'i': 'a', 'u': 'https://x.example/1', 't': 'T'})!;
      expect(none.kind, DjTrack.linkKind);
      final long = DjTrack.fromJson({'i': 'a', 'u': 'u', 't': 'T', 'k': 'k' * 40})!;
      expect(long.kind.length, DjTrack.maxKind);
    });
  });

  group('DjLinks', () {
    DjLink? p(String s) => DjLinks.parse(s);

    test('links are normalised, tracking parameters dropped', () {
      final link = p('http://music.example/track/1?utm_source=x&si=abc&t=42');
      expect(link?.url, 'https://music.example/track/1?t=42');
      expect(p('https://Music.Example/a')?.host, 'music.example');
      expect(p('https://music.example/a?si=x')?.url, 'https://music.example/a');
    });

    test('pasted text with several links keeps order, without repeats', () {
      final links = DjLinks.parseAll('''
Queue these:
https://music.example/a,
(https://tunes.example/b/c)
https://music.example/a
not a link, nor is music.example/bare
''');
      expect(links.map((l) => l.url), [
        'https://music.example/a',
        'https://tunes.example/b/c',
      ]);
    });

    test('garbage is not a link', () {
      expect(p('ftp://x'), isNull);
      expect(p('hello'), isNull);
      expect(p('https://'), isNull);
    });

    test('hosts match themselves and what is under them', () {
      expect(DjLinks.hostMatches('music.example', 'music.example'), isTrue);
      expect(DjLinks.hostMatches('www.music.example', 'music.example'), isTrue);
      expect(DjLinks.hostMatches('WWW.Music.Example', 'music.example'), isTrue);
      expect(DjLinks.hostMatches('notmusic.example', 'music.example'), isFalse);
      expect(DjLinks.hostMatches('music.example.evil', 'music.example'), isFalse);
    });
  });
}
