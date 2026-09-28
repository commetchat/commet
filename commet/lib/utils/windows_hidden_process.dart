// Runs a program on Windows without a console window flashing up, for the
// DJ booth's source extensions (docs/dj-extensions.md).
//
// Dart has no say over how a child process is given a console. Started
// normally from a GUI app, a console program gets its own console window;
// started detached (`ProcessStartMode.detachedWithStdio`) it gets none, but
// then whatever *it* starts gets a fresh one instead. An extension is often
// a script runtime that starts other console programs in turn, and on
// Windows 11 each fresh console is a Terminal window, which ignores any
// hidden-window hint a program asks for.
//
// `CREATE_NO_WINDOW` is the flag that gives a child a console with no window
// of its own, which its own children then inherit, so nothing in the tree
// ever shows one. Dart cannot pass it, hence CreateProcessW here.
//
// The program also starts in a job object of its own, so killing it ends
// everything it started too. Windows ends only the process it is told to,
// and a runtime that ends its own children on the way out doesn't reach
// theirs: yt-dlp.exe, say, is a launcher whose Python child would go on
// downloading. The job doesn't kill on close, so what outlives a program
// that ended normally (an updater it left running) is left alone.
//
// Output goes to files in a temporary directory rather than pipes: reading a
// pipe means a blocking read on a thread of its own, and nothing here needs
// what a program says sooner than the next poll.
import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

/// A program started by [startWindowsHidden], shaped like [Process].
class WindowsHiddenProcess {
  WindowsHiddenProcess._(this._handle, this._job, this.pid, this._directory) {
    unawaited(_pump());
  }

  final int _handle;

  /// The job the program and everything it starts run in; 0 without one.
  final int _job;
  final int pid;
  final Directory _directory;

  final StreamController<List<int>> _stdout = StreamController<List<int>>();
  final StreamController<List<int>> _stderr = StreamController<List<int>>();
  final Completer<int> _exit = Completer<int>();
  bool _killed = false;

  Stream<List<int>> get stdout => _stdout.stream;
  Stream<List<int>> get stderr => _stderr.stream;
  Future<int> get exitCode => _exit.future;

  /// Ends the program and everything it started.
  bool kill() {
    if (_killed || _exit.isCompleted) return false;
    _killed = true;
    if (_job != 0 && _terminateJobObject(_job, 1) != 0) return true;
    return _terminateProcess(_handle, 1) != 0;
  }

  /// The program's exit code, or null while it is still running.
  int? _exitCodeNow() {
    // WAIT_OBJECT_0: it has ended. Asked before the code itself, because a
    // program may legitimately exit with STILL_ACTIVE's value.
    if (_waitForSingleObject(_handle, 0) != 0) return null;
    final code = calloc<Uint32>();
    try {
      if (_getExitCodeProcess(_handle, code) == 0) return -1;
      return code.value;
    } finally {
      calloc.free(code);
    }
  }

