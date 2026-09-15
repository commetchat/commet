// MyInstants import pipeline: resolve -> download -> validate -> normalize
// metadata -> caller uploads bytes to MXC.
//
// Split from UI/Matrix so it is unit-testable with injected [fetcher].
// The actual MXC upload stays in the Matrix component (needs authenticated
// client); this service returns validated bytes + suggested metadata.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:commet/client/components/soundboard/myinstants_resolver.dart';
import 'package:commet/client/components/soundboard/soundboard_constraints.dart';
import 'package:commet/client/components/soundboard/soundboard_normalizer.dart';
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

Future<http.Response> _defaultFetcher(Uri uri) {
  // MyInstants (behind anti-bot protection) rejects non-browser clients
  // with 403, so present full browser-like headers.
  return http
      .get(uri, headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,audio/mpeg,audio/ogg,audio/wav,audio/*;q=0.8,*/*;q=0.5',
        'Accept-Language': 'en-US,en;q=0.9',
        'Referer': 'https://www.myinstants.com/',
        'Upgrade-Insecure-Requests': '1',
        'Sec-Fetch-Site': 'same-origin',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Dest': 'document',
      })
      .timeout(SoundboardConstraints.httpTimeout);
}

class SoundboardImportService {
  final HttpFetcher fetcher;

  SoundboardImportService({HttpFetcher? fetcher})
      : fetcher = fetcher ?? _defaultFetcher;

  /// Full import from an admin-pasted MyInstants URL. Accepts either an
  /// instant page URL (…/instant/<slug>/) or a direct audio file URL
  /// (…/media/sounds/….mp3) from the same host as an escape hatch when the
  /// page is unreadable.
  Future<FetchedAudio> importFromPageUrl(String pageUrl) async {
    final trimmed = pageUrl.trim();
    MyInstantsResolver.requireAllowedUrl(trimmed);
    if (_looksLikeAudioFileUrl(trimmed)) {
      return importFromAudioUrl(trimmed);
    }
    final pageRes = await _fetch(Uri.parse(trimmed));
    if (pageRes.statusCode == 403 || pageRes.statusCode == 429) {
      throw const MyInstantsValidationError(
          'MyInstants refused the connection (bot protection)');
    }
    if (pageRes.statusCode == 404) {
      throw const MyInstantsValidationError(
          'MyInstants page not found (404)');
    }
    if (pageRes.statusCode < 200 || pageRes.statusCode >= 300) {
      throw MyInstantsValidationError(
          'MyInstants page not found (${pageRes.statusCode})');
    }
    final audioUrl = MyInstantsResolver.extractAudioUrl(
      pageRes.body,
      pageUrl: trimmed,
    );
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
    try {
      return await fetcher(uri);
    } on SocketException catch (e) {
      throw MyInstantsValidationError(
          'Network unreachable (${e.address?.host ?? uri.host}). '
          'Check your internet connection and try again.');
    } on TimeoutException {
      throw const MyInstantsValidationError(
          'Network timeout. Check your internet connection and try again.');
    } on HttpException {
      throw const MyInstantsValidationError(
          'Network error. Check your internet connection and try again.');
    }
  }

  /// Imports already-resolved audio file bytes (also used by tests).
  Future<FetchedAudio> importFromAudioUrl(String audioUrl) async {
    MyInstantsResolver.requireAllowedUrl(audioUrl);
    final res = await _fetch(Uri.parse(audioUrl));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw MyInstantsValidationError(
          'Audio download failed (${res.statusCode})');
    }
    final contentType =
        res.headers['content-type']?.split(';').first.trim().toLowerCase();
    MyInstantsResolver.validateDownload(
      byteLength: res.bodyBytes.length,
      contentType: res.headers['content-type'],
      downloadUrl: audioUrl,
    );
    final bytes = res.bodyBytes;
    final mime = _inferMime(contentType, audioUrl);
    final durationMs = _estimateDurationMs(bytes, mime);
    if (durationMs != null &&
        durationMs > SoundboardConstraints.maxDurationMs) {
      throw const MyInstantsValidationError('Audio too long (max 15s)');
    }
    final estimate = _estimateLoudness(bytes, mime);
    return FetchedAudio(
      bytes: bytes,
      mimeType: mime,
      audioUrl: audioUrl,
      durationMs: durationMs,
      normalizedGain: estimate.gain,
      loudnessMeasured: estimate.measured,
    );
  }

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

  /// Best-effort duration probe. WAV parsed exactly; MP3 estimated from
  /// bitrate (CBR assumption, 128kbps fallback); others null (accepted,
  /// enforced at playback by natural end + overlay clamp).
  static int? _estimateDurationMs(Uint8List bytes, String mime) {
    // WAV: exact.
    final pcm = SoundboardNormalizer.decodeWav16(bytes);
    if (pcm != null) {
      // Need sample rate: parse fmt chunk.
      try {
        if (bytes.length >= 28) {
          var offset = 12;
          while (offset + 8 <= bytes.length) {
            final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
            final size = ByteData.sublistView(bytes, offset + 4, offset + 8)
                .getUint32(0, Endian.little);
            if (id == 'fmt ') {
              final bd =
                  ByteData.sublistView(bytes, offset + 8, offset + 8 + size);
              final sampleRate = bd.getUint32(4, Endian.little);
              if (sampleRate > 0 && pcm.isNotEmpty) {
                return (pcm.length * 1000 / sampleRate).round();
              }
              break;
            }
            offset += 8 + size + (size.isOdd ? 1 : 0);
          }
        }
      } catch (_) {}
    }
    if (mime == 'audio/mpeg' || mime == 'audio/mp3') {
      // Rough CBR estimate; VBR will be off but within 2x — acceptable for
      // a 15s cap (a 30s VBR file may slip; playback still ends naturally).
      const bitsPerSecond = 128000;
      return (bytes.length * 8 * 1000 / bitsPerSecond).round();
    }
    return null;
  }

  static LoudnessEstimate _estimateLoudness(Uint8List bytes, String mime) {
    if (mime == 'audio/wav' ||
        mime == 'audio/x-wav' ||
        mime == 'audio/wave') {
      final pcm = SoundboardNormalizer.decodeWav16(bytes);
      if (pcm != null && pcm.isNotEmpty) {
        return SoundboardNormalizer.analyze(pcm);
      }
    }
    return SoundboardNormalizer.fallback();
  }
}
