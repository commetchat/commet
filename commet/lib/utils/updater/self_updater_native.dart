// Desktop: download the release archive, check it, unpack it beside the
// install, and leave a script to put it in place once we are gone.
//
// The swap is a rename, not a copy over the top: a half-written install is
// the one outcome worth ruling out. The old directory is moved aside first
// and moved back if the new one will not go in, so a failure leaves the
// build that was already working.
import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/updater/self_updater.dart';
import 'package:commet/utils/updater/update_release.dart';
import 'package:commet/utils/update_checker.dart';
import 'package:commet/utils/windows_hidden_process.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

SelfUpdater createSelfUpdater() => NativeSelfUpdater();

/// Directories an update must not touch, because something else owns what is
/// in them. A flatpak is read only at `/app`, and a .deb or a distro package
/// lives under `/usr`.
const _managedPrefixes = ['/usr/', '/app/', '/snap/', '/nix/store/'];

/// Whether a build living at [executable] is ours to replace.
///
/// Pulled out so it can be tested without an install to point at.
bool isSelfInstallable(String platform, String executable) {
  if (platform != 'windows' && platform != 'linux') return false;
  final path = executable.replaceAll('\\', '/');
  return !_managedPrefixes.any(path.startsWith);
}

/// Unpacks [archive] into [into].
///
/// The system's own tar first: `archive`'s pure Dart gzip and tar take about
/// three minutes over a release build, against a second or two for the tool
/// every desktop already has (Windows has shipped bsdtar, which reads zip
/// too, since Windows 10 1803). The Dart one is kept for whatever does not
/// have it, slow but working.
Future<void> unpack(File archive, Directory into) async {
  try {
    final tar =
        await _runQuietly('tar', ['-xf', archive.path, '-C', into.path]);
    if (tar == 0) return;
    Log.w('Update: tar exited $tar, unpacking in Dart instead');
  } catch (e, s) {
    Log.onError(e, s, content: 'Update: no system tar, unpacking in Dart');
  }
  // Leaves nothing half written for the Dart pass to trip over.
  for (final entry in into.listSync()) {
    entry.deleteSync(recursive: true);
  }
  await extractFileToDisk(archive.path, into.path);
}

Future<int> _runQuietly(String executable, List<String> arguments) async {
  if (!Platform.isWindows) {
    final result = await Process.run(executable, arguments);
    return result.exitCode;
  }
  // No console window for the user to watch flash past.
  final process = await startWindowsHidden(executable, arguments);
  return process.exitCode.timeout(const Duration(minutes: 5));
}

/// The one directory an archive holds, which is the new install.
///
/// `ci.yml` packs `roscord-<tag>-<platform>-x64-<mode>/` and nothing else.
/// Anything else is not an archive we made, and is refused rather than
/// guessed at.
Directory? singleRootOf(Directory unpacked) {
  final entries = unpacked.listSync();
  if (entries.length != 1) return null;
  final only = entries.first;
  return only is Directory ? only : null;
}

/// Where an update goes, worked out from where the running build is.
class UpdateTarget {
  const UpdateTarget(
      {required this.install, required this.workRoot, this.shortcut});

  /// The directory the new build takes the place of. It may not exist yet
  /// (a build that is moving somewhere lasting).
  final String install;

  /// [updateDirName] beside [install]: downloads are unpacked in there, so
  /// putting one in place is a rename, and the swap clears all of it,
  /// whatever earlier attempts left behind.
  final String workRoot;

  /// A Start menu shortcut to point at the new build, for one that moved.
  final String? shortcut;

  bool get moves => shortcut != null;
}

/// Name of the directory updates are staged in, beside the install.
const updateDirName = '.roscord-update';

