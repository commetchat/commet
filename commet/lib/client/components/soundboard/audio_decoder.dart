// Decodes a downloaded soundboard clip to PCM so its loudness can be
// measured at import. WAV is handled in Dart ([SoundboardNormalizer]); this
// covers everything else (MP3, Ogg, ...) with the platform's decoder:
// - Linux/Windows: rust/audio_decode (symphonia) inside librust_lib_commet.
// - Browser: AudioContext.decodeAudioData.
// - Android and others: nothing, the import is logged as unmeasured.
import 'dart:async';
import 'dart:typed_data';

import 'package:commet/client/components/soundboard/soundboard_normalizer.dart';

import 'audio_decoder/audio_decoder_stub.dart'
    if (dart.library.ffi) 'audio_decoder/audio_decoder_native.dart'
    if (dart.library.js_interop) 'audio_decoder/audio_decoder_web.dart'
    as platform;

/// Returns null when the bytes cannot be decoded here.
typedef AudioDecoder = FutureOr<PcmAudio?> Function(
    Uint8List bytes, String mimeType);

/// Decodes at most this much audio: enough to tell a clip is over
/// [SoundboardConstraints.maxDurationMs] without decoding a whole song.
const double maxDecodeSeconds = 20;

Future<PcmAudio?> decodeWithPlatform(Uint8List bytes, String mimeType) =>
    platform.decode(bytes, mimeType);
