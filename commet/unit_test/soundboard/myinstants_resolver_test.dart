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

  group('normalizeUrl', () {
    test('keeps a plain URL', () {
      expect(
          MyInstantsResolver.normalizeUrl(
              ' https://www.myinstants.com/pt/instant/faaah-63455/\n'),
          'https://www.myinstants.com/pt/instant/faaah-63455/');
    });

    test('unwraps Markdown links and angle brackets', () {
      expect(
          MyInstantsResolver.normalizeUrl(
              '[www.myinstants.com](http://www.myinstants.com)'),
          'http://www.myinstants.com');
      expect(
          MyInstantsResolver.normalizeUrl(
              '<https://www.myinstants.com/pt/instant/faaah-63455/>'),
          'https://www.myinstants.com/pt/instant/faaah-63455/');
    });

    test('adds https to a bare address and drops the fragment', () {
      expect(
          MyInstantsResolver.normalizeUrl(
              'www.myinstants.com/pt/instant/faaah-63455/#top'),
          'https://www.myinstants.com/pt/instant/faaah-63455/');
      expect(
          MyInstantsResolver.normalizeUrl(
              'MyInstants.com/media/sounds/faaah.mp3'),
          'https://MyInstants.com/media/sounds/faaah.mp3');
    });

    test('leaves other sites for the allowlist to reject', () {
      for (final input in [
        'myinstants.com.evil.org/x.mp3',
        '[myinstants](https://evil.org/myinstants.com)',
      ]) {
        expect(
            MyInstantsResolver.isAllowedUrl(
                MyInstantsResolver.normalizeUrl(input)),
            isFalse,
            reason: input);
      }
    });
  });

  group('extractAudioUrl', () {
    test('reads the live instant page markup', () {
      // Trimmed from https://www.myinstants.com/pt/instant/faaah-63455/.
      const html = '''
<meta property="og:audio" content="https://www.myinstants.com/media/sounds/faaah.mp3"/>
<meta property="og:audio:type" content="audio/mpeg" />
<button onclick="play('/media/sounds/faaah.mp3', 'loader-', 'faaah-63455')"></button>
<a href="/media/sounds/faaah.mp3" download target="_blank" class="instant-page-extra-button btn btn-primary">''';
      expect(
          MyInstantsResolver.extractAudioUrl(html,
              pageUrl: 'https://www.myinstants.com/pt/instant/faaah-63455/'),
          'https://www.myinstants.com/media/sounds/faaah.mp3');
    });

    test('falls back to a download link with href before download', () {
      const html = '''
<a href="/pt/instant/faaah-63455/">faaah</a>
<a href="/media/sounds/faaah.mp3" download target="_blank">download</a>''';
      expect(
          MyInstantsResolver.extractAudioUrl(html,
              pageUrl: 'https://www.myinstants.com/pt/instant/faaah-63455/'),
          'https://www.myinstants.com/media/sounds/faaah.mp3');
    });

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
