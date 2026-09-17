import 'dart:ffi';
import 'dart:io';

import 'package:commet/debug/log.dart';
import 'package:path/path.dart' as p;

DynamicLibrary? _library;
bool _attempted = false;

/// Opens librust_lib_commet (Linux and Windows only) for the plain C ABI
/// entry points that bypass flutter_rust_bridge (voice DSP, soundboard
/// decoder). Null, logged once, when it cannot be found.
DynamicLibrary? openRustLibrary() {
  if (_attempted) return _library;
  _attempted = true;
  final name =
      Platform.isWindows ? 'rust_lib_commet.dll' : 'librust_lib_commet.so';
  final exeDir = p.dirname(Platform.resolvedExecutable);
  final candidates = [
    // packaged builds and `flutter run` bundles
    p.join(exeDir, 'lib', name),
    p.join(exeDir, name),
    // already loaded by the runner / flutter_rust_bridge
    name,
    // flutter_rust_bridge's dev location
    p.join('..', 'rust', 'rust', 'target', 'release', name),
    p.join('rust', 'rust', 'target', 'release', name),
  ];
  final errors = <String>[];
  for (final candidate in candidates) {
    try {
      return _library = DynamicLibrary.open(candidate);
    } catch (e) {
      errors.add("$candidate: $e");
    }
  }
  Log.w("Could not load the Rust library: ${errors.join("; ")}");
  return null;
}
