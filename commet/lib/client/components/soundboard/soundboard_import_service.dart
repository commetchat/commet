// MyInstants import pipeline: resolve -> download -> validate -> normalize
// metadata -> caller uploads bytes to MXC.
//
// Split from UI/Matrix so it is unit-testable with injected [fetcher].
// The actual MXC upload stays in the Matrix component (needs authenticated
// client); this service returns validated bytes + suggested metadata.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:commet/client/components/soundboard/audio_decoder.dart';
import 'package:commet/client/components/soundboard/mp3_duration.dart';
import 'package:commet/client/components/soundboard/myinstants_resolver.dart';
import 'package:commet/client/components/soundboard/soundboard_constraints.dart';
import 'package:commet/client/components/soundboard/soundboard_normalizer.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:http/http.dart' as http;

class FetchedAudio {
  final Uint8List bytes;
  final String mimeType;
  final String audioUrl;
  final int? durationMs;
  final double normalizedGain;
  final bool loudnessMeasured;

  const FetchedAudio({
    required this.bytes,
    required this.mimeType,
    required this.audioUrl,
    required this.durationMs,
    required this.normalizedGain,
    required this.loudnessMeasured,
  });
}

typedef HttpFetcher = Future<http.Response> Function(Uri uri);

const _isWeb = bool.fromEnvironment('dart.library.js_interop');

const _redirectStatusCodes = {301, 302, 303, 307, 308};

/// Default [HttpFetcher]: a plain GET that follows at most
/// [SoundboardConstraints.maxRedirects] redirects, each to an allowlisted
/// host.
///
/// MyInstants sits behind Cloudflare, which answers 403 "Attention
/// Required!" to dart:io requests whose User-Agent claims to be a browser
/// (anything starting with `Mozilla/5.0`); the TLS handshake gives the claim
/// away. Dart's own User-Agent gets 200, so do not add browser headers here.
Future<http.Response> fetchFromMyInstants(Uri uri,
    {http.Client? client}) async {
  final c = client ?? http.Client();
  try {
    return await _getFollowingAllowedRedirects(c, uri)
        .timeout(SoundboardConstraints.httpTimeout);
  } finally {
    if (client == null) c.close();
  }
}

Future<http.Response> _getFollowingAllowedRedirects(
    http.Client client, Uri uri) async {
  var current = uri;
  for (var redirects = 0;; redirects++) {
    // Browsers only allow following redirects or failing on them.
    final request = http.Request('GET', current)..followRedirects = _isWeb;
    final response = await http.Response.fromStream(await client.send(request));
    final location = response.headers['location'];
    if (!_redirectStatusCodes.contains(response.statusCode) ||
        location == null) {
      return response;
    }
    if (redirects == SoundboardConstraints.maxRedirects) {
      throw const MyInstantsRequestError(
          'MyInstants redirected too many times');
    }
    current = current.resolve(location);
    if (!MyInstantsResolver.isAllowedUrl(current.toString())) {
      throw MyInstantsRequestError(
          'MyInstants redirected to an unsupported site (${current.host})');
    }
  }
}

class SoundboardImportService {
  final HttpFetcher fetcher;

  /// Decodes non-WAV audio for loudness measurement.
  final AudioDecoder decoder;

  /// Receives one line per import step (URLs, HTTP responses, duration) so a
  /// failed import can be traced from the log.
  final void Function(String message) log;

  SoundboardImportService(
      {HttpFetcher? fetcher,
      AudioDecoder? decoder,
      void Function(String message)? log})
      : fetcher = fetcher ?? fetchFromMyInstants,
        decoder = decoder ?? decodeWithPlatform,
        log = log ?? _ignore;

  static void _ignore(String _) {}

  /// Full import from an admin-pasted MyInstants URL. Accepts either an
  /// instant page URL (…/instant/<slug>/) or a direct audio file URL
  /// (…/media/sounds/….mp3) from the same host.
  Future<FetchedAudio> importFromPageUrl(String pageUrl) async {
    final url = MyInstantsResolver.normalizeUrl(pageUrl);
    final uri = Uri.tryParse(url);
    log('input "${pageUrl.trim()}" -> $url '
        '(scheme=${uri?.scheme} host=${uri?.host} path=${uri?.path})');
    MyInstantsResolver.requireAllowedUrl(url);
    if (_looksLikeAudioFileUrl(url)) {
      return importFromAudioUrl(url);
    }
    final page = await _fetch(Uri.parse(url));
    _checkStatus(page, 'page');
    final audioUrl = MyInstantsResolver.extractAudioUrl(
      page.body,
      pageUrl: url,
    );
    log('audio url: ${audioUrl ?? 'none found'}');
    if (audioUrl == null) {
      throw const MyInstantsValidationError(
          'Could not find audio on that MyInstants page');
    }
    return importFromAudioUrl(audioUrl);
  }

  static bool _looksLikeAudioFileUrl(String url) {
    final path = url.toLowerCase().split('?').first;
    return SoundboardConstraints.allowedExtensions
        .any((ext) => path.endsWith(ext));
  }