/// Where the build at [executable] is updated to.
///
/// - Run from inside [updateDirName] (an earlier swap never happened and the
///   staged build was started by hand, maybe more than once, each one
///   staging the next inside itself): the install is the build left beside
///   the outermost [updateDirName], and the whole nest goes with the swap.
/// - Run from a zip opened in Explorer, which unpacks it into the temp
///   directory ([tempDir]): the update goes to `Programs\roscord` in
///   [localAppData], with a Start menu shortcut, since the next click on the
///   zip would start the old build again.
/// - Otherwise the build's own directory.
///
/// Reads the file system (the recovery looks for the build that was left
/// behind) but changes nothing, so it can be tried on directories that are
/// not an install.
UpdateTarget updateTargetFor(
  String executable, {
  required bool windows,
  required String tempDir,
  String? localAppData,
  String? startMenu,
}) {
  final context = windows ? p.windows : p.posix;
  final exeName = context.basename(executable);
  final installDir = context.dirname(executable);
  final parts = context.split(installDir);

  final nested = parts.indexOf(updateDirName);
  if (nested > 0) {
    final outer = context.joinAll(parts.take(nested));
    String? left;
    try {
      for (final entry in Directory(outer).listSync()) {
        if (entry is Directory &&
            context.basename(entry.path) != updateDirName &&
            File(context.join(entry.path, exeName)).existsSync()) {
          left = entry.path;
          break;
        }
      }
    } catch (_) {}
    return UpdateTarget(
      install: left ?? context.join(outer, parts.last),
      workRoot: context.join(outer, updateDirName),
    );
  }

  if (windows &&
      localAppData != null &&
      startMenu != null &&
      context.isWithin(tempDir, installDir)) {
    final programs = context.join(localAppData, 'Programs');
    return UpdateTarget(
      install: context.join(programs, 'roscord'),
      workRoot: context.join(programs, updateDirName),
      shortcut: context.join(startMenu, 'roscord.lnk'),
    );
  }

  return UpdateTarget(
    install: installDir,
    workRoot: context.join(context.dirname(installDir), updateDirName),
  );
}

class NativeSelfUpdater implements SelfUpdater {
  @override
  final ValueNotifier<UpdateProgress> progress =
      ValueNotifier(const UpdateProgress(UpdateStage.idle));

  /// Unpacked and waiting for the app to close.
  Directory? _staged;
  bool _running = false;

  /// Not a bool: a macOS build that called itself linux would pass
  /// [isSelfInstallable] and then download the Linux tarball.
  String get _platform => Platform.isWindows
      ? 'windows'
      : Platform.isMacOS
          ? 'macos'
          : 'linux';

  late final UpdateTarget _target = updateTargetFor(
    File(Platform.resolvedExecutable).absolute.path,
    windows: Platform.isWindows,
    tempDir: Directory.systemTemp.absolute.path,
    localAppData: Platform.environment['LOCALAPPDATA'],
    startMenu: Platform.environment['APPDATA'] == null
        ? null
        : p.join(Platform.environment['APPDATA']!, 'Microsoft', 'Windows',
            'Start Menu', 'Programs'),
  );

  /// What the swap clears up after itself: [UpdateTarget.workRoot], or the
  /// temp directory's when that could not be written.
  String? _workRoot;

  @override
  bool get canInstall =>
      UpdateChecker.shouldCheckForUpdates &&
      isSelfInstallable(_platform, Platform.resolvedExecutable);

  void _set(UpdateStage stage,
          {UpdateRelease? release, double? fraction, String? message}) =>
      progress.value = UpdateProgress(stage,
          release: release ?? progress.value.release,
          fraction: fraction,
          message: message);

  @override
  Future<void> checkAndPrepare() async {
    if (_running) return;
    _running = true;
    try {
      _set(UpdateStage.checking);
      final release =
          await UpdateRelease.fetchLatest(UpdateChecker.releasesApiUrl);
      if (release == null) {
        _set(UpdateStage.failed,
            message: 'Could not reach GitHub to look for updates.');
        return;
      }
      if (!UpdateChecker.isNewer(release.tag, BuildConfig.VERSION_TAG)) {
        _set(UpdateStage.upToDate,
            release: release,
            message: 'roscord ${BuildConfig.VERSION_TAG} is the latest.');
        return;
      }
      if (!canInstall) {
        // Nothing to do but point at the download, as before.
        _set(UpdateStage.available, release: release);
        return;
      }
      await _prepare(release);
    } catch (e, s) {
      Log.onError(e, s, content: 'Update: could not prepare');
      _set(UpdateStage.failed, message: 'The update could not be prepared.');
    } finally {
      _running = false;
    }
  }

