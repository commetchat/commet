// yt-dlp, as the DJ booth uses it: list what a link holds, and download one
// song's audio to the booth's cache.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:commet/client/matrix/components/dj/native/dj_tools.dart';

class YtDlpException implements Exception {
  final String message;
  YtDlpException(this.message);

  /// yt-dlp's own error line, without the noise around it.
  static YtDlpException fromOutput(String stderr, String fallback) {
    final lines = const LineSplitter()
        .convert(stderr)
        .map((l) => l.startsWith('ERROR:')
            ? l.substring(6).trim()
            // Its command line parser: an option this yt-dlp doesn't know.
            : l.contains(': error: ')
                ? l.substring(l.indexOf(': error: ') + 9).trim()
                : null)
        .whereType<String>()
        .toList();
    var message = lines.isEmpty ? fallback : lines.last;
    // "[youtube] dQw4w9WgXcQ: Video unavailable" -> "Video unavailable"
    message = message.replaceFirst(RegExp(r'^\[[^\]]+\]\s*[^:]*:\s*'), '');
    return YtDlpException(message);
  }

  @override
  String toString() => message;
}

/// A downloaded song and what yt-dlp said about it.
class YtDlpDownload {
  final String path;
  final Map<String, Object?> info;

  const YtDlpDownload(this.path, this.info);
}

class YtDlp {
  final DjToolPaths tools;

  YtDlp(this.tools);

  List<String> get _common => [
        '--ignore-config',
        '--no-warnings',
        '--js-runtimes',
        tools.jsRuntime,
      ];

  /// What [url] holds, without downloading: one video, or a playlist whose
  /// entries are only listed (`--flat-playlist`), which is fast.
  Future<Map<String, Object?>> inspect(String url,
      {bool playlist = false}) async {
    final result = await runQuietly(
        tools.ytDlp,
        [
          ..._common,
          '--dump-single-json',
          '--flat-playlist',
          playlist ? '--yes-playlist' : '--no-playlist',
          '--',
          url,
        ],
        timeout: const Duration(seconds: 90));
    final json = _lastJsonObject(result.stdout);
    if (json == null) {
      throw YtDlpException.fromOutput(result.stderr, "Couldn't read $url");
    }
    return json;
  }

  /// Audio formats the booth's decoder reads (AAC in MP4, MP3, Vorbis,
  /// FLAC) over plain HTTP: HLS from YouTube comes in MPEG-TS, which it
  /// doesn't read. MP3 is the exception, SoundCloud's HLS MP3 segments join
  /// into a valid file. The last resort is a small video with AAC audio,
  /// never a big HLS one.
  static const formatSelector = 'ba[acodec^=mp4a][protocol^=http]'
      '/ba[acodec=mp3]'
      '/ba[ext=m4a][protocol^=http]'
      '/ba[ext=mp3]'
      '/ba[acodec=vorbis][protocol^=http]'
      '/ba[acodec=flac][protocol^=http]'
      '/b[ext=mp4][protocol^=http][height<=480]'
      '/ba[protocol^=http]';

  /// Downloads [source]'s audio as `<directory>/<name>.<ext>`.
  /// [knownSitesOnly] leaves out yt-dlp's generic extractor, which fetches
  /// any page it is given: for songs another client named.
  Future<YtDlpDownload> download(String source,
      {required String directory,
      required String name,
      bool knownSitesOnly = false}) async {
    final result = await runQuietly(
        tools.ytDlp,
        [
          ..._common,
          if (knownSitesOnly) ...['--use-extractors', 'default,-generic'],
          '--no-playlist',
          '--no-progress',
          '--no-mtime',
          // Downloads land in a .part file first: one cut short is never
          // mistaken for a finished song.
          '-f',
          formatSelector,
          '-o',
          // `%` is template syntax in yt-dlp's output name.
          '${directory.replaceAll('%', '%%')}${Platform.pathSeparator}'
              '$name.%(ext)s',
          '--print',
          'after_move:%(.{filepath,title,uploader,channel,artist,creator,duration,thumbnail,id,extractor_key})j',
          '--',
          source,
        ],
        timeout: const Duration(minutes: 10));
    final info = _lastJsonObject(result.stdout);
    final path = info?['filepath'];
    if (info == null || path is! String || !await File(path).exists()) {
      throw YtDlpException.fromOutput(
          result.stderr, "Couldn't download the song");
    }
    return YtDlpDownload(path, info);
  }

  static Map<String, Object?>? _lastJsonObject(String output) {
    for (final line in const LineSplitter().convert(output).reversed) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('{')) continue;
      try {
        final json = jsonDecode(trimmed);
        if (json is Map<String, Object?>) return json;
      } catch (_) {}
    }
    return null;
  }
}
