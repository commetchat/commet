/*
 * Copyright 2025 LiveKit
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

import Accelerate
import AVFoundation
import Foundation
import WebRTC

public struct AudioLevel {
    /// Linear Scale RMS Value
    public let average: Float
    public let peak: Float
}

public extension RTCAudioBuffer {
    /// Convert to AVAudioPCMBuffer Int16 format.
    @objc
    func toAVAudioPCMBuffer() -> AVAudioPCMBuffer? {
        guard let audioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                              sampleRate: Double(frames * 100),
                                              channels: AVAudioChannelCount(channels),
                                              interleaved: false),
            let pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat,
                                             frameCapacity: AVAudioFrameCount(frames))
        else { return nil }

        pcmBuffer.frameLength = AVAudioFrameCount(frames)

        guard let targetBufferPointer = pcmBuffer.int16ChannelData else { return nil }

        for i in 0 ..< channels {
            let sourceBuffer = rawBuffer(forChannel: i)
            let targetBuffer = targetBufferPointer[i]
            // sourceBuffer is in the format of [Int16] but is stored in 32-bit alignment, we need to pack the Int16 data correctly.

            for frame in 0 ..< frames {
                // Cast and pack the source 32-bit Int16 data into the target 16-bit buffer
                let clampedValue = max(Float(Int16.min), min(Float(Int16.max), sourceBuffer[frame]))
                targetBuffer[frame] = Int16(clampedValue)
            }
        }

        return pcmBuffer
    }
}

public extension AVAudioPCMBuffer {
    /// Computes Peak and Linear Scale RMS Value (Average) for all channels.
    func audioLevels() -> [AudioLevel] {
        var result: [AudioLevel] = []
        guard let data = floatChannelData else {
            // Not containing float data
            return result
        }

        for i in 0 ..< Int(format.channelCount) {
            let channelData = data[i]
            var max: Float = 0.0
            vDSP_maxv(channelData, stride, &max, vDSP_Length(frameLength))
            var rms: Float = 0.0
            vDSP_rmsqv(channelData, stride, &rms, vDSP_Length(frameLength))

            // No conversion to dB, return linear scale values directly
            result.append(AudioLevel(average: rms, peak: max))
        }

        return result
    }
}

public extension Sequence where Iterator.Element == AudioLevel {
    /// Combines all elements into a single audio level by computing the average value of all elements.
    func combine() -> AudioLevel? {
        var count = 0
        let totalSums: (averageSum: Float, peakSum: Float) = reduce((averageSum: 0.0, peakSum: 0.0)) { totals, audioLevel in
            count += 1
            return (totals.averageSum + audioLevel.average,
                    totals.peakSum + audioLevel.peak)
        }

        guard count > 0 else { return nil }

        return AudioLevel(average: totalSums.averageSum / Float(count),
                          peak: totalSums.peakSum / Float(count))
    }
}

public class AudioVisualizeProcessor {
    static let bufferSize = 1024

    // MARK: - Public

    public let minFrequency: Float
    public let maxFrequency: Float
    public let minDB: Float
    public let maxDB: Float
    public let bandsCount: Int

    private var bands: [Float]?

    // MARK: - Private

    private let ringBuffer = RingBuffer<Float>(size: AudioVisualizeProcessor.bufferSize)
    private let processor: FFTProcessor

    public init(minFrequency: Float = 10,
                maxFrequency: Float = 8000,
                minDB: Float = -32.0,
                maxDB: Float = 32.0,
                bandsCount: Int = 100)
    {
        self.minFrequency = minFrequency
        self.maxFrequency = maxFrequency
        self.minDB = minDB
        self.maxDB = maxDB
        self.bandsCount = bandsCount

        processor = FFTProcessor(bufferSize: Self.bufferSize)
        bands = [Float](repeating: 0.0, count: bandsCount)
    }

    public func process(pcmBuffer: AVAudioPCMBuffer) -> [Float]? {
        guard let pcmBuffer = pcmBuffer.convert(toCommonFormat: .pcmFormatFloat32) else { return nil }
        guard let floatChannelData = pcmBuffer.floatChannelData else { return nil }

        // Get the float array.
        let floats = Array(UnsafeBufferPointer(start: floatChannelData[0], count: Int(pcmBuffer.frameLength)))
        ringBuffer.write(floats)

        // Get full-size buffer if available, otherwise return
        guard let buffer = ringBuffer.read() else { return nil }

        // Process FFT and compute frequency bands
        let fftRes = processor.process(buffer: buffer)
        let bands = fftRes.computeBands(
            minFrequency: minFrequency,
            maxFrequency: maxFrequency,
            bandsCount: bandsCount,
            sampleRate: Float(pcmBuffer.format.sampleRate)
        )

        let headroom = maxDB - minDB

        // Normalize magnitudes (already in decibels)
        return bands.magnitudes.map { magnitude in
            let adjustedMagnitude = max(0, magnitude + abs(minDB))
            return min(1.0, adjustedMagnitude / headroom)
        }
    }
}
