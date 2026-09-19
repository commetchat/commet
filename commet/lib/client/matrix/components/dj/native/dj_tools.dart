// The programs the DJ booth runs on desktop: yt-dlp, which fetches songs from
// YouTube and SoundCloud, and a JavaScript runtime, which yt-dlp needs to
// solve YouTube's player challenges (Deno by default; Node 22+ works too).
//
// Found on PATH when the user has them, otherwise downloaded once from their
// GitHub releases into the app's data folder, with the user's consent. The
// managed yt-dlp updates itself daily: YouTube changes break older ones.
import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Runs a program without flashing a console window on Windows.
///
/// A GUI app on Windows gives every console child its own visible console
/// unless it is detached; `detachedWithStdio` keeps the pipes but has no exit
/// code, so it is read from nothing but the output.
Future<Process> startQuietly(String executable, List<String> arguments,
    {String? workingDirectory}) {
  return Process.start(executable, arguments,
      workingDirectory: workingDirectory,
      mode: Platform.isWindows
          ? ProcessStartMode.detachedWithStdio
          : ProcessStartMode.normal);
}

/// Output of a finished program.
class QuietResult {
  final String stdout;
  final String stderr;

  /// Null on Windows, where the program runs detached (see [startQuietly]).
  final int? exitCode;

  const QuietResult(this.stdout, this.stderr, this.exitCode);
}

/// Runs a program to its end, or kills it after [timeout].
Future<QuietResult> runQuietly(String executable, List<String> arguments,
    {Duration timeout = const Duration(minutes: 1)}) async {
  final process = await startQuietly(executable, arguments);
  final out = StringBuffer();
  final err = StringBuffer();
  final outDone = process.stdout
      .transform(const SystemEncoding().decoder)
      .forEach(out.write);
  final errDone = process.stderr
      .transform(const SystemEncoding().decoder)
      .forEach(err.write);
  try {
    await Future.wait([outDone, errDone]).timeout(timeout);
  } on TimeoutException {
    process.kill();
    throw TimeoutException('$executable took too long', timeout);
  }
  final exitCode = Platform.isWindows
      ? null
      : await process.exitCode.timeout(const Duration(seconds: 5),
          onTimeout: () => -1);
  return QuietResult(out.toString(), err.toString(), exitCode);
}

enum DjTool { ytDlp, jsRuntime }

/// Lets the user stop a tools download.
class DjDownloadCancel {
  bool cancelled = false;
  http.Client? _client;

  void cancel() {
    cancelled = true;
    _client?.close();
  }
}

class DjDownloadCancelled implements Exception {
  const DjDownloadCancelled();

  @override
  String toString() => 'Cancelled';
}

/// What the booth found, ready to hand to yt-dlp.
class DjToolPaths {
  final String ytDlp;

  /// `--js-runtimes` value, e.g. `deno:/path/to/deno`.
  final String jsRuntime;

  /// Whether yt-dlp is ours to update.
  final bool managedYtDlp;

  const DjToolPaths(
      {required this.ytDlp, required this.jsRuntime, required this.managedYtDlp});
}

class DjTools {
  DjTools._();
  static final DjTools instance = DjTools._();

  Directory? _dir;

