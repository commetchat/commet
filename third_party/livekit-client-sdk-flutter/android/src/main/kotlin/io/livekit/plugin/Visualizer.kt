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
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import org.webrtc.AudioTrack
import org.webrtc.AudioTrackSink
import java.nio.ByteBuffer
import kotlin.math.*

class Visualizer(
    private var barCount: Int,
    private var isCentered: Boolean,
    private var smoothTransition: Boolean,
    audioTrack: LKAudioTrack,
    binaryMessenger: BinaryMessenger,
    visualizerId: String
) : EventChannel.StreamHandler, AudioTrackSink {
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var ffiAudioAnalyzer = FFTAudioAnalyzer()
    private var audioTrack: LKAudioTrack? = audioTrack
    private var amplitudes: FloatArray = FloatArray(0)
    private var bands: FloatArray
    private var loPass: Int = 0
    private var hiPass: Int = 80

    private var audioFormat = AudioFormat(16, 48000, 1)

    fun stop() {
        audioTrack?.removeSink(this)
        eventChannel?.setStreamHandler(null)
        ffiAudioAnalyzer.release()
    }

    override fun onData(
        audioData: ByteBuffer,
        bitsPerSample: Int,
        sampleRate: Int,
        numberOfChannels: Int,
        numberOfFrames: Int,
        absoluteCaptureTimestampMs: Long
    ) {

        if (audioFormat.sampleRate != sampleRate || audioFormat.bitsPerSample != bitsPerSample || audioFormat.numberOfChannels != numberOfChannels) {
            audioFormat = AudioFormat(bitsPerSample, sampleRate, numberOfChannels)
            ffiAudioAnalyzer.configure(audioFormat)
        }

        ffiAudioAnalyzer.queueInput(audioData)
        val fft: FloatArray = ffiAudioAnalyzer.fft ?: return

        val averages = FloatArray(barCount)

        val sliced = fft.slice(loPass until hiPass)
        amplitudes = calculateAmplitudeBarsFromFFT(sliced, averages, barCount)

        if(bands.size != amplitudes.size) {
            bands = amplitudes;
        }

        if(this.isCentered) {
            amplitudes = centerBands(amplitudes)
        }

        if(this.smoothTransition) {
            bands = bands.mapIndexed { index, value ->
                smoothTransition(value, amplitudes[index], 0.3f)
            }.toFloatArray()
        } else {
            bands = amplitudes
        }

        handler.post {
            eventSink?.success(bands)
        }
    }

    private val handler: Handler by lazy {
        Handler(Looper.getMainLooper())
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    init {
        eventChannel = EventChannel(binaryMessenger, "io.livekit.audio.visualizer/eventChannel-" + audioTrack.id() + "-" + visualizerId)
        eventChannel?.setStreamHandler(this)
        bands = FloatArray(barCount)
        ffiAudioAnalyzer.configure(audioFormat)
        audioTrack.addSink(this)
    }
}

private fun centerBands(bands: FloatArray): FloatArray {
    val centeredBands = FloatArray(bands.size)
    var leftIndex = bands.size / 2;
    var rightIndex = leftIndex;

    for (i in bands.indices) {
        val value = bands[i]
        if (i % 2 == 0) {
            // Place value to the right
            centeredBands[rightIndex] = value
            rightIndex += 1
        } else {
            // Place value to the left
            leftIndex -= 1
            centeredBands[leftIndex] = value
        }
    }
    return centeredBands
}

private  fun smoothTransition(from: Float, to: Float, factor: Float): Float {
    val delta = to - from
    val easedFactor = easeInOutCubic(factor)
    return from + delta * easedFactor
}

private fun easeInOutCubic(t: Float): Float {
    return if (t < 0.5) {
        4 * t * t * t
    } else {
        1 - (2 * t - 2).pow(3) / 2
    }
}

private const val MIN_CONST = 0.1f
private const val MAX_CONST = 8.0f

private fun calculateAmplitudeBarsFromFFT(
    fft: List<Float>,
    averages: FloatArray,
    barCount: Int,
): FloatArray {
    val amplitudes = FloatArray(barCount)
    if (fft.isEmpty()) {
        return amplitudes
    }

    // We average out the values over 3 occurences (plus the current one), so big jumps are smoothed out
    // Iterate over the entire FFT result array.
    for (barIndex in 0 until barCount) {
        // Note: each FFT is a real and imaginary pair.
        // Scale down by 2 and scale back up to ensure we get an even number.
        val prevLimit = (round(fft.size.toFloat() / 2 * barIndex / barCount).toInt() * 2)
            .coerceIn(0, fft.size - 1)
        val nextLimit = (round(fft.size.toFloat() / 2 * (barIndex + 1) / barCount).toInt() * 2)
            .coerceIn(0, fft.size - 1)

        var accum = 0f
        // Here we iterate within this single band
        for (i in prevLimit until nextLimit step 2) {
            // Convert real and imaginary part to get energy

            val realSq = fft[i]
                .toDouble()
                .pow(2.0)
            val imaginarySq = fft[i + 1]
                .toDouble()
                .pow(2.0)
            val raw = sqrt(realSq + imaginarySq).toFloat()

            accum += raw
        }

        // A window might be empty which would result in a 0 division
        if ((nextLimit - prevLimit) != 0) {
            accum /= (nextLimit - prevLimit)
        } else {
            accum = 0.0f
        }

        val smoothingFactor = 1f
        var avg = averages[barIndex]
        avg += (accum - avg / smoothingFactor)
        averages[barIndex] = avg

        var amplitude = avg.coerceIn(MIN_CONST, MAX_CONST)
        amplitude -= MIN_CONST
        amplitude /= (MAX_CONST - MIN_CONST)
        amplitudes[barIndex] = amplitude
    }

    return amplitudes
}

