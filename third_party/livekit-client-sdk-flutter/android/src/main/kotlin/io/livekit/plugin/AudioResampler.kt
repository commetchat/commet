/*
 * Copyright 2024 LiveKit, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package io.livekit.plugin

/**
 * Pure audio resampler for interleaved int16 PCM data.
 *
 * - Same rate: passthrough (returns input array as-is)
 * - Upsampling: linear interpolation between adjacent samples
 * - Downsampling: box filter (averages source samples per output sample) to prevent aliasing
 */
object AudioResampler {

  /**
   * Resample interleaved int16 PCM audio.
   *
   * @param src         Interleaved int16 samples (channels interleaved per frame)
   * @param srcFrames   Number of frames in [src] (total samples = srcFrames * channels)
   * @param srcRate     Source sample rate in Hz
   * @param targetRate  Target sample rate in Hz
   * @param channels    Number of interleaved channels
   * @return Resampled interleaved int16 samples. Returns [src] unchanged when rates match.
   */
  fun resample(
    src: ShortArray,
    srcFrames: Int,
    srcRate: Int,
    targetRate: Int,
    channels: Int
  ): ResampleResult {
    if (srcRate == targetRate || srcFrames <= 0 || channels <= 0) {
      return ResampleResult(src, srcFrames)
    }

    val outFrames = ((srcFrames.toLong() * targetRate) / srcRate).toInt()
    if (outFrames <= 0) {
      return ResampleResult(ShortArray(0), 0)
    }

    val resampled = if (targetRate > srcRate) {
      upsample(src, srcFrames, outFrames, channels)
    } else {
      downsample(src, srcFrames, outFrames, srcRate, targetRate, channels)
    }

    return ResampleResult(resampled, outFrames)
  }

  /**
   * Linear interpolation upsampling.
   */
  private fun upsample(
    src: ShortArray,
    srcFrames: Int,
    outFrames: Int,
    channels: Int
  ): ShortArray {
    val out = ShortArray(outFrames * channels)

    // Edge case: single source frame — just repeat it
    if (srcFrames <= 1) {
      for (f in 0 until outFrames) {
        for (ch in 0 until channels) {
          out[f * channels + ch] = src[ch]
        }
      }
      return out
    }

    val ratio = srcFrames.toDouble() / outFrames.toDouble()

    for (f in 0 until outFrames) {
      val srcPos = f * ratio
      val idx = srcPos.toInt().coerceAtMost(srcFrames - 2)
      val frac = (srcPos - idx).toFloat()

      for (ch in 0 until channels) {
        val s0 = src[idx * channels + ch]
        val s1 = src[(idx + 1) * channels + ch]
        out[f * channels + ch] = (s0 + frac * (s1 - s0)).toInt()
          .coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())
          .toShort()
      }
    }

    return out
  }

  /**
   * Box filter downsampling. Averages all source samples that map to each
   * output sample, acting as a low-pass filter to prevent aliasing.
   */
  private fun downsample(
    src: ShortArray,
    srcFrames: Int,
    outFrames: Int,
    srcRate: Int,
    targetRate: Int,
    channels: Int
  ): ShortArray {
    val out = ShortArray(outFrames * channels)
    val ratio = srcRate.toDouble() / targetRate.toDouble()

    for (f in 0 until outFrames) {
      val srcStart = (f * ratio).toInt()
      val srcEnd = ((f + 1) * ratio).toInt().coerceAtMost(srcFrames)

      for (ch in 0 until channels) {
        var sum = 0L
        for (i in srcStart until srcEnd) {
          sum += src[i * channels + ch]
        }
        val count = srcEnd - srcStart
        out[f * channels + ch] = if (count > 0) {
          (sum / count).toInt()
            .coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())
            .toShort()
        } else {
          0
        }
      }
    }

    return out
  }

  data class ResampleResult(val samples: ShortArray, val frameCount: Int)
}
