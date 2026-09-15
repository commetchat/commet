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

extension Float {
    var nyquistFrequency: Float { self / 2.0 }
}

public struct FFTComputeBandsResult {
    let count: Int
    let magnitudes: [Float]
    let frequencies: [Float]
}

public class FFTResult {
    public let magnitudes: [Float]

    init(magnitudes: [Float]) {
        self.magnitudes = magnitudes
    }

    func computeBands(minFrequency: Float, maxFrequency: Float, bandsCount: Int, sampleRate: Float) -> FFTComputeBandsResult {
        let actualMaxFrequency = min(sampleRate.nyquistFrequency, maxFrequency)
        var bandMagnitudes = [Float](repeating: 0.0, count: bandsCount)
        var bandFrequencies = [Float](repeating: 0.0, count: bandsCount)

        let magLowerRange = _magnitudeIndex(for: minFrequency, sampleRate: sampleRate)
        let magUpperRange = _magnitudeIndex(for: actualMaxFrequency, sampleRate: sampleRate)
        let ratio = Float(magUpperRange - magLowerRange) / Float(bandsCount)

        return magnitudes.withUnsafeBufferPointer { magnitudesPtr in
            for i in 0 ..< bandsCount {
                let magsStartIdx = vDSP_Length(floorf(Float(i) * ratio)) + magLowerRange
                let magsEndIdx = vDSP_Length(floorf(Float(i + 1) * ratio)) + magLowerRange

                let count = magsEndIdx - magsStartIdx
                if count > 0 {
                    var sum: Float = 0
                    vDSP_sve(magnitudesPtr.baseAddress! + Int(magsStartIdx), 1, &sum, count)
                    bandMagnitudes[i] = sum / Float(count)
                } else {
                    bandMagnitudes[i] = magnitudes[Int(magsStartIdx)]
                }

                // Compute average frequency
                let bandwidth = sampleRate.nyquistFrequency / Float(magnitudes.count)
                bandFrequencies[i] = (bandwidth * Float(magsStartIdx) + bandwidth * Float(magsEndIdx)) / 2
            }

            return FFTComputeBandsResult(count: bandsCount, magnitudes: bandMagnitudes, frequencies: bandFrequencies)
        }
    }

    @inline(__always) private func _magnitudeIndex(for frequency: Float, sampleRate: Float) -> vDSP_Length {
        vDSP_Length(Float(magnitudes.count) * frequency / sampleRate.nyquistFrequency)
    }
}

class FFTProcessor {
    enum WindowType {
        case none
        case hanning
        case hamming
    }

    let bufferSize: vDSP_Length
    let windowType: WindowType

    private let bufferHalfSize: vDSP_Length
    private let bufferLog2Size: vDSP_Length
    private var window: [Float] = []
    private var fftSetup: FFTSetup
    private var realBuffer: [Float]
    private var imaginaryBuffer: [Float]
    private var zeroDBReference: Float = 1.0

    init(bufferSize: Int, windowType: WindowType = .hanning) {
        self.bufferSize = vDSP_Length(bufferSize)
        self.windowType = windowType

        bufferHalfSize = vDSP_Length(bufferSize / 2)
        bufferLog2Size = vDSP_Length(log2f(Float(bufferSize)))

        realBuffer = [Float](repeating: 0.0, count: Int(bufferHalfSize))
        imaginaryBuffer = [Float](repeating: 0.0, count: Int(bufferHalfSize))
        window = [Float](repeating: 1.0, count: Int(bufferSize))

        fftSetup = vDSP_create_fftsetup(UInt(bufferLog2Size), FFTRadix(FFT_RADIX2))!

        switch windowType {
        case .none:
            break
        case .hanning:
            vDSP_hann_window(&window, vDSP_Length(bufferSize), Int32(vDSP_HANN_NORM))
        case .hamming:
            vDSP_hamm_window(&window, vDSP_Length(bufferSize), 0)
        }
    }

    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }

    func process(buffer: [Float]) -> FFTResult {
        precondition(buffer.count == Int(bufferSize), "Input buffer size mismatch.")

        var windowedBuffer = [Float](repeating: 0.0, count: Int(bufferSize))

        vDSP_vmul(buffer, 1, window, 1, &windowedBuffer, 1, bufferSize)

        return realBuffer.withUnsafeMutableBufferPointer { realPtr in
            imaginaryBuffer.withUnsafeMutableBufferPointer { imagPtr in
                var complexBuffer = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)

                windowedBuffer.withUnsafeBufferPointer { bufferPtr in
                    let complexPtr = UnsafeRawPointer(bufferPtr.baseAddress!).bindMemory(to: DSPComplex.self, capacity: Int(bufferHalfSize))
                    vDSP_ctoz(complexPtr, 2, &complexBuffer, 1, bufferHalfSize)
                }

                vDSP_fft_zrip(fftSetup, &complexBuffer, 1, bufferLog2Size, FFTDirection(FFT_FORWARD))

                var magnitudes = [Float](repeating: 0.0, count: Int(bufferHalfSize))
                vDSP_zvabs(&complexBuffer, 1, &magnitudes, 1, bufferHalfSize)

                // Convert magnitudes to decibels
                vDSP_vdbcon(magnitudes, 1, &zeroDBReference, &magnitudes, 1, vDSP_Length(magnitudes.count), 1)

                return FFTResult(magnitudes: magnitudes)
            }
        }
    }
}