  Future<void> _pump() async {
    RandomAccessFile? out;
    RandomAccessFile? err;
    try {
      out = await File(p.join(_directory.path, _stdoutName)).open();
      err = await File(p.join(_directory.path, _stderrName)).open();
      var outAt = 0;
      var errAt = 0;
      while (true) {
        // Read the status first, so the last read of the files happens
        // after the program is known to be gone and nothing is missed.
        final code = _exitCodeNow();
        outAt = await _drain(out, outAt, _stdout);
        errAt = await _drain(err, errAt, _stderr);
        if (code != null) {
          _exit.complete(code);
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    } catch (e, s) {
      if (!_exit.isCompleted) _exit.completeError(e, s);
    } finally {
      await out?.close().catchError((_) {});
      await err?.close().catchError((_) {});
      _closeHandle(_handle);
      if (_job != 0) _closeHandle(_job);
      await _stdout.close();
      await _stderr.close();
      await _directory.delete(recursive: true).catchError((_) => _directory);
    }
  }

  static Future<int> _drain(
      RandomAccessFile file, int at, StreamController<List<int>> to) async {
    final length = await file.length();
    if (length <= at) return at;
    await file.setPosition(at);
    final bytes = await file.read(length - at);
    if (bytes.isNotEmpty) to.add(bytes);
    return at + bytes.length;
  }
}

const _stdoutName = 'stdout';
const _stderrName = 'stderr';

/// Starts [executable] with [arguments], with no console window anywhere in
/// the process tree. Throws [ProcessException] like [Process.start] does.
Future<WindowsHiddenProcess> startWindowsHidden(
    String executable, List<String> arguments,
    {String? workingDirectory}) async {
  final directory = await Directory.systemTemp.createTemp('roscord-run-');
  // Created here, so the child only has to open them for appending.
  final outPath = p.join(directory.path, _stdoutName);
  final errPath = p.join(directory.path, _stderrName);

  var started = false;
  try {
    return using((Arena arena) {
      final inheritable = arena<_SecurityAttributes>();
      inheritable.ref.nLength = sizeOf<_SecurityAttributes>();
      inheritable.ref.lpSecurityDescriptor = nullptr;
      inheritable.ref.bInheritHandle = 1;

      final handles = <int>[];
      int open(String path, int access, int disposition) {
        final handle = _createFileW(
            path.toNativeUtf16(allocator: arena),
            access,
            _fileShareRead | _fileShareWrite | _fileShareDelete,
            inheritable,
            disposition,
            _fileAttributeNormal,
            0);
        if (handle == _invalidHandle) {
          throw ProcessException(executable, arguments,
              'Could not open $path (error ${_getLastError()})');
        }
        handles.add(handle);
        return handle;
      }

      final info = arena<_ProcessInformation>();
      Pointer<Void> attributes = nullptr;
      var job = 0;
      try {
        // Nothing here reads from the program, but a child left with no
        // input handle at all can misbehave.
        final stdin = open('NUL', _genericRead, _openExisting);
        final stdout = open(outPath, _genericWrite, _createAlways);
        final stderr = open(errPath, _genericWrite, _createAlways);

        // Standard handles only work on a child that inherits handles, and
        // that would hand it every inheritable handle the app has open, its
        // sockets included: a ten minute download would hold a call's ports
        // long after the call. The attribute list names the three it gets.
        attributes = _attributeListFor([stdin, stdout, stderr], arena);

        final startup = arena<_StartupInfoEx>();
        final plain = startup.cast<_StartupInfo>();
        plain.ref.cb = attributes == nullptr
            ? sizeOf<_StartupInfo>()
            : sizeOf<_StartupInfoEx>();
        plain.ref.dwFlags = _startfUseStdHandles | _startfUseShowWindow;
        plain.ref.wShowWindow = _swHide;
        plain.ref.hStdInput = stdin;
        plain.ref.hStdOutput = stdout;
        plain.ref.hStdError = stderr;
        startup.ref.lpAttributeList = attributes;

        // Started suspended, so it is in the job before it can start
        // anything.
        job = _createJobObjectW(nullptr, nullptr);

        // No application name: that way the command line's first word is
        // looked up on PATH, and `.exe` appended, as Process.start does.
        final commandLine = [executable, ...arguments]
            .map(quoteWindowsArgument)
            .join(' ')
            .toNativeUtf16(allocator: arena);
        final ok = _createProcessW(
            nullptr,
            commandLine,
            nullptr,
            nullptr,
            1,
            _createNoWindow |
                (attributes == nullptr ? 0 : _extendedStartupInfoPresent) |
                (job == 0 ? 0 : _createSuspended),
            nullptr,
            workingDirectory == null
                ? nullptr
                : workingDirectory.toNativeUtf16(allocator: arena),
            plain,
            info);
        if (ok == 0) {
          final error = _getLastError();
          if (job != 0) _closeHandle(job);
          throw ProcessException(executable, arguments,
              'Could not start $executable (error $error)', error);
        }
        started = true;
        if (job != 0) {
          if (_assignProcessToJobObject(job, info.ref.hProcess) == 0) {
            _closeHandle(job);
            job = 0;
          }
          _resumeThread(info.ref.hThread);
        }
      } finally {
        if (attributes != nullptr) _deleteProcThreadAttributeList(attributes);
        // The child has its own copies; ours would keep the files open and
        // hide the end of the output.
        for (final handle in handles) {
          _closeHandle(handle);
        }
      }

      _closeHandle(info.ref.hThread);
      return WindowsHiddenProcess._(
          info.ref.hProcess, job, info.ref.dwProcessId, directory);
    });
  } finally {
    // The process owns the directory once it is running.
    if (!started) {
      await directory.delete(recursive: true).catchError((_) => directory);
    }
  }
}

/// An attribute list naming the only handles the child may inherit, or
/// nullptr if Windows would not build one, in which case the child inherits
/// every inheritable handle as it did before.
Pointer<Void> _attributeListFor(List<int> handles, Arena arena) {
  final size = arena<IntPtr>();
  // The first call only reports the size; it is expected to fail.
  _initializeProcThreadAttributeList(nullptr, 1, 0, size);
  if (size.value <= 0) return nullptr;
  final list = arena<Uint8>(size.value).cast<Void>();
  if (_initializeProcThreadAttributeList(list, 1, 0, size) == 0) {
    return nullptr;
  }
  final values = arena<IntPtr>(handles.length);
  for (var i = 0; i < handles.length; i++) {
    values[i] = handles[i];
  }
  if (_updateProcThreadAttribute(list, 0, _attributeHandleList, values.cast(),
          handles.length * sizeOf<IntPtr>(), nullptr, nullptr) ==
      0) {
    _deleteProcThreadAttributeList(list);
    return nullptr;
  }
  return list;
}

/// Quotes [argument] the way the C runtime parses a command line back into
/// arguments, which is what most programs (Deno included) use.
String quoteWindowsArgument(String argument) {
  if (argument.isNotEmpty && !argument.contains(RegExp(r'[ \t"]'))) {
    return argument;
  }
  final quoted = StringBuffer('"');
  var backslashes = 0;
  for (final unit in argument.codeUnits) {
    if (unit == 0x5c) {
      backslashes++;
      continue;
    }
    if (unit == 0x22) {
      // A quote is escaped, and the backslashes before it are doubled so
      // they are not read as escaping each other.
      quoted.write('\\' * (backslashes * 2 + 1));
      backslashes = 0;
      quoted.write('"');
      continue;
    }
    quoted.write('\\' * backslashes);
    backslashes = 0;
    quoted.writeCharCode(unit);
  }
  // The closing quote would be escaped by an odd number of them.
  quoted.write('\\' * (backslashes * 2));
  quoted.write('"');
  return quoted.toString();
}

const int _createNoWindow = 0x08000000;
const int _createSuspended = 0x00000004;
const int _extendedStartupInfoPresent = 0x00080000;
const int _attributeHandleList = 0x00020002;
const int _startfUseShowWindow = 0x00000001;
const int _startfUseStdHandles = 0x00000100;
const int _swHide = 0;
const int _genericRead = 0x80000000;
const int _genericWrite = 0x40000000;
const int _fileShareRead = 0x00000001;
const int _fileShareWrite = 0x00000002;
const int _fileShareDelete = 0x00000004;
const int _createAlways = 2;
const int _openExisting = 3;
const int _fileAttributeNormal = 0x00000080;
const int _invalidHandle = -1;

final class _SecurityAttributes extends Struct {
  @Uint32()
  external int nLength;
  external Pointer<Void> lpSecurityDescriptor;
  @Int32()
  external int bInheritHandle;
}

final class _StartupInfo extends Struct {
  @Uint32()
  external int cb;
  external Pointer<Utf16> lpReserved;
  external Pointer<Utf16> lpDesktop;
  external Pointer<Utf16> lpTitle;
  @Uint32()
  external int dwX;
  @Uint32()
  external int dwY;
  @Uint32()
  external int dwXSize;
  @Uint32()
  external int dwYSize;
  @Uint32()
  external int dwXCountChars;
  @Uint32()
  external int dwYCountChars;
  @Uint32()
  external int dwFillAttribute;
  @Uint32()
  external int dwFlags;
  @Uint16()
  external int wShowWindow;
  @Uint16()
  external int cbReserved2;
  external Pointer<Uint8> lpReserved2;
  @IntPtr()
  external int hStdInput;
  @IntPtr()
  external int hStdOutput;
  @IntPtr()
  external int hStdError;
}

final class _StartupInfoEx extends Struct {
  external _StartupInfo startupInfo;
  external Pointer<Void> lpAttributeList;
}

final class _ProcessInformation extends Struct {
  @IntPtr()
  external int hProcess;
  @IntPtr()
  external int hThread;
  @Uint32()
  external int dwProcessId;
  @Uint32()
  external int dwThreadId;
}

final DynamicLibrary _kernel32 = DynamicLibrary.open('kernel32.dll');

final int Function(
        Pointer<Utf16>, int, int, Pointer<_SecurityAttributes>, int, int, int)
    _createFileW = _kernel32.lookupFunction<
        IntPtr Function(Pointer<Utf16>, Uint32, Uint32,
            Pointer<_SecurityAttributes>, Uint32, Uint32, IntPtr),
        int Function(Pointer<Utf16>, int, int, Pointer<_SecurityAttributes>,
            int, int, int)>('CreateFileW');

final int Function(
        Pointer<Utf16>,
        Pointer<Utf16>,
        Pointer<Void>,
        Pointer<Void>,
        int,
        int,
        Pointer<Void>,
        Pointer<Utf16>,
        Pointer<_StartupInfo>,
        Pointer<_ProcessInformation>) _createProcessW =
    _kernel32.lookupFunction<
        Int32 Function(
            Pointer<Utf16>,
            Pointer<Utf16>,
            Pointer<Void>,
            Pointer<Void>,
            Int32,
            Uint32,
            Pointer<Void>,
            Pointer<Utf16>,
            Pointer<_StartupInfo>,
            Pointer<_ProcessInformation>),
        int Function(
            Pointer<Utf16>,
            Pointer<Utf16>,
            Pointer<Void>,
            Pointer<Void>,
            int,
            int,
            Pointer<Void>,
            Pointer<Utf16>,
            Pointer<_StartupInfo>,
            Pointer<_ProcessInformation>)>('CreateProcessW');

final int Function(int) _closeHandle = _kernel32
    .lookupFunction<Int32 Function(IntPtr), int Function(int)>('CloseHandle');

final int Function(int, int) _waitForSingleObject = _kernel32.lookupFunction<
    Uint32 Function(IntPtr, Uint32),
    int Function(int, int)>('WaitForSingleObject');

final int Function(int, Pointer<Uint32>) _getExitCodeProcess =
    _kernel32.lookupFunction<Int32 Function(IntPtr, Pointer<Uint32>),
        int Function(int, Pointer<Uint32>)>('GetExitCodeProcess');

final int Function(int, int) _terminateProcess = _kernel32.lookupFunction<
    Int32 Function(IntPtr, Uint32), int Function(int, int)>('TerminateProcess');

final int Function(Pointer<Void>, Pointer<Utf16>) _createJobObjectW =
    _kernel32.lookupFunction<IntPtr Function(Pointer<Void>, Pointer<Utf16>),
        int Function(Pointer<Void>, Pointer<Utf16>)>('CreateJobObjectW');

final int Function(int, int) _assignProcessToJobObject = _kernel32
    .lookupFunction<Int32 Function(IntPtr, IntPtr), int Function(int, int)>(
        'AssignProcessToJobObject');

final int Function(int, int) _terminateJobObject = _kernel32.lookupFunction<
    Int32 Function(IntPtr, Uint32),
    int Function(int, int)>('TerminateJobObject');

final int Function(int) _resumeThread = _kernel32
    .lookupFunction<Uint32 Function(IntPtr), int Function(int)>('ResumeThread');

final int Function() _getLastError =
    _kernel32.lookupFunction<Uint32 Function(), int Function()>('GetLastError');

final int Function(Pointer<Void>, int, int, Pointer<IntPtr>)
    _initializeProcThreadAttributeList = _kernel32.lookupFunction<
        Int32 Function(Pointer<Void>, Uint32, Uint32, Pointer<IntPtr>),
        int Function(Pointer<Void>, int, int,
            Pointer<IntPtr>)>('InitializeProcThreadAttributeList');

final int Function(Pointer<Void>, int, int, Pointer<Void>, int, Pointer<Void>,
        Pointer<IntPtr>) _updateProcThreadAttribute =
    _kernel32.lookupFunction<
        Int32 Function(Pointer<Void>, Uint32, IntPtr, Pointer<Void>, IntPtr,
            Pointer<Void>, Pointer<IntPtr>),
        int Function(Pointer<Void>, int, int, Pointer<Void>, int, Pointer<Void>,
            Pointer<IntPtr>)>('UpdateProcThreadAttribute');

final void Function(Pointer<Void>) _deleteProcThreadAttributeList = _kernel32
    .lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>(
        'DeleteProcThreadAttributeList');