  Future<void> _prepare(UpdateRelease release) async {
    final asset = release.assetFor(_platform);
    if (asset == null) {
      _set(UpdateStage.available,
          release: release,
          message: 'That release has no build for this platform.');
      return;
    }
    if (asset.sha256 == null) {
      // Without a checksum there is no way to know what arrived, and this
      // unpacks over the app: the browser can have this one.
      _set(UpdateStage.available,
          release: release,
          message: 'That release is not checksummed, so it has to be '
              'installed by hand.');
      return;
    }

    await discard();
    // Beside the install, so putting it in place is a rename and not a copy
    // across filesystems. Falls back to the temp directory when the parent
    // is not ours to write in.
    final work = await _workDirectory(release.tag);
    try {
      final archive = File(p.join(work.path, asset.name));
      _set(UpdateStage.downloading, release: release, fraction: 0);
      await _download(asset, archive);

      _set(UpdateStage.verifying, release: release);
      final digest = await sha256.bind(archive.openRead()).first;
      final got = digest.toString();
      if (got != asset.sha256) {
        throw StateError('checksum is $got, expected ${asset.sha256}');
      }

      _set(UpdateStage.unpacking, release: release);
      final unpacked = Directory(p.join(work.path, 'unpacked'));
      await unpacked.create(recursive: true);
      await unpack(archive, unpacked);
      await archive.delete();

      final root = singleRootOf(unpacked);
      if (root == null) {
        throw StateError('the archive does not hold one directory');
      }
      if (!await File(p.join(root.path, _executableName)).exists()) {
        throw StateError('no $_executableName in the archive');
      }
      _staged = root;
      _set(UpdateStage.ready,
          release: release,
          message: _target.moves
              ? '${release.tag} is ready. Restarting moves roscord to '
                  '${_target.install}, with a Start menu shortcut, so it no '
                  'longer runs from the zip.'
              : null);
      Log.i('Update: ${release.tag} is unpacked at ${root.path}');
    } catch (e, s) {
      Log.onError(e, s, content: 'Update: could not stage ${release.tag}');
      await _delete(work);
      _set(UpdateStage.failed,
          release: release,
          message: 'The update could not be downloaded. '
              'You can still install it from the release page.');
    }
  }

  String get _executableName => p.basename(Platform.resolvedExecutable);

  /// A fresh directory for [tag] under the work root. Fresh, because the
  /// root may hold what earlier attempts left (the running build, even).
  Future<Directory> _workDirectory(String tag) async {
    Future<Directory> fresh(String root) async {
      final work = Directory(p.join(root, tag));
      if (await work.exists()) await work.delete(recursive: true);
      await work.create(recursive: true);
      // Writable in practice, not only on paper.
      final probe = File(p.join(work.path, '.probe'));
      await probe.writeAsString('');
      await probe.delete();
      _workRoot = root;
      return work;
    }

    try {
      return await fresh(_target.workRoot);
    } catch (_) {
      return fresh(p.join(Directory.systemTemp.path, 'roscord-update'));
    }
  }

