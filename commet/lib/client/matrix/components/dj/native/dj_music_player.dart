// dart:ffi bindings to the booth's player in librust_lib_commet
// (rust/dj_audio, `commet_music_*`). The player decodes a downloaded song
// and hands it, 10 ms at a time, to the WebRTC track flutter-webrtc feeds
// from `commet_music_pull` (commet_music_source.h).
import 'dart:ffi';

import 'package:commet/config/rust_library.dart';
import 'package:commet/debug/log.dart';
import 'package:ffi/ffi.dart';

/// Mirrors `MusicStatus` in rust/dj_audio/src/ffi.rs.
final class MusicStatus extends Struct {
  @Uint32()
  external int state;
  @Uint32()
  external int underruns;
  @Uint64()
  external int trackId;
  @Uint64()
  external int positionMs;
  @Uint64()
  external int durationMs;
  @Int32()
  external int error;
  @Uint32()
  external int pad;
}

/// `MusicStatus.state`.
enum MusicState { idle, playing, paused, ended, error, buffering }

class DjMusicBindings {
  static const abiVersion = 1;

  final DynamicLibrary lib;

  DjMusicBindings._(this.lib);

  static DjMusicBindings? _instance;
  static bool _tried = false;

  /// Null when the library is missing or predates the booth.
  static DjMusicBindings? load() {
    if (_tried) return _instance;
    _tried = true;
    final lib = openRustLibrary();
    if (lib == null) return null;
    try {
      final version =
          lib.lookupFunction<Uint32 Function(), int Function()>(
              'commet_music_abi_version')();
      if (version != abiVersion) {
        Log.w('DJ booth: music player ABI $version, expected $abiVersion');
        return null;
      }
      final bindings = DjMusicBindings._(lib);
      // Resolve everything now, so a missing symbol shows here and not
      // halfway through a song.
      bindings.create;
      bindings.free;
      bindings.open;
      bindings.stop;
      bindings.setPaused;
      bindings.seek;
      bindings.setGain;
      bindings.status;
      bindings.pullAddress;
      return _instance = bindings;
    } catch (e) {
      Log.w('DJ booth: no music player in the Rust library: $e');
      return null;
    }
  }

  late final Pointer<Void> Function() create = lib
      .lookupFunction<Pointer<Void> Function(), Pointer<Void> Function()>(
          'commet_music_new');
  late final void Function(Pointer<Void>) free = lib.lookupFunction<
      Void Function(Pointer<Void>), void Function(Pointer<Void>)>(
      'commet_music_free');
  late final int Function(Pointer<Void>, Pointer<Utf8>, int, int) open =
      lib.lookupFunction<
          Int32 Function(Pointer<Void>, Pointer<Utf8>, Uint64, Uint64),
          int Function(Pointer<Void>, Pointer<Utf8>, int, int)>(
          'commet_music_open');
  late final void Function(Pointer<Void>) stop = lib.lookupFunction<
      Void Function(Pointer<Void>), void Function(Pointer<Void>)>(
      'commet_music_stop');
  late final void Function(Pointer<Void>, int) setPaused = lib.lookupFunction<
      Void Function(Pointer<Void>, Uint8),
      void Function(Pointer<Void>, int)>('commet_music_set_paused');
  late final int Function(Pointer<Void>, int) seek = lib.lookupFunction<
      Int32 Function(Pointer<Void>, Uint64),
      int Function(Pointer<Void>, int)>('commet_music_seek');
  late final void Function(Pointer<Void>, double) setGain = lib.lookupFunction<
      Void Function(Pointer<Void>, Float),
      void Function(Pointer<Void>, double)>('commet_music_set_gain');
  late final void Function(Pointer<Void>, Pointer<MusicStatus>) status =
      lib.lookupFunction<Void Function(Pointer<Void>, Pointer<MusicStatus>),
          void Function(Pointer<Void>, Pointer<MusicStatus>)>(
          'commet_music_status');

  /// Address of `commet_music_pull`, for the C++ pacing thread.
  late final int pullAddress = lib
      .lookup<
          NativeFunction<
              Size Function(Pointer<Void>, Pointer<Int16>, Size, Size,
                  Int32)>>('commet_music_pull')
      .address;
}

/// Error codes of `commet_music_open`.
String describeMusicError(int code) => switch (code) {
      -2 => "the downloaded file couldn't be opened",
      -3 => "its audio format isn't supported",
      -4 => "it couldn't be played from that position",
      -5 => 'the decoder failed',
      _ => 'error $code',
    };

/// One player instance.
class DjMusicPlayer {
  final DjMusicBindings _b;
  Pointer<Void> _handle;
  final Pointer<MusicStatus> _status = calloc<MusicStatus>();

  DjMusicPlayer(this._b) : _handle = _b.create();

  /// For flutter-webrtc's pacing thread.
  int get handleAddress => _handle.address;
  int get pullAddress => _b.pullAddress;

  bool get isFreed => _handle == nullptr;

  /// Loads [path] at [positionMs]; throws with a readable reason.
  void open(String path, {required int positionMs, required int trackId}) {
    final native = path.toNativeUtf8();
    try {
      final code = _b.open(_handle, native, positionMs, trackId);
      if (code != 0) throw StateError(describeMusicError(code));
    } finally {
      malloc.free(native);
    }
  }

  void stop() => _b.stop(_handle);

  void setPaused(bool paused) => _b.setPaused(_handle, paused ? 1 : 0);

  void seek(int positionMs) {
    final code = _b.seek(_handle, positionMs);
    if (code != 0) throw StateError(describeMusicError(code));
  }

  void setGain(double gain) => _b.setGain(_handle, gain);

  ({MusicState state, int trackId, int positionMs, int durationMs, int error})
      get status {
    _b.status(_handle, _status);
    final s = _status.ref;
    return (
      state: s.state < MusicState.values.length
          ? MusicState.values[s.state]
          : MusicState.error,
      trackId: s.trackId,
      positionMs: s.positionMs,
      durationMs: s.durationMs,
      error: s.error,
    );
  }

  /// Only once nothing pulls from it any more (commetStopMusicTrack
  /// returned).
  void free() {
    if (_handle == nullptr) return;
    _b.free(_handle);
    _handle = nullptr;
    calloc.free(_status);
  }
}
