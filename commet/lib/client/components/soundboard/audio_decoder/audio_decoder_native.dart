// Binding to rust/audio_decode/src/ffi.rs.
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:commet/client/components/soundboard/audio_decoder.dart';
import 'package:commet/client/components/soundboard/soundboard_normalizer.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/config/rust_library.dart';
import 'package:commet/debug/log.dart';
import 'package:ffi/ffi.dart';

/// Mirrors `audio_decode::ffi::DecodedAudio`.
final class DecodedAudio extends Struct {
  external Pointer<Float> samples;
  @Size()
  external int len;
  @Uint32()
  external int sampleRate;
  @Uint32()
  external int channels;
  @Uint32()
  external int truncated;
}

typedef _DecodeNative = Int32 Function(Pointer<Uint8> data, Size len,
    Pointer<Utf8> extension, Double maxSeconds, Pointer<DecodedAudio> out);
typedef _Decode = int Function(Pointer<Uint8> data, int len,
    Pointer<Utf8> extension, double maxSeconds, Pointer<DecodedAudio> out);
typedef _FreeNative = Void Function(Pointer<Float> samples, Size len);
typedef _Free = void Function(Pointer<Float> samples, int len);

class NativeAudioDecoder {
  static const expectedAbi = 1;

  final _Decode _decode;
  final _Free _free;

  NativeAudioDecoder._(this._decode, this._free);

  /// Null when the library or its symbols are missing (Android, old build).
  static NativeAudioDecoder? open(DynamicLibrary lib) {
    try {
      final abi = lib.lookupFunction<Uint32 Function(), int Function()>(
          'commet_audio_decode_abi_version')();
      if (abi != expectedAbi) {
        Log.w('Soundboard decoder: ABI $abi, expected $expectedAbi');
        return null;
      }
      return NativeAudioDecoder._(
        lib.lookupFunction<_DecodeNative, _Decode>('commet_audio_decode'),
        lib.lookupFunction<_FreeNative, _Free>('commet_audio_decode_free'),
      );
    } catch (e) {
      Log.w('Soundboard decoder: symbols missing: $e');
      return null;
    }
  }

  PcmAudio? decode(Uint8List bytes, String mimeType) {
    final data = malloc<Uint8>(bytes.length);
    final ext = _extension(mimeType)?.toNativeUtf8();
    final out = calloc<DecodedAudio>();
    try {
      data.asTypedList(bytes.length).setAll(0, bytes);
      final code =
          _decode(data, bytes.length, ext ?? nullptr, maxDecodeSeconds, out);
      if (code != 0) return null;
      final r = out.ref;
      try {
        final samples = Float32List.fromList(r.samples.asTypedList(r.len));
        return PcmAudio.interleaved(samples, r.channels, r.sampleRate);
      } finally {
        _free(r.samples, r.len);
      }
    } finally {
      malloc.free(data);
      if (ext != null) malloc.free(ext);
      calloc.free(out);
    }
  }

  static String? _extension(String mimeType) => switch (mimeType) {
        'audio/mpeg' || 'audio/mp3' => 'mp3',
        'audio/ogg' || 'audio/opus' => 'ogg',
        'audio/flac' => 'flac',
        'audio/wav' || 'audio/x-wav' || 'audio/wave' => 'wav',
        _ => null,
      };
}

NativeAudioDecoder? _openDecoder() {
  // librust_lib_commet is only built for Linux and Windows.
  if (!PlatformUtils.isLinux && !PlatformUtils.isWindows) return null;
  final lib = openRustLibrary();
  return lib == null ? null : NativeAudioDecoder.open(lib);
}

/// Decodes on a background isolate: up to [maxDecodeSeconds] of MP3 takes
/// long enough to drop frames on the UI isolate.
Future<PcmAudio?> decode(Uint8List bytes, String mimeType) =>
    Isolate.run(() => _openDecoder()?.decode(bytes, mimeType));