  Future<void> _download(UpdateAsset asset, File target) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(asset.url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}', uri: request.uri);
      }
      final total = response.contentLength > 0
          ? response.contentLength
          : (asset.size > 0 ? asset.size : 0);
      var received = 0;
      final sink = target.openWrite();
      try {
        await for (final chunk
            in response.timeout(const Duration(seconds: 60))) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) {
            _set(UpdateStage.downloading, fraction: received / total);
          }
        }
      } finally {
        await sink.close();
      }
    } finally {
      client.close();
    }
  }

  @override
  Future<bool> installAndRestart() async {
    final staged = _staged;
    if (staged == null || !await staged.exists()) return false;
    try {
      final script = await _writeSwapScript(staged);
      await startSwapScript(script);
      Log.i('Update: handed the swap to ${script.path}');
      return true;
    } catch (e, s) {
      Log.onError(e, s, content: 'Update: could not start the installer');
      _set(UpdateStage.failed,
          message: 'The update could not be started. Nothing was changed.');
      return false;
    }
  }

  @override
  Future<void> discard() async {
    final staged = _staged;
    _staged = null;
    if (staged == null) return;
    // The whole working directory, not only what was unpacked.
    await _delete(staged.parent.parent);
  }

  Future<void> _delete(Directory dir) async {
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (e, s) {
      Log.onError(e, s, content: 'Update: could not clean up ${dir.path}');
    }
  }

  Future<File> _writeSwapScript(Directory staged) async {
    final install = _target.install;
    final exe = p.join(install, _executableName);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final work = staged.parent.parent;
    final workRoot = _workRoot ?? work.path;
    final script = File(
        p.join(work.path, Platform.isWindows ? 'install.ps1' : 'install.sh'));
    await script.writeAsString(Platform.isWindows
        ? windowsSwapScript(
            waitFor: pid,
            staged: staged.path,
            install: install,
            exe: exe,
            work: workRoot,
            stamp: stamp,
            shortcut: _target.shortcut,
            restart: Platform.resolvedExecutable)
        : linuxSwapScript(
            waitFor: pid,
            staged: staged.path,
            install: install,
            exe: exe,
            work: workRoot,
            stamp: stamp));
    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', script.path]);
    }
    return script;
  }
}

/// Starts the swap [script] so that it outlives the app.
///
/// In the temp directory, never the app's working directory: that is
/// usually the install itself (Explorer starts a program in its own folder),
/// and Windows will not rename a directory a process is working in. The
/// script inheriting it kept every swap on Windows from happening.
Future<void> startSwapScript(File script) async {
  final outside = Directory.systemTemp.path;
  if (Platform.isWindows) {
    // No console window: this outlives the app and the user should not
    // see a terminal flash up as it closes.
    await startWindowsHidden(
        'powershell.exe',
        [
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-WindowStyle',
          'Hidden',
          '-File',
          script.path,
        ],
        workingDirectory: outside);
  } else {
    await Process.start('/bin/sh', [script.path],
        mode: ProcessStartMode.detached, workingDirectory: outside);
  }
}

/// Single-quoted for PowerShell, where a quote is doubled to escape it.
String _ps(String value) => "'${value.replaceAll("'", "''")}'";

/// Single-quoted for the shell, where a quote ends the string, is escaped,
/// and the string starts again.
String _sh(String value) => "'${value.replaceAll("'", r"'\''")}'";

