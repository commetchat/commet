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

import AVFoundation
import WebRTC

#if os(macOS)
import Cocoa
import FlutterMacOS
#else
import Flutter
import UIKit
#endif

public class AudioRenderer: NSObject {
    public let rendererId: String
    public let format: AVAudioFormat // Target format

    private var eventSink: FlutterEventSink?
    private var channel: FlutterEventChannel?

    private var converter: AudioConverter?

    // Weak ref
    private weak var _track: AudioTrack?

    public init(track: AudioTrack,
                binaryMessenger: FlutterBinaryMessenger,
                rendererId: String,
                format: AVAudioFormat)
    {
        _track = track
        self.rendererId = rendererId
        self.format = format

        super.init()
        _track?.add(audioRenderer: self)

        let channelName = "io.livekit.audio.renderer/channel-" + rendererId
        channel = FlutterEventChannel(name: channelName, binaryMessenger: binaryMessenger)
        channel?.setStreamHandler(self)
    }

    func detach() {
        _track?.remove(audioRenderer: self)
        channel?.setStreamHandler(nil)
        channel = nil
        eventSink = nil
    }

    deinit {
        detach()
    }
}

extension AudioRenderer: FlutterStreamHandler {
    public func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    public func onCancel(withArguments _: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}

public extension AVAudioPCMBuffer {
    /// Serializes audio data as raw interleaved bytes.
    ///
    /// Mono buffers are copied directly.
    /// Multi-channel buffers are interleaved in sample order.
    ///
    /// Uses `FlutterStandardTypedData` to send a binary payload.
    func serializeAsBytes() -> [String: Any] {
        let channels = Int(format.channelCount)
        let frames = Int(frameLength)

        var result: [String: Any] = [
            "sampleRate": UInt(format.sampleRate),
            "channels": UInt(channels),
            "frameLength": UInt(frames),
        ]

        if let int16ChannelData {
            let data: Data
            if channels == 1 {
                // Fast path for mono.
                data = Data(bytes: int16ChannelData[0], count: frames * MemoryLayout<Int16>.size)
            } else {
                // Interleave channels
                var bytes = Data(count: frames * channels * MemoryLayout<Int16>.size)
                bytes.withUnsafeMutableBytes { raw in
                    let out = raw.bindMemory(to: Int16.self)
                    for frame in 0..<frames {
                        for ch in 0..<channels {
                            out[frame * channels + ch] = int16ChannelData[ch][frame]
                        }
                    }
                }
                data = bytes
            }
            result["data"] = FlutterStandardTypedData(bytes: data)
            result["commonFormat"] = "int16"
        } else if let floatChannelData {
            let data: Data
            if channels == 1 {
                data = Data(bytes: floatChannelData[0], count: frames * MemoryLayout<Float32>.size)
            } else {
                var bytes = Data(count: frames * channels * MemoryLayout<Float32>.size)
                bytes.withUnsafeMutableBytes { raw in
                    let out = raw.bindMemory(to: Float32.self)
                    for frame in 0..<frames {
                        for ch in 0..<channels {
                            out[frame * channels + ch] = floatChannelData[ch][frame]
                        }
                    }
                }
                data = bytes
            }
            result["data"] = FlutterStandardTypedData(bytes: data)
            result["commonFormat"] = "float32"
        } else {
            result["data"] = FlutterStandardTypedData(bytes: Data())
            result["commonFormat"] = "unknown"
        }

        return result
    }
}

extension AudioRenderer: RTCAudioRenderer {
    public func render(pcmBuffer: AVAudioPCMBuffer) {
        guard let eventSink else { return }

        // Create or update converter if needed
        if converter == nil || pcmBuffer.format != converter!.inputFormat || format != converter!.outputFormat {
            converter = AudioConverter(from: pcmBuffer.format, to: format)
        }

        let convertedBuffer = converter!.convert(from: pcmBuffer)

        guard convertedBuffer.frameLength > 0 else { return }

        let serializedBuffer = convertedBuffer.serializeAsBytes()

        // Send the result to Flutter on the main thread
        DispatchQueue.main.async {
            eventSink(serializedBuffer)
        }
    }
}
