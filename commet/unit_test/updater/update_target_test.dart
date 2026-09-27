// Where an update goes, from where the running build is: its own directory,
// the build left behind when it was started from the staging directory, or
// somewhere lasting when it runs out of a zip Explorer unpacked into temp.
import 'dart:io';

import 'package:commet/utils/updater/self_updater_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  final exe = Platform.isWindows ? 'commet.exe' : 'commet';

  setUp(() => root = Directory.systemTemp.createTempSync('roscord-target-'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  Directory build(String path) {
    final dir = Directory(p.join(root.path, path))..createSync(recursive: true);
    File(p.join(dir.path, exe)).writeAsStringSync('');
    return dir;
  }

  UpdateTarget targetOf(Directory dir, {String? tempDir}) => updateTargetFor(
        p.join(dir.path, exe),
        windows: Platform.isWindows,
        tempDir: tempDir ?? p.join(root.path, 'no-temp-here'),
        localAppData: p.join(root.path, 'local'),
        startMenu: p.join(root.path, 'start'),
      );

  test('a build is updated where it is, staged beside itself', () {
    final install = build(p.join('Downloads', 'roscord-v1', 'roscord-v1'));
    final target = targetOf(install);
    expect(target.install, install.path);
    expect(target.workRoot,
        p.join(root.path, 'Downloads', 'roscord-v1', '.roscord-update'));
    expect(target.moves, isFalse);
  });

  test('run from the staging directory, the build left behind is replaced',
      () {
    // The swap to v2 never happened; v2 was started from where it was
    // staged, and staged v3 inside itself, and v3 was started from there.
    final outer = p.join('Downloads', 'roscord-v1');
    final left = build(p.join(outer, 'roscord-v1'));
    final v3 = build(p.join(outer, '.roscord-update', 'unpacked',
        '.roscord-update', 'unpacked', 'roscord-v3'));

    final target = targetOf(v3);
    expect(target.install, left.path);
    // The outermost staging directory: the whole nest goes with the swap.
    expect(target.workRoot, p.join(root.path, outer, '.roscord-update'));
    expect(target.moves, isFalse);
  });

  test('run from staging with nothing left behind, it moves out beside it',
      () {
    final staged =
        build(p.join('here', '.roscord-update', 'v2', 'unpacked', 'roscord'));
    final target = targetOf(staged);
    expect(target.install, p.join(root.path, 'here', 'roscord'));
    expect(target.workRoot, p.join(root.path, 'here', '.roscord-update'));
  });

  test('run out of a zip Explorer unpacked into temp, it moves somewhere lasting',
      () {
    final temp = p.join(root.path, 'Temp');
    final inZip = build(p.join('Temp', 'Temp1_roscord-v1.zip', 'roscord-v1'));
    final target = targetOf(inZip, tempDir: temp);
    if (!Platform.isWindows) {
      // Only Windows opens zips that way.
      expect(target.install, inZip.path);
      return;
    }
    expect(target.install, p.join(root.path, 'local', 'Programs', 'roscord'));
    expect(target.workRoot,
        p.join(root.path, 'local', 'Programs', '.roscord-update'));
    expect(target.shortcut, p.join(root.path, 'start', 'roscord.lnk'));
    expect(target.moves, isTrue);
  });

  test('the Windows rules on Windows paths', () {
    final target = updateTargetFor(
      r'C:\Users\a\AppData\Local\Temp\Temp1_roscord.zip\roscord\commet.exe',
      windows: true,
      tempDir: r'C:\Users\a\AppData\Local\Temp',
      localAppData: r'C:\Users\a\AppData\Local',
      startMenu: r'C:\Users\a\AppData\Roaming\Microsoft\Windows\Start Menu\Programs',
    );
    expect(target.install, r'C:\Users\a\AppData\Local\Programs\roscord');
    expect(target.shortcut,
        r'C:\Users\a\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\roscord.lnk');

    final plain = updateTargetFor(r'D:\apps\roscord\commet.exe',
        windows: true,
        tempDir: r'C:\Users\a\AppData\Local\Temp',
        localAppData: r'C:\Users\a\AppData\Local',
        startMenu: r'C:\start');
    expect(plain.install, r'D:\apps\roscord');
    expect(plain.workRoot, r'D:\apps\.roscord-update');
    expect(plain.moves, isFalse);
  });
}
