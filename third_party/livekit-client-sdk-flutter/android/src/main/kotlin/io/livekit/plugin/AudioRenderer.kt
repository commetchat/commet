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

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import org.webrtc.AudioTrackSink
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * AudioRenderer for capturing audio data from WebRTC tracks and streaming to Flutter
 * Similar to iOS AudioRenderer implementation
 */
class AudioRenderer(
  private val audioTrack: LKAudioTrack,
  private val binaryMessenger: BinaryMessenger,
  private val rendererId: String,
  private val targetFormat: RendererAudioFormat
) : EventChannel.StreamHandler, AudioTrackSink {
  companion object {
    private const val TAG = "LKAudioRenderer"
  }

  private var eventChannel: EventChannel? = null
  private var eventSink: EventChannel.EventSink? = null
  private var isAttached = false
  private var droppedFrameCount = 0L

  private val handler: Handler by lazy {
    Handler(Looper.getMainLooper())
  }

  init {
    val channelName = "io.livekit.audio.renderer/channel-$rendererId"
    eventChannel = EventChannel(binaryMessenger, channelName)
    eventChannel?.setStreamHandler(this)

    // Attach to the audio track
    audioTrack.addSink(this)
    isAttached = true
  }

  fun detach() {
    if (isAttached) {
      audioTrack.removeSink(this)
      isAttached = false
    }
    eventChannel?.setStreamHandler(null)
    eventSink = null
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  override fun onData(
    audioData: ByteBuffer,
    bitsPerSample: Int,
    sampleRate: Int,
    numberOfChannels: Int,
    numberOfFrames: Int,
    absoluteCaptureTimestampMs: Long
  ) {
    eventSink?.let { sink ->
      val convertedData = try {
        // Convert audio data to the target format
        convertAudioData(
          audioData,
          bitsPerSample,
          sampleRate,
          numberOfChannels,
          numberOfFrames
        )
      } catch (e: Exception) {
        logDroppedFrame("Audio conversion exception: ${e.message}")
        null
      }

      if (convertedData == null) {
        return@let
      }

      // Send to Flutter on the main thread
      handler.post {
        sink.success(convertedData)
      }
    }
  }

  /**
   * Converts audio data to raw interleaved bytes with resampling.
   *
   * Pipeline: read int16 → resample → channel reduce → format convert (int16/float32)
   */
  private fun convertAudioData(
    audioData: ByteBuffer,
    bitsPerSample: Int,
    sampleRate: Int,
    numberOfChannels: Int,
    numberOfFrames: Int
  ): Map<String, Any>? {
    // WebRTC AudioTrackSink always delivers 16-bit signed int16 PCM.
    if (bitsPerSample != 16) {
      logDroppedFrame("Unsupported bitsPerSample: $bitsPerSample (expected 16)")
      return null
    }
    if (numberOfChannels <= 0) {
      logDroppedFrame("Invalid numberOfChannels: $numberOfChannels")
      return null
    }
    if (numberOfFrames <= 0) {
      logDroppedFrame("Invalid numberOfFrames: $numberOfFrames")
      return null
    }

    val bytesPerFrame = numberOfChannels * 2
    val buffer = audioData.duplicate()
    buffer.order(ByteOrder.LITTLE_ENDIAN)
    buffer.rewind()

    val availableBytes = buffer.remaining()
    if (availableBytes <= 0) {
      logDroppedFrame("No audio payload bytes available")
      return null
    }

    val expectedBytes = numberOfFrames.toLong() * bytesPerFrame.toLong()
    val srcFrames = if (expectedBytes <= availableBytes.toLong()) {
      numberOfFrames
    } else {
      val availableFrames = availableBytes / bytesPerFrame
      if (availableFrames <= 0) {
        logDroppedFrame(
          "Insufficient bytes for one frame (available=$availableBytes, bytesPerFrame=$bytesPerFrame)"
        )
        return null
      }
      logDroppedFrame("Short audio payload; truncating frames from $numberOfFrames to $availableFrames")
      availableFrames
    }

    // Step 1: Read source int16 samples into ShortArray
    val src = ShortArray(srcFrames * numberOfChannels)
    for (i in src.indices) {
      src[i] = buffer.short
    }

    // Step 2: Resample to target sample rate
    val resampleResult = AudioResampler.resample(
      src, srcFrames, sampleRate, targetFormat.sampleRate, numberOfChannels
    )
    val resampled = resampleResult.samples
    val outFrames = resampleResult.frameCount

    if (outFrames <= 0) {
      logDroppedFrame("Resampled frame count is 0")
      return null
    }

    // Step 3: Channel reduction + format conversion
    val requestedChannels = targetFormat.numberOfChannels.coerceAtLeast(1)
    val outChannels = requestedChannels.coerceAtMost(numberOfChannels)

    val result = mutableMapOf<String, Any>(
      "sampleRate" to targetFormat.sampleRate,
      "channels" to outChannels,
      "frameLength" to outFrames,
    )

    when (targetFormat.commonFormat) {
      "float32" -> {
        result["commonFormat"] = "float32"
        val out = ByteArray(outFrames * outChannels * 4)
        val outBuf = ByteBuffer.wrap(out).order(ByteOrder.LITTLE_ENDIAN)
        for (f in 0 until outFrames) {
          for (ch in 0 until outChannels) {
            val sample = resampled[f * numberOfChannels + ch].toFloat() / Short.MAX_VALUE
            outBuf.putFloat((f * outChannels + ch) * 4, sample)
          }
        }
        result["data"] = out
      }
      else -> {
        result["commonFormat"] = "int16"
        if (outChannels == numberOfChannels) {
          // Fast path: no channel reduction — bulk copy resampled data
          val out = ByteArray(outFrames * outChannels * 2)
          val outBuf = ByteBuffer.wrap(out).order(ByteOrder.LITTLE_ENDIAN)
          for (i in 0 until outFrames * outChannels) {
            outBuf.putShort(i * 2, resampled[i])
          }
          result["data"] = out
        } else {
          // Channel reduction: keep first outChannels
          val out = ByteArray(outFrames * outChannels * 2)
          val outBuf = ByteBuffer.wrap(out).order(ByteOrder.LITTLE_ENDIAN)
          for (f in 0 until outFrames) {
            for (ch in 0 until outChannels) {
              outBuf.putShort(
                (f * outChannels + ch) * 2,
                resampled[f * numberOfChannels + ch]
              )
            }
          }
          result["data"] = out
        }
      }
    }

    return result
  }

  private fun logDroppedFrame(reason: String) {
    droppedFrameCount += 1
    if (droppedFrameCount <= 5 || droppedFrameCount % 100 == 0L) {
      Log.w(TAG, "Dropping audio frame #$droppedFrameCount for rendererId=$rendererId: $reason")
    }
  }
}

/**
 * Audio format specification for the renderer
 */
data class RendererAudioFormat(
  val bitsPerSample: Int,
  val sampleRate: Int,
  val numberOfChannels: Int,
  val commonFormat: String = "int16"
) {
  companion object {
    fun fromMap(formatMap: Map<String, Any?>): RendererAudioFormat? {
      val bitsPerSample = formatMap["bitsPerSample"] as? Int ?: 16
      val sampleRate = formatMap["sampleRate"] as? Int ?: 48000
      val numberOfChannels = formatMap["channels"] as? Int ?: 1
      val commonFormat = formatMap["commonFormat"] as? String ?: "int16"

      return RendererAudioFormat(bitsPerSample, sampleRate, numberOfChannels, commonFormat)
    }
  }
}
