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
 *
 * Originally adapted from: https://github.com/dzolnai/ExoVisualizer
 *
 * MIT License
 *
 * Copyright (c) 2019 Dániel Zolnai
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

package io.livekit.plugin

import android.media.AudioTrack
import com.paramsen.noise.Noise
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.TimeUnit
import kotlin.math.max


/**
 * A Fast Fourier Transform analyzer for audio bytes.
 *
 * Use [queueInput] to add audio bytes, and collect on [fftFlow]
 * to receive the analyzed frequencies.
 */
class FFTAudioAnalyzer {

    companion object {
        const val SAMPLE_SIZE = 512
        private val EMPTY_BUFFER = ByteBuffer.allocateDirect(0).order(ByteOrder.nativeOrder())

        // Extra size next in addition to the AudioTrack buffer size
        private const val BUFFER_EXTRA_SIZE = SAMPLE_SIZE * 8

        // Size of short in bytes.
        private const val SHORT_SIZE = 2
    }

    private val isActive: Boolean
        get() = noise != null

    private var noise: Noise? = null
    private lateinit var inputAudioFormat: AudioFormat

    private var audioTrackBufferSize = 0

    private var fftBuffer: ByteBuffer = EMPTY_BUFFER
    private lateinit var srcBuffer: ByteBuffer
    private var srcBufferPosition = 0
    private val tempShortArray = ShortArray(SAMPLE_SIZE)
    private val src = FloatArray(SAMPLE_SIZE)

    /**
     * A flow of frequencies for the audio bytes given through [queueInput].
     */
    var fft: FloatArray? = null
        private set

    fun configure(inputAudioFormat: AudioFormat) {
        this.inputAudioFormat = inputAudioFormat

        noise = Noise.real(SAMPLE_SIZE)

        audioTrackBufferSize = getDefaultBufferSizeInBytes(inputAudioFormat)

        srcBuffer = ByteBuffer.allocate(audioTrackBufferSize + BUFFER_EXTRA_SIZE)
    }

    fun release() {
        noise?.close()
        noise = null
    }

    /**
     * Add audio bytes to be processed.
     */
    fun queueInput(inputBuffer: ByteBuffer) {
        if (!isActive) {
            return
        }
        var position = inputBuffer.position()
        val limit = inputBuffer.limit()
        val frameCount = (limit - position) / (SHORT_SIZE * inputAudioFormat.numberOfChannels)
        val singleChannelOutputSize = frameCount * SHORT_SIZE

        // Setup buffer
        if (fftBuffer.capacity() < singleChannelOutputSize) {
            fftBuffer =
                ByteBuffer.allocateDirect(singleChannelOutputSize).order(ByteOrder.nativeOrder())
        } else {
            fftBuffer.clear()
        }

        // Process inputBuffer
        while (position < limit) {
            var summedUp: Short = 0
            for (channelIndex in 0 until inputAudioFormat.numberOfChannels) {
                if( channelIndex == 0) {
                    val current = inputBuffer.getShort(position + 2 * channelIndex)
                    summedUp = (summedUp + current).toShort()
                }
            }
            fftBuffer.putShort(summedUp)
            position += inputAudioFormat.numberOfChannels * 2
        }

        // Reset input buffer to original position.
        inputBuffer.position(position)

        processFFT(this.fftBuffer)
    }

    private fun processFFT(buffer: ByteBuffer) {
        if (noise == null) {
            return
        }
        srcBuffer.put(buffer.array())
        srcBufferPosition += buffer.array().size
        // Since this is PCM 16 bit, each sample will be 2 bytes.
        // So to get the sample size in the end, we need to take twice as many bytes off the buffer
        val bytesToProcess = SAMPLE_SIZE * 2
        while (srcBufferPosition > bytesToProcess) {
            // Move to start of
            srcBuffer.position(0)

            srcBuffer.asShortBuffer().get(tempShortArray, 0, SAMPLE_SIZE)
            tempShortArray.forEachIndexed { index, sample ->
                // Normalize to value between -1.0 and 1.0
                src[index] = sample.toFloat() / Short.MAX_VALUE
            }

            srcBuffer.position(bytesToProcess)
            srcBuffer.compact()
            srcBufferPosition -= bytesToProcess
            srcBuffer.position(srcBufferPosition)
            val dst = FloatArray(SAMPLE_SIZE + 2)
            val fft = noise?.fft(src, dst)!!

            this.fft = fft
        }
    }

    private fun durationUsToFrames(sampleRate: Int, durationUs: Long): Long {
        return durationUs * sampleRate / TimeUnit.MICROSECONDS.convert(1, TimeUnit.SECONDS)
    }

    private fun getPcmFrameSize(channelCount: Int): Int {
        // assumes PCM_16BIT
        return channelCount * 2
    }

    private fun getAudioTrackChannelConfig(channelCount: Int): Int {
        return when (channelCount) {
            1 -> android.media.AudioFormat.CHANNEL_OUT_MONO
            2 -> android.media.AudioFormat.CHANNEL_OUT_STEREO
            // ignore other channel counts that aren't used in LiveKit
            else -> android.media.AudioFormat.CHANNEL_INVALID
        }
    }

    private fun getDefaultBufferSizeInBytes(audioFormat: AudioFormat): Int {
        val outputPcmFrameSize = getPcmFrameSize(audioFormat.numberOfChannels)
        val minBufferSize =
            AudioTrack.getMinBufferSize(
                audioFormat.sampleRate,
                getAudioTrackChannelConfig(audioFormat.numberOfChannels),
                android.media.AudioFormat.ENCODING_PCM_16BIT
            )

        check(minBufferSize != AudioTrack.ERROR_BAD_VALUE)
        val multipliedBufferSize = minBufferSize * 4
        val minAppBufferSize =
            durationUsToFrames(audioFormat.sampleRate, 30 * 1000).toInt() * outputPcmFrameSize
        val maxAppBufferSize = max(
            minBufferSize.toLong(),
            durationUsToFrames(audioFormat.sampleRate, 500 * 1000) * outputPcmFrameSize
        ).toInt()
        val bufferSizeInFrames =
            multipliedBufferSize.coerceIn(minAppBufferSize, maxAppBufferSize) / outputPcmFrameSize
        return bufferSizeInFrames * outputPcmFrameSize
    }
}

data class AudioFormat(val bitsPerSample: Int, val sampleRate: Int, val numberOfChannels: Int)