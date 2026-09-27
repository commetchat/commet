// Programs the DJ booth runs (source extensions), started without a console
// window flashing up on Windows.
import 'dart:async';
import 'dart:io';

import 'package:commet/utils/windows_hidden_process.dart';

/// A program the booth is running, however it was started.
abstract class QuietProcess {
  Stream<List<int>> get stdout;
  Stream<List<int>> get stderr;
  Future<int> get exitCode;
  void kill();
}

/// Runs a program without a console window flashing up on Windows, where a
/// child of a GUI app gets one of its own unless it is told otherwise
/// ([startWindowsHidden]). Elsewhere a child is just a child.
Future<QuietProcess> startQuietly(String executable, List<String> arguments,
    {String? workingDirectory}) async {
  if (Platform.isWindows) {
    return _HiddenQuietProcess(await startWindowsHidden(executable, arguments,
        workingDirectory: workingDirectory));
  }
  final process = await Process.start(executable, arguments,
      workingDirectory: workingDirectory);
  // Nothing is written to it: the program sees its end straight away.
  unawaited(process.stdin.close().catchError((_) {}));
  return _DartQuietProcess(process);
}

class _DartQuietProcess implements QuietProcess {
  _DartQuietProcess(this._process);

  final Process _process;

  @override
  Stream<List<int>> get stdout => _process.stdout;
  @override
  Stream<List<int>> get stderr => _process.stderr;
  @override
  Future<int> get exitCode => _process.exitCode;
  @override
  void kill() => _process.kill();
}

class _HiddenQuietProcess implements QuietProcess {
  _HiddenQuietProcess(this._process);

  final WindowsHiddenProcess _process;

  @override
  Stream<List<int>> get stdout => _process.stdout;
  @override
  Stream<List<int>> get stderr => _process.stderr;
  @override
  Future<int> get exitCode => _process.exitCode;
  @override
  void kill() => _process.kill();
}
