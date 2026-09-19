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
              source: 'https://www.youtube.com/watch?v=${'$i'.padLeft(11, 'x')}',
              kind: DjSource.youtube,
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
      expect(assembler.add('@a', {'t': 'part', 'id': 'x', 'i': 5, 'n': 2, 'd': ''}),
          isNull);
      expect(
          assembler.add('@a', {'t': 'part', 'id': 'x', 'i': 0, 'n': 1, 'd': '!!'}),
          isNull);
      expect(DjProtocol.decodePacket(DjProtocol.encodePacket({'no': 'type'})),
          isNull);
    });

    test('a snapshot survives the round trip', () {
      const track = DjTrack(
          id: 'a',
          source: 'ytsearch1:Rick Astley - Never Gonna Give You Up',
          link: 'https://open.spotify.com/track/4cOdK2wGLETKBW3PvgPWqT',
          kind: DjSource.spotify,
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
      expect(track.pageUrl, startsWith('https://open.spotify.com'));
    });
  });

  group('DjLinks', () {
    DjLink? p(String s) => DjLinks.parse(s);

    test('YouTube videos in all their forms', () {
      for (final url in [
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://youtube.com/watch?v=dQw4w9WgXcQ&t=42s',
        'https://m.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://music.youtube.com/watch?v=dQw4w9WgXcQ&list=RDAMVM',
        'https://youtu.be/dQw4w9WgXcQ?si=abc',
        'https://www.youtube.com/shorts/dQw4w9WgXcQ',
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PLx&index=3',
      ]) {
        final link = p(url);
        expect(link?.type, DjLinkType.youtubeVideo, reason: url);
        expect(link?.url, 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            reason: url);
      }
    });

    test('YouTube playlists', () {
      final link = p('https://www.youtube.com/playlist?list=PLabc123');
      expect(link?.type, DjLinkType.youtubePlaylist);
      expect(link?.url, 'https://www.youtube.com/playlist?list=PLabc123');
      expect(link?.isCollection, isTrue);
    });

    test('SoundCloud tracks and sets', () {
      expect(p('https://soundcloud.com/artist/track-name?utm_source=x')?.url,
          'https://soundcloud.com/artist/track-name');
      expect(p('https://soundcloud.com/artist/sets/my-set')?.type,
          DjLinkType.soundcloudSet);
      expect(p('https://on.soundcloud.com/AbCdE')?.type,
          DjLinkType.soundcloudTrack);
      expect(p('https://soundcloud.com/discover/sets/x')?.type,
          DjLinkType.soundcloudSet);
      expect(p('https://soundcloud.com/you/likes'), isNull);
    });

    test('Spotify tracks, albums and playlists', () {
      expect(
          p('https://open.spotify.com/track/4cOdK2wGLETKBW3PvgPWqT?si=x')?.url,
          'https://open.spotify.com/track/4cOdK2wGLETKBW3PvgPWqT');
      expect(
          p('https://open.spotify.com/intl-de/album/4LH4d3cOWNNsVw41Gqt2kv')
              ?.type,
          DjLinkType.spotifyAlbum);
      expect(p('https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M')
          ?.source, DjSource.spotify);
      expect(p('https://open.spotify.com/artist/0gxyHStUsqpMadRV0Di1Qt'),
          isNull);
      expect(p('https://open.spotify.com/'), isNull);
    });

    test('pasted text with several links, some bare, keeps order', () {
      final links = DjLinks.parseAll('''
Queue these:
https://youtu.be/dQw4w9WgXcQ,
youtube.com/watch?v=aaaaaaaaaaa
(https://soundcloud.com/a/b)
https://youtu.be/dQw4w9WgXcQ
not a link
''');
      expect(links.map((l) => l.url), [
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://www.youtube.com/watch?v=aaaaaaaaaaa',
        'https://soundcloud.com/a/b',
      ]);
    });

    test('other links are passed on, garbage is not', () {
      expect(p('https://bandcamp.com/track/x')?.type, DjLinkType.other);
      expect(p('ftp://x'), isNull);
      expect(p('hello'), isNull);
    });
  });
}
