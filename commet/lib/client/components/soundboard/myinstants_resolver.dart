// MyInstants URL validation + audio-URL extraction. Pure Dart.
//
// Security model: admin-provided URLs are untrusted. Only exact-match hosts
// in [SoundboardConstraints.allowedHosts] are accepted — never suffix/regex
// matches (blocks `myinstants.com.attacker.com`). No file://, localhost,
// private IPs, or arbitrary schemes. Redirects/bytes validated by caller.
import 'soundboard_constraints.dart';

class MyInstantsValidationError implements Exception {
  final String message;
  const MyInstantsValidationError(this.message);
  @override
  String toString() => 'MyInstantsValidationError: $message';
}

class MyInstantsResolver {
  /// Returns true only for http(s) URLs whose host exactly matches the
  /// allowlist (case-insensitive, optional port stripped for comparison,
  /// trailing dot tolerated).
  static bool isAllowedUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    if (uri.host.isEmpty) return false;
    var host = uri.host.toLowerCase();
    if (host.endsWith('.')) host = host.substring(0, host.length - 1);
    return SoundboardConstraints.allowedHosts.contains(host);
  }

  static void requireAllowedUrl(String url) {
    if (!isAllowedUrl(url)) {
      throw MyInstantsValidationError(
          'Only myinstants.com links are supported');
    }
    final uri = Uri.parse(url.trim());
    // Defense in depth: reject credentials / non-default trickery.
    if (uri.userInfo.isNotEmpty) {
      throw const MyInstantsValidationError('URL must not contain credentials');
    }
  }

  /// Extracts the direct audio file URL from a MyInstants instant page.
  ///
  /// Lookup order (most stable first):
  /// 1. `<meta property="og:audio" content="...">` (and name= variant)
  /// 2. `onclick="play('/media/sounds/xxx.mp3')"` / `onmousedown` variant
  ///    (the player's actual source — what the site itself plays)
  /// 3. `<a ... download href="/media/sounds/xxx.mp3">`
  ///
  /// Returns an absolute https URL on the same allowlisted host, or null.
  /// Never returns arbitrary third-party URLs found in page markup.
  static String? extractAudioUrl(String pageHtml, {required String pageUrl}) {
    final pageUri = Uri.tryParse(pageUrl);
    final pageHost =
        (pageUri?.host.toLowerCase() ?? 'www.myinstants.com');

    String? absolutize(String raw) {
      raw = raw.trim().replaceAll('&amp;', '&');
      if (raw.isEmpty) return null;
      Uri? u = Uri.tryParse(raw);
      if (u == null) return null;
      if (!u.hasScheme) {
        u = pageUri?.resolve(raw);
      }
      if (u == null) return null;
      // Only allow audio files served from the MyInstants host itself.
      var host = u.host.toLowerCase();
      if (host.endsWith('.')) host = host.substring(0, host.length - 1);
      if (!SoundboardConstraints.allowedHosts.contains(host)) return null;
      if (u.scheme != 'http' && u.scheme != 'https') return null;
      if (!_looksLikeAudioPath(u.path)) return null;
      // Force https for playback/download.
      return u.replace(scheme: 'https').toString();
    }

    // 1. og:audio (order of attributes varies; both quote styles).
    final ogAudio = RegExp(
      '''<meta\\s[^>]*?(?:property|name)\\s*=\\s*["']og:audio["'][^>]*?content\\s*=\\s*["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(pageHtml);
    if (ogAudio != null) {
      final abs = absolutize(ogAudio.group(1)!);
      if (abs != null) return abs;
    }
    final ogAudioRev = RegExp(
      '''<meta\\s[^>]*?content\\s*=\\s*["']([^"']+)["'][^>]*?(?:property|name)\\s*=\\s*["']og:audio["']''',
      caseSensitive: false,
    ).firstMatch(pageHtml);
    if (ogAudioRev != null) {
      final abs = absolutize(ogAudioRev.group(1)!);
      if (abs != null) return abs;
    }

    // 2. play('/media/sounds/xxx.mp3') — primary player hook.
    final playHook = RegExp(
      '''play\\(\\s*['"](\\/media\\/sounds\\/[^'"]+)['"]''',
      caseSensitive: false,
    ).firstMatch(pageHtml);
    if (playHook != null) {
      final abs = absolutize(playHook.group(1)!);
      if (abs != null) return abs;
    }

    // 3. download anchor.
    final dl = RegExp(
      '''<a\\s[^>]*?download[^>]*?href\\s*=\\s*["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(pageHtml);
    if (dl != null) {
      final abs = absolutize(dl.group(1)!);
      if (abs != null) return abs;
    }
    void unused() {
      // keeps `pageHost` referenced for future host-pinning logs.
      assert(pageHost.isNotEmpty);
    }

    unused();
    return null;
  }

  static bool _looksLikeAudioPath(String path) {
    final lower = path.toLowerCase();
    for (final ext in SoundboardConstraints.allowedExtensions) {
      if (lower.endsWith(ext)) return true;
    }
    // /media/sounds/ without extension (rare) — allow, content-type check
    // at download time is authoritative.
    return lower.contains('/media/sounds/');
  }

  /// Validates downloaded bytes before they are stored: size + MIME.
  static void validateDownload({
    required int byteLength,
    required String? contentType,
    required String downloadUrl,
  }) {
    if (byteLength <= 0) {
      throw const MyInstantsValidationError('Downloaded file is empty');
    }
    if (byteLength > SoundboardConstraints.maxFileBytes) {
      throw const MyInstantsValidationError('Audio file too large');
    }
    if (contentType != null) {
      final mime = contentType.split(';').first.trim().toLowerCase();
      final ok = mime.startsWith('audio/') ||
          mime == 'application/octet-stream' ||
          mime == 'binary/octet-stream';
      if (!ok) {
        throw MyInstantsValidationError('Not an audio file ($mime)');
      }
    }
    if (!isAllowedUrl(downloadUrl) &&
        !_isSameHostMediaUrl(downloadUrl)) {
      throw const MyInstantsValidationError('Unexpected download host');
    }
  }

  static bool _isSameHostMediaUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    var host = uri.host.toLowerCase();
    if (host.endsWith('.')) host = host.substring(0, host.length - 1);
    return SoundboardConstraints.allowedHosts.contains(host);
  }
}
