import 'package:commet/client/components/soundboard/myinstants_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('MyInstants allowlist', () {
    test('accepts official hosts', () {
      expect(
          MyInstantsResolver.isAllowedUrl(
              'https://www.myinstants.com/en/instant/vine-boom-70972/'),
          isTrue);
      expect(
          MyInstantsResolver.isAllowedUrl(
              'https://myinstants.com/media/sounds/vine-boom.mp3'),
          isTrue);
    });

    test('rejects lookalike attacker domain', () {
      expect(
          MyInstantsResolver.isAllowedUrl(
              'https://myinstants.com.attacker.com/x.mp3'),
          isFalse);
      expect(
          MyInstantsResolver.isAllowedUrl(
              'https://www.myinstants.com.evil.org/instant/1/'),
          isFalse);
    });

    test('rejects non-http schemes and credentials', () {
      expect(MyInstantsResolver.isAllowedUrl('file:///etc/passwd'), isFalse);
      expect(MyInstantsResolver.isAllowedUrl('http://localhost:8000/x.mp3'),
          isFalse);
      expect(
          MyInstantsResolver.isAllowedUrl('http://127.0.0.1/x.mp3'), isFalse);
      expect(
          () => MyInstantsResolver.requireAllowedUrl(
              'https://user:pass@www.myinstants.com/x'),
          throwsA(isA<MyInstantsValidationError>()));
    });
  });

  group('extractAudioUrl', () {
    test('prefers og:audio', () {
      const html = '''
<html><head>
<meta property="og:audio" content="https://www.myinstants.com/media/sounds/vine-boom.mp3" />
<script>play('/media/sounds/other.mp3')</script>
</head></html>''';
      expect(
          MyInstantsResolver.extractAudioUrl(html,
              pageUrl: 'https://www.myinstants.com/en/instant/x/'),
          'https://www.myinstants.com/media/sounds/vine-boom.mp3');
    });

    test('falls back to play() hook', () {
      const html = '''
<div class="instant">
<a class="small-button" onclick="play('/media/sounds/bruh.mp3')">play</a>
</div>''';
      expect(
          MyInstantsResolver.extractAudioUrl(html,
              pageUrl: 'https://www.myinstants.com/en/instant/bruh/'),
          'https://www.myinstants.com/media/sounds/bruh.mp3');
    });

    test('never returns third-party URLs from markup', () {
      const html = '''
<meta property="og:audio" content="https://evil.com/steal.mp3" />
<script>play('/media/sounds/ok.mp3')</script>''';
      // Evil og:audio is skipped, play() hook (same host) wins.
      expect(
          MyInstantsResolver.extractAudioUrl(html,
              pageUrl: 'https://www.myinstants.com/en/instant/x/'),
          'https://www.myinstants.com/media/sounds/ok.mp3');
    });

    test('returns null when nothing found', () {
      expect(
          MyInstantsResolver.extractAudioUrl('<html></html>',
              pageUrl: 'https://www.myinstants.com/en/instant/x/'),
          isNull);
    });
  });

  group('validateDownload', () {
    test('rejects oversized files', () {
      expect(
          () => MyInstantsResolver.validateDownload(
            byteLength: 2 * 1024 * 1024,
            contentType: 'audio/mpeg',
            downloadUrl: 'https://www.myinstants.com/media/sounds/x.mp3',
          ),
          throwsA(isA<MyInstantsValidationError>()));
    });

    test('rejects non-audio content', () {
      expect(
          () => MyInstantsResolver.validateDownload(
            byteLength: 100,
            contentType: 'text/html',
            downloadUrl: 'https://www.myinstants.com/media/sounds/x.mp3',
          ),
          throwsA(isA<MyInstantsValidationError>()));
    });

    test('accepts audio with octet-stream fallback', () {
      MyInstantsResolver.validateDownload(
        byteLength: 1000,
        contentType: 'application/octet-stream',
        downloadUrl: 'https://www.myinstants.com/media/sounds/x.mp3',
      );
    });
  });
}
