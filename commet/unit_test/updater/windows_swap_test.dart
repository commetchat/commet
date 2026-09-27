// The Windows swap, run for real against directories that are not an
// install, the way the app starts it: from a process whose working
// directory is the install, as Explorer leaves it. That is what kept every
// swap from happening before the script was started elsewhere.
//
// The stand-in for roscord is a .vbs, which Windows hands to wscript: a
// program that starts without a window and writes a file to say it ran.
@TestOn('windows')
library;

import 'dart:io';

import 'package:commet/utils/updater/self_updater_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// A pid that has already exited, so the wait falls straight through.
Future<int> deadPid() async {
  final process = await Process.run('cmd', ['/c', 'exit 0']);
  return process.pid;
}

/// A build: `which` says which one, and `commet.vbs` writes [ran] when
/// started.
Directory buildDir(String path, String marker, String ran) {
  final dir = Directory(path)..createSync(recursive: true);
  File(p.join(dir.path, 'which')).writeAsStringSync(marker);
  File(p.join(dir.path, 'commet.vbs')).writeAsStringSync(
      'CreateObject("Scripting.FileSystemObject")'
      '.CreateTextFile("$ran").Close\r\n');
  return dir;
}

Future<void> until(bool Function() done, {int seconds = 60}) async {
  for (var i = 0; i < seconds * 10 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

void main() {
  late Directory root;
  late Directory before;

  setUp(() {
    root = Directory.systemTemp.createTempSync('roscord-swap-');
    before = Directory.current;
  });
  tearDown(() async {
    Directory.current = before;
    for (var i = 0; i < 50 && root.existsSync(); i++) {
      try {
        root.deleteSync(recursive: true);
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }
  });

  Future<File> writeScript(
    Directory work, {
    required String install,
    required String staged,
    String? shortcut,
    String? restart,
  }) async {
    final script = File(p.join(work.path, 'install.ps1'));
    script.writeAsStringSync(windowsSwapScript(
      waitFor: await deadPid(),
      staged: staged,
      install: install,
      exe: p.join(install, 'commet.vbs'),
      work: work.path,
      stamp: 1234,
      shortcut: shortcut,
      restart: restart,
    ));
    return script;
  }

  test('swaps even though the app works in the install, and starts it',
      () async {
    final ran = p.join(root.path, 'ran');
    final install =
        buildDir(p.join(root.path, 'roscord-v1', 'roscord-v1'), 'old', ran);
    final work = Directory(p.join(root.path, 'roscord-v1', '.roscord-update'));
    final staged = buildDir(
        p.join(work.path, 'v2', 'unpacked', 'roscord-v2'), 'new', ran);
    final script =
        await writeScript(work, install: install.path, staged: staged.path);

    // As the app is when started from Explorer.
    Directory.current = install;
    await startSwapScript(script);
    Directory.current = before;

    await until(() => File(ran).existsSync() && !work.existsSync());
    expect(File(p.join(install.path, 'which')).readAsStringSync(), 'new');
    expect(File(ran).existsSync(), isTrue, reason: 'the new build started');
    expect(Directory('${install.path}.old-1234').existsSync(), isFalse);
    expect(work.existsSync(), isFalse);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('waits for the install to stop being busy', () async {
    final ran = p.join(root.path, 'ran');
    final install = buildDir(p.join(root.path, 'roscord'), 'old', ran);
    final work = Directory(p.join(root.path, '.roscord-update'));
    final staged =
        buildDir(p.join(work.path, 'v2', 'unpacked', 'roscord'), 'new', ran);
    final script =
        await writeScript(work, install: install.path, staged: staged.path);

    // A file held open inside it, as a helper still closing would.
    final held = File(p.join(install.path, 'which')).openSync();
    await startSwapScript(script);
    await Future<void>.delayed(const Duration(seconds: 4));
    // Whole, not half moved: a rename that can't happen doesn't start.
    expect(File(p.join(install.path, 'commet.vbs')).existsSync(), isTrue,
        reason: 'nothing moves while it is busy');
    expect(Directory('${install.path}.old-1234').existsSync(), isFalse);
    held.closeSync();

    await until(() => File(ran).existsSync());
    expect(File(p.join(install.path, 'which')).readAsStringSync(), 'new');
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('a failed swap puts back what worked, starts it again and says why',
      () async {
    final ran = p.join(root.path, 'ran');
    final restarted = p.join(root.path, 'restarted');
    final install = buildDir(p.join(root.path, 'roscord'), 'old', restarted);
    final work = Directory(p.join(root.path, '.roscord-update'))
      ..createSync();
    final script = await writeScript(work,
        install: install.path,
        // Never unpacked: the move cannot succeed.
        staged: p.join(work.path, 'v2', 'unpacked', 'not-there'),
        restart: p.join(install.path, 'commet.vbs'));

    await startSwapScript(script);

    await until(() => File(restarted).existsSync(), seconds: 90);
    expect(File(restarted).existsSync(), isTrue,
        reason: 'the working build was started again');
    expect(File(ran).existsSync(), isFalse);
    expect(File(p.join(install.path, 'which')).readAsStringSync(), 'old');
    final log = File(p.join(work.path, 'install-1234.log'));
    expect(log.readAsStringSync(), contains('the swap failed'));
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('a build moving somewhere new gets there, with a shortcut', () async {
    final ran = p.join(root.path, 'ran');
    final programs = p.join(root.path, 'Local', 'Programs');
    final install = p.join(programs, 'roscord');
    final work = Directory(p.join(programs, '.roscord-update'));
    final staged =
        buildDir(p.join(work.path, 'v2', 'unpacked', 'roscord-v2'), 'new', ran);
    final shortcut = p.join(root.path, 'Start', 'roscord.lnk');
    Directory(p.dirname(shortcut)).createSync(recursive: true);
    final script = await writeScript(work,
        install: install, staged: staged.path, shortcut: shortcut);

    await startSwapScript(script);

    await until(() => File(ran).existsSync() && !work.existsSync());
    expect(File(p.join(install, 'which')).readAsStringSync(), 'new');
    expect(File(shortcut).existsSync(), isTrue);
    expect(work.existsSync(), isFalse);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test("a path with a quote in it doesn't break the script", () async {
    final odd = p.join(root.path, "it's here");
    final ran = p.join(root.path, 'ran');
    final install = buildDir(p.join(odd, 'roscord'), 'old', ran);
    final work = Directory(p.join(odd, '.roscord-update'));
    final staged =
        buildDir(p.join(work.path, 'v2', 'unpacked', 'roscord'), 'new', ran);
    final script =
        await writeScript(work, install: install.path, staged: staged.path);

    await startSwapScript(script);

    await until(() => File(ran).existsSync());
    expect(File(p.join(install.path, 'which')).readAsStringSync(), 'new');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