/// Swaps [install] for [staged] once the process [waitFor] is gone, starts
/// [exe] and clears up. The old install is moved aside first and moved back
/// if the new one will not go in, so a failure leaves what was working.
///
/// Pulled out of the updater so the scripts can be read, and run against a
/// directory that is not an install, in tests.
///
/// [install] need not exist (a build moving out of the temp directory);
/// [shortcut], when given, is a Start menu shortcut made to point at [exe].
/// When the swap fails, [restart] (the build that was running) is started
/// again, so restarting to update never leaves roscord closed. What
/// happened goes in `install-<stamp>.log` in [work], which is only cleared
/// when the swap worked.
String windowsSwapScript({
  required int waitFor,
  required String staged,
  required String install,
  required String exe,
  required String work,
  required int stamp,
  String? shortcut,
  String? restart,
}) =>
    '''
\$ErrorActionPreference = 'Stop'
\$work = ${_ps(work)}
\$log  = Join-Path \$work 'install-$stamp.log'
function Say(\$what) {
  Add-Content -LiteralPath \$log -Value "\$(Get-Date -Format o) \$what" -ErrorAction SilentlyContinue
}
# Out of every directory this moves or deletes: Windows will not rename a
# directory some process, this one included, is working in.
Set-Location -LiteralPath ([System.IO.Path]::GetTempPath())

# Wait for roscord to go: its directory cannot be renamed while it runs.
Say 'waiting for roscord (process $waitFor) to close'
\$deadline = (Get-Date).AddSeconds(60)
while ((Get-Process -Id $waitFor -ErrorAction SilentlyContinue) -and
       ((Get-Date) -lt \$deadline)) {
  Start-Sleep -Milliseconds 200
}

# A rename, whole or not at all. Move-Item is not that: when a file inside
# is busy it moves the rest one by one and leaves half an install behind.
# The directory can stay busy for a moment after roscord has gone (its
# browser helpers closing, a virus scanner looking at the new files), so
# the rename is tried again for a while.
function Rename-Patiently(\$from, \$to) {
  \$until = (Get-Date).AddSeconds(30)
  while (\$true) {
    try {
      [System.IO.Directory]::Move(\$from, \$to)
      return
    } catch {
      if ((Get-Date) -ge \$until) { throw }
      Start-Sleep -Milliseconds 500
    }
  }
}

\$install = ${_ps(install)}
\$staged  = ${_ps(staged)}
\$old     = ${_ps('$install.old-$stamp')}
try {
  \$hadOld = Test-Path -LiteralPath \$install
  if (\$hadOld) {
    Rename-Patiently \$install \$old
  } else {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent \$install) | Out-Null
  }
  try {
    if ([System.IO.Path]::GetPathRoot(\$staged) -eq [System.IO.Path]::GetPathRoot(\$install)) {
      Rename-Patiently \$staged \$install
    } else {
      # Staged on another drive (the install's own could not be written
      # to): a copy, which is not whole until it has finished.
      Copy-Item -LiteralPath \$staged -Destination \$install -Recurse
    }
  } catch {
    # Put back what was working and leave the update where it is.
    if (Test-Path -LiteralPath \$install) {
      Remove-Item -LiteralPath \$install -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (\$hadOld) { [System.IO.Directory]::Move(\$old, \$install) }
    throw
  }
} catch {
  Say "the swap failed: \$_"
${restart == null ? '' : '  Start-Process -FilePath ${_ps(restart)} -WorkingDirectory (Split-Path -Parent ${_ps(restart)})\n'}  exit 1
}
Say 'swapped'
${shortcut == null ? '' : '''try {
  \$link = (New-Object -ComObject WScript.Shell).CreateShortcut(${_ps(shortcut)})
  \$link.TargetPath = ${_ps(exe)}
  \$link.WorkingDirectory = \$install
  \$link.Save()
} catch {
  Say "no Start menu shortcut: \$_"
}
'''}Start-Process -FilePath ${_ps(exe)} -WorkingDirectory \$install
Remove-Item -LiteralPath \$old -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath \$work -Recurse -Force -ErrorAction SilentlyContinue
''';

String linuxSwapScript({
  required int waitFor,
  required String staged,
  required String install,
  required String exe,
  required String work,
  required int stamp,
}) =>
    '''
#!/bin/sh
# Wait for roscord to go, so the new build does not start beside the old one.
i=0
while [ \$i -lt 300 ] && kill -0 $waitFor 2>/dev/null; do
  sleep 0.2
  i=\$((i + 1))
done
# Unlike Windows, a directory here can be moved out from under a running
# program. Waiting out rather than swapping under it: two roscords sharing
# one account is worse than an update that did not happen.
if kill -0 $waitFor 2>/dev/null; then
  exit 1
fi
install=${_sh(install)}
staged=${_sh(staged)}
old=${_sh('$install.old-$stamp')}
# The install may not be there: a recovered one can be moving out of the
# staging directory it was run from.
if [ -e "\$install" ]; then
  mv "\$install" "\$old" || exit 1
else
  mkdir -p "\$(dirname "\$install")" || exit 1
fi
if ! mv "\$staged" "\$install"; then
  [ -e "\$old" ] && mv "\$old" "\$install"
  exit 1
fi
(cd "\$install" && exec ${_sh(exe)}) &
# Last, and from outside it: this script lives in there.
cd /
rm -rf "\$old" ${_sh(work)}
''';