  Future<Directory> get directory async {
    final dir = _dir ??=
        Directory(p.join((await getApplicationSupportDirectory()).path, 'dj-tools'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String get _exe => Platform.isWindows ? '.exe' : '';

  DjToolPaths? _found;
  Future<DjToolPaths?>? _locating;

  /// The tools, or null when something is missing (see [missing]).
  Future<DjToolPaths?> locate({bool refresh = false}) {
    if (refresh) {
      _found = null;
      _locating = null;
    }
    if (_found != null) return Future.value(_found);
    return _locating ??= _locate().whenComplete(() => _locating = null);
  }

  Future<DjToolPaths?> _locate() async {
    final ytDlp = await _findYtDlp();
    final js = await _findJsRuntime();
    if (ytDlp == null || js == null) return null;
    _found = DjToolPaths(ytDlp: ytDlp.$1, jsRuntime: js, managedYtDlp: ytDlp.$2);
    _updateInBackground(_found!);
    return _found;
  }

  /// What [locate] could not find.
  Future<Set<DjTool>> missing() async => {
        if (await _findYtDlp() == null) DjTool.ytDlp,
        if (await _findJsRuntime() == null) DjTool.jsRuntime,
      };

  /// The first yt-dlp with `--js-runtimes`, which YouTube needs now. Linux
  /// distributions ship far older ones.
  static const minYtDlp = (2025, 11, 12);

  static bool _recentYtDlp(String version) {
    final match = RegExp(r'(\d{4})\.(\d{1,2})\.(\d{1,2})').firstMatch(version);
    if (match == null) return false;
    final v = (int.parse(match[1]!), int.parse(match[2]!), int.parse(match[3]!));
    if (v.$1 != minYtDlp.$1) return v.$1 > minYtDlp.$1;
    if (v.$2 != minYtDlp.$2) return v.$2 > minYtDlp.$2;
    return v.$3 >= minYtDlp.$3;
  }

  Future<(String, bool)?> _findYtDlp() async {
    final managed = File(p.join((await directory).path, 'yt-dlp$_exe'));
    if (await managed.exists()) return (managed.path, true);
    final onPath = await _version('yt-dlp', ['--version']);
    if (onPath != null && _recentYtDlp(onPath)) return ('yt-dlp', false);
    return null;
  }

  Future<String?> _findJsRuntime() async {
    final managed = File(p.join((await directory).path, 'deno$_exe'));
    if (await managed.exists() &&
        await _version(managed.path, ['--version']) != null) {
      return 'deno:${managed.path}';
    }
    final deno = await _version('deno', ['--version']);
    if (deno != null && _atLeast(deno, 'deno', [2, 3])) return 'deno';
    final node = await _version('node', ['--version']);
    if (node != null && _atLeast(node, 'v', [22, 0])) return 'node';
    return null;
  }

  static bool _atLeast(String output, String prefix, List<int> wanted) {
    final match =
        RegExp('${RegExp.escape(prefix)}\\s*(\\d+)\\.(\\d+)').firstMatch(output);
    if (match == null) return false;
    final major = int.parse(match[1]!);
    final minor = int.parse(match[2]!);
    return major > wanted[0] || (major == wanted[0] && minor >= wanted[1]);
  }

  static Future<String?> _version(String program, List<String> args) async {
    try {
      final result = await runQuietly(program, args,
          timeout: const Duration(seconds: 10));
      final out = result.stdout.trim();
      if (result.exitCode != null && result.exitCode != 0) return null;
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }

  /// Rough download sizes, for the consent prompt.
  static const downloadSizes = {DjTool.ytDlp: '18 MB', DjTool.jsRuntime: '45 MB'};

  /// Downloads what is [missing]. [onProgress] gets the tool being fetched
  /// and how far along it is (0..1, null while unknown).
  Future<DjToolPaths> install(
      {void Function(DjTool tool, double? progress)? onProgress,
      DjDownloadCancel? cancel}) async {
    final dir = await directory;
    final missing = await this.missing();
    if (missing.contains(DjTool.ytDlp)) {
      final target = File(p.join(dir.path, 'yt-dlp$_exe'));
      await _download(_ytDlpUrl(), target,
          (progress) => onProgress?.call(DjTool.ytDlp, progress), cancel);
      await _makeExecutable(target.path);
    }
    if (missing.contains(DjTool.jsRuntime)) {
      final zip = File(p.join(dir.path, 'deno.zip'));
      await _download(await _denoUrl(), zip,
          (progress) => onProgress?.call(DjTool.jsRuntime, progress), cancel);
      onProgress?.call(DjTool.jsRuntime, null);
      // Unpacked aside and moved in whole: a half-written deno would pass
      // for a working one.
      final unpacked = Directory(p.join(dir.path, 'deno-unpack'));
      if (await unpacked.exists()) await unpacked.delete(recursive: true);
      await extractFileToDisk(zip.path, unpacked.path);
      await zip.delete();
      final binary = File(p.join(unpacked.path, 'deno$_exe'));
      if (!await binary.exists()) {
        throw StateError("Deno's download had no program in it");
      }
      final target = File(p.join(dir.path, 'deno$_exe'));
      if (await target.exists()) await target.delete();
      await binary.rename(target.path);
      await unpacked.delete(recursive: true);
      await _makeExecutable(target.path);
    }
    final paths = await locate(refresh: true);
    if (paths == null) {
      throw StateError('The DJ tools could not be set up');
    }
    return paths;
  }

  static const _ytDlpReleases =
      'https://github.com/yt-dlp/yt-dlp/releases/latest/download';
  static const _denoReleases =
      'https://github.com/denoland/deno/releases/latest/download';

  static bool get _arm => Platform.version.contains('arm64');

  String _ytDlpUrl() {
    if (Platform.isWindows) return '$_ytDlpReleases/yt-dlp.exe';
    return _arm
        ? '$_ytDlpReleases/yt-dlp_linux_aarch64'
        : '$_ytDlpReleases/yt-dlp_linux';
  }

  Future<String> _denoUrl() async {
    if (Platform.isWindows) {
      return '$_denoReleases/deno-x86_64-pc-windows-msvc.zip';
    }
    return _arm
        ? '$_denoReleases/deno-aarch64-unknown-linux-gnu.zip'
        : '$_denoReleases/deno-x86_64-unknown-linux-gnu.zip';
  }

  static Future<void> _makeExecutable(String path) async {
    if (Platform.isWindows) return;
    await Process.run('chmod', ['+x', path]);
  }

  static Future<void> _download(String url, File target,
      void Function(double?) onProgress, DjDownloadCancel? cancel) async {
    final client = http.Client();
    cancel?._client = client;
    final part = File('${target.path}.part');
    try {
      final response = await client
          .send(http.Request('GET', Uri.parse(url)))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw HttpException('Download failed (${response.statusCode})',
            uri: Uri.parse(url));
      }
      final total = response.contentLength;
      var received = 0;
      final sink = part.openWrite();
      try {
        // A stall is an error, not a wait without end.
        await for (final chunk
            in response.stream.timeout(const Duration(seconds: 30))) {
          if (cancel?.cancelled ?? false) throw const DjDownloadCancelled();
          sink.add(chunk);
          received += chunk.length;
          onProgress(total != null && total > 0 ? received / total : null);
        }
      } finally {
        await sink.close();
      }
      if (cancel?.cancelled ?? false) throw const DjDownloadCancelled();
      if (await target.exists()) await target.delete();
      await part.rename(target.path);
    } on TimeoutException {
      throw const HttpException('The download stalled');
    } catch (e) {
      // Closing the client to cancel surfaces as a connection error.
      if (cancel?.cancelled ?? false) throw const DjDownloadCancelled();
      rethrow;
    } finally {
      client.close();
      if (await part.exists()) await part.delete();
    }
  }

  bool _updating = false;

  /// Keeps the managed yt-dlp current, at most once a day.
  void _updateInBackground(DjToolPaths paths) {
    if (!paths.managedYtDlp || _updating) return;
    final last = DateTime.fromMillisecondsSinceEpoch(
        preferences.djToolsLastUpdate.value.toInt());
    if (DateTime.now().difference(last) < const Duration(days: 1)) return;
    _updating = true;
    runQuietly(paths.ytDlp, ['-U'], timeout: const Duration(minutes: 3))
        .then((result) {
      Log.i('DJ booth: yt-dlp update: ${result.stdout.trim()}');
      preferences.djToolsLastUpdate
          .set(DateTime.now().millisecondsSinceEpoch.toDouble());
    }).catchError((Object e, StackTrace s) {
      Log.onError(e, s, content: 'DJ booth: could not update yt-dlp');
    }).whenComplete(() => _updating = false);
  }
}