  /// Runs [fetcher], translating low-level network failures into a
  /// user-actionable validation error instead of a generic crash.
  Future<http.Response> _fetch(Uri uri) async {
    if (_isWeb) {
      // MyInstants sends no CORS headers, so a browser cannot read its pages
      // or sound files.
      throw const MyInstantsRequestError(
          'MyInstants does not allow importing from the browser. '
          'Add the sound from the desktop or mobile app.');
    }
    log('GET $uri');
    try {
      final res = await fetcher(uri);
      log('-> ${_describe(res)}');
      return res;
    } on MyInstantsValidationError catch (e) {
      log('-> $e');
      rethrow;
    } on SocketException catch (e) {
      log('-> failed: $e');
      throw MyInstantsRequestError('Could not connect to ${uri.host}. '
          'Check your internet connection and try again.');
    } on TimeoutException {
      log('-> timed out');
      throw MyInstantsRequestError('${uri.host} did not answer in time. '
          'Check your internet connection and try again.');
    } on http.ClientException catch (e) {
      // IOClient reports HttpException (e.g. connection closed) this way.
      log('-> failed: $e');
      throw MyInstantsRequestError(
          'The connection to ${uri.host} failed (${e.message}). '
          'Check your internet connection and try again.');
    } on IOException catch (e) {
      // TLS failures (e.g. HTTPS inspection) are not wrapped by IOClient.
      log('-> failed: $e');
      throw MyInstantsRequestError('The connection to ${uri.host} failed ($e)');
    }
  }

  static String _describe(http.Response res) {
    final parts = [
      '${res.statusCode}',
      '${res.headers['content-type']}',
      '${res.bodyBytes.length} bytes',
      if (res.request != null) 'from ${res.request!.url}',
    ];
    if (res.statusCode >= 300) {
      final title = RegExp(r'<title>([^<]*)</title>', caseSensitive: false)
          .firstMatch(res.body)
          ?.group(1)
          ?.trim();
      parts.addAll([
        if (title != null) 'title="$title"',
        if (res.headers['server'] != null) 'server=${res.headers['server']}',
        if (res.headers['cf-ray'] != null) 'cf-ray=${res.headers['cf-ray']}',
        if (res.headers['cf-mitigated'] != null)
          'cf-mitigated=${res.headers['cf-mitigated']}',
      ]);
    }
    return parts.join(', ');
  }

  static void _checkStatus(http.Response res, String what) {
    final code = res.statusCode;
    if (code >= 200 && code < 300) return;
    if (code == 403 || code == 429) {
      throw MyInstantsRequestError(
          'MyInstants refused the $what request (HTTP $code, bot protection)');
    }
    if (code == 404) {
      throw MyInstantsRequestError(
          'MyInstants $what not found (HTTP 404). Check the link.');
    }
    throw MyInstantsRequestError(
        'MyInstants $what request failed (HTTP $code)');
  }

  /// Imports already-resolved audio file bytes (also used by tests).
  Future<FetchedAudio> importFromAudioUrl(String audioUrl) async {
    MyInstantsResolver.requireAllowedUrl(audioUrl);
    final res = await _fetch(Uri.parse(audioUrl));
    _checkStatus(res, 'audio');
    final contentType =
        res.headers['content-type']?.split(';').first.trim().toLowerCase();
    MyInstantsResolver.validateDownload(
      byteLength: res.bodyBytes.length,
      contentType: res.headers['content-type'],
      downloadUrl: audioUrl,
    );
    final bytes = res.bodyBytes;
    final mime = _inferMime(contentType, audioUrl);
    final pcm = await _decode(bytes, mime);
    final durationMs = _measureDurationMs(bytes, mime, pcm);
    log('duration: ${durationMs == null ? 'unknown' : '$durationMs ms'} '
        '($mime)');
    if (durationMs != null &&
        durationMs > SoundboardConstraints.maxDurationMs) {
      throw MyInstantsValidationError(
          'Audio too long (${_seconds(durationMs)} s, '
          'max ${_seconds(SoundboardConstraints.maxDurationMs)} s)');
    }
    final estimate = pcm == null
        ? SoundboardNormalizer.fallback()
        : await compute(SoundboardNormalizer.analyze, pcm);
    log('loudness: $estimate');
    return FetchedAudio(
      bytes: bytes,
      mimeType: mime,
      audioUrl: audioUrl,
      durationMs: durationMs,
      normalizedGain: estimate.gain,
      loudnessMeasured: estimate.measured,
    );
  }

  Future<PcmAudio?> _decode(Uint8List bytes, String mime) async {
    final wav = SoundboardNormalizer.decodeWav(bytes);
    if (wav != null) return wav;
    try {
      final pcm = await decoder(bytes, mime);
      if (pcm == null) log('decoder: $mime not decodable on this platform');
      return pcm;
    } catch (e) {
      log('decoder: failed on $mime: $e');
      return null;
    }
  }

  static String _seconds(int ms) =>
      (ms / 1000).toStringAsFixed(ms % 1000 == 0 ? 0 : 1);

  static String _inferMime(String? contentType, String url) {
    if (contentType != null && contentType.startsWith('audio/')) {
      return contentType;
    }
    final lower = url.toLowerCase().split('?').first;
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.ogg') || lower.endsWith('.oga')) return 'audio/ogg';
    if (lower.endsWith('.opus')) return 'audio/opus';
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.webm')) return 'audio/webm';
    if (lower.endsWith('.m4a')) return 'audio/mp4';
    if (lower.endsWith('.flac')) return 'audio/flac';
    return 'audio/mpeg';
  }

  /// MP3 duration comes from its frame headers (the decoder stops at
  /// [maxDecodeSeconds]); everything else from the decoded PCM. Null when
  /// neither is available (accepted, bounded at playback by natural end +
  /// overlay clamp).
  static int? _measureDurationMs(Uint8List bytes, String mime, PcmAudio? pcm) {
    if (mime == 'audio/mpeg' || mime == 'audio/mp3') {
      final ms = Mp3Duration.inMilliseconds(bytes);
      if (ms != null) return ms;
    }
    return pcm?.durationMs;
  }
}
