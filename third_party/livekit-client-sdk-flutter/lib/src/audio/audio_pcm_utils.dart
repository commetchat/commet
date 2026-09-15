// Copyright 2025 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:typed_data' show ByteData, Endian, Float32List, Uint8List;

/// Convert interleaved float32 samples to int16 PCM bytes (little-endian).
///
/// [srcFloat32] contains interleaved samples with [srcChannels] channels.
/// The output contains only the first [outChannels] channels, with each sample
/// clamped to [-1.0, 1.0] and scaled to the int16 range.
Uint8List float32ToInt16Bytes(
  Float32List srcFloat32,
  int srcChannels,
  int outChannels,
  int frames,
) {
  final out = ByteData(frames * outChannels * 2);

  for (var frame = 0; frame < frames; frame++) {
    for (var ch = 0; ch < outChannels; ch++) {
      final sample = srcFloat32[frame * srcChannels + ch];
      final clamped = sample.clamp(-1.0, 1.0);
      final int16 = (clamped * 32767).round();
      out.setInt16((frame * outChannels + ch) * 2, int16, Endian.little);
    }
  }

  return out.buffer.asUint8List();
}

/// Extract interleaved float32 samples as raw bytes (little-endian).
///
/// If [srcChannels] equals [outChannels], the source buffer is returned
/// directly (zero-copy). Otherwise, only the first [outChannels] are kept.
Uint8List float32ToFloat32Bytes(
  Float32List srcFloat32,
  int srcChannels,
  int outChannels,
  int frames,
) {
  if (srcChannels == outChannels) {
    return srcFloat32.buffer.asUint8List();
  }

  final out = ByteData(frames * outChannels * 4);
  for (var frame = 0; frame < frames; frame++) {
    for (var ch = 0; ch < outChannels; ch++) {
      out.setFloat32(
        (frame * outChannels + ch) * 4,
        srcFloat32[frame * srcChannels + ch],
        Endian.little,
      );
    }
  }
  return out.buffer.asUint8List();
}
