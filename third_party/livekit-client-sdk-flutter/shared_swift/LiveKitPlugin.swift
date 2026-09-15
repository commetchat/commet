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

import flutter_webrtc
import WebRTC

#if os(macOS)
import Cocoa
import FlutterMacOS
#else
import Combine
import Flutter
import UIKit
#endif

let trackIdKey = "trackId"
let visualizerIdKey = "visualizerId"
let rendererIdKey = "rendererId"
let formatKey = "format"

let commonFormatKey = "commonFormat"
let sampleRateKey = "sampleRate"
let channelsKey = "channels"

class AudioProcessors {
    var track: AudioTrack
    var visualizers: [String: Visualizer] = [:]
    var renderers: [String: AudioRenderer] = [:]

    init(track: AudioTrack) {
        self.track = track
    }
}

@available(iOS 13.0, *)
public class LiveKitPlugin: NSObject, FlutterPlugin {
    // TrackId: AudioProcessors
    var audioProcessors: [String: AudioProcessors] = [:]

    var binaryMessenger: FlutterBinaryMessenger?

    #if os(iOS)
    var cancellable = Set<AnyCancellable>()
    #endif

    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(macOS)
        let messenger = registrar.messenger
        #else
        let messenger = registrar.messenger()
        #endif

        let channel = FlutterMethodChannel(name: "livekit_client", binaryMessenger: messenger)
        let instance = LiveKitPlugin()
        instance.binaryMessenger = messenger
        registrar.addMethodCallDelegate(instance, channel: channel)

        #if os(iOS)
        BroadcastManager.shared.isBroadcastingPublisher
            .sink { isBroadcasting in
                channel.invokeMethod("broadcastStateChanged", arguments: isBroadcasting)
            }
            .store(in: &instance.cancellable)
        #endif
    }

    #if !os(macOS)
    // https://developer.apple.com/documentation/avfaudio/avaudiosession/category
    let categoryMap: [String: AVAudioSession.Category] = [
        "ambient": .ambient,
        "multiRoute": .multiRoute,
        "playAndRecord": .playAndRecord,
        "playback": .playback,
        "record": .record,
        "soloAmbient": .soloAmbient,
    ]

    // https://developer.apple.com/documentation/avfaudio/avaudiosession/categoryoptions
    let categoryOptionsMap: [String: AVAudioSession.CategoryOptions] = [
        "mixWithOthers": .mixWithOthers,
        "duckOthers": .duckOthers,
        "interruptSpokenAudioAndMixWithOthers": .interruptSpokenAudioAndMixWithOthers,
        "allowBluetooth": .allowBluetooth,
        "allowBluetoothA2DP": .allowBluetoothA2DP,
        "allowAirPlay": .allowAirPlay,
        "defaultToSpeaker": .defaultToSpeaker,
        //        @available(iOS 14.5, *)
        //        "overrideMutedMicrophoneInterruption": .overrideMutedMicrophoneInterruption,
    ]

    // https://developer.apple.com/documentation/avfaudio/avaudiosession/mode
    let modeMap: [String: AVAudioSession.Mode] = [
        "default": .default,
        "gameChat": .gameChat,
        "measurement": .measurement,
        "moviePlayback": .moviePlayback,
        "spokenAudio": .spokenAudio,
        "videoChat": .videoChat,
        "videoRecording": .videoRecording,
        "voiceChat": .voiceChat,
        "voicePrompt": .voicePrompt,
    ]

    private func categoryOptions(fromFlutter options: [String]) -> AVAudioSession.CategoryOptions {
        var result: AVAudioSession.CategoryOptions = []
        for option in categoryOptionsMap {
            if options.contains(option.key) {
                result.insert(option.value)
            }
        }
        return result
    }
    #endif

    private func audioProcessors(for trackId: String) -> AudioProcessors? {
        if let existing = audioProcessors[trackId] {
            return existing
        }

        let webrtc = FlutterWebRTCPlugin.sharedSingleton()

        var audioTrack: AudioTrack?
        if let track = webrtc?.localTracks![trackId] as? LocalAudioTrack {
            audioTrack = LKLocalAudioTrack(name: trackId, track: track)
        } else if let track = webrtc?.remoteTrack(forId: trackId) as? RTCAudioTrack {
            audioTrack = LKRemoteAudioTrack(name: trackId, track: track)
        }

        guard let audioTrack else {
            return nil
        }

        let processor = AudioProcessors(track: audioTrack)
        audioProcessors[trackId] = processor
        return processor
    }

    public func handleStartAudioVisualizer(args: [String: Any?], result: @escaping FlutterResult) {
        // Required params
        let trackId = args[trackIdKey] as? String
        let visualizerId = args[visualizerIdKey] as? String

        guard let trackId else {
            result(FlutterError(code: trackIdKey, message: "\(trackIdKey) is required", details: nil))
            return
        }

        guard let visualizerId else {
            result(FlutterError(code: visualizerIdKey, message: "\(visualizerIdKey) is required", details: nil))
            return
        }

        // Optional params
        let barCount = args["barCount"] as? Int ?? 7
        let isCentered = args["isCentered"] as? Bool ?? true
        let smoothTransition = args["smoothTransition"] as? Bool ?? true

        guard let processors = audioProcessors(for: trackId) else {
            result(FlutterError(code: trackIdKey, message: "No such track", details: nil))
            return
        }

        // Already exists
        if processors.visualizers[visualizerId] != nil {
            result(true)
            return
        }

        let visualizer = Visualizer(track: processors.track,
                                    binaryMessenger: binaryMessenger!,
                                    bandCount: barCount,
                                    isCentered: isCentered,
                                    smoothTransition: smoothTransition,
                                    visualizerId: visualizerId)
        // Retain
        processors.visualizers[visualizerId] = visualizer

        result(true)
    }

    public func handleStopAudioVisualizer(args: [String: Any?], result: @escaping FlutterResult) {
        // let trackId = args["trackId"] as? String
        let visualizerId = args[visualizerIdKey] as? String

        guard let visualizerId else {
            result(FlutterError(code: visualizerIdKey, message: "\(visualizerIdKey) is required", details: nil))
            return
        }

        for processors in audioProcessors.values {
            processors.visualizers[visualizerId]?.stop()
            processors.visualizers.removeValue(forKey: visualizerId)
        }

        result(true)
    }

    public func parseAudioFormat(args: [String: Any?]) -> AVAudioFormat? {
        guard let commonFormatString = args[commonFormatKey] as? String,
              let sampleRate = args[sampleRateKey] as? Int,
              let channels = args[channelsKey] as? Int
        else {
            return nil
        }

        let commonFormat: AVAudioCommonFormat
        switch commonFormatString {
        case "float32":
            commonFormat = .pcmFormatFloat32
        case "int16":
            commonFormat = .pcmFormatInt16
        default:
            return nil
        }

        return AVAudioFormat(commonFormat: commonFormat,
                             sampleRate: Double(sampleRate),
                             channels: AVAudioChannelCount(channels),
                             interleaved: false)
    }

    public func handleStartAudioRenderer(args: [String: Any?], result: @escaping FlutterResult) {
        // Required params
        let trackId = args[trackIdKey] as? String
        let rendererId = args[rendererIdKey] as? String

        let formatMap = args[formatKey] as? [String: Any?]

        guard let formatMap else {
            result(FlutterError(code: formatKey, message: "\(formatKey) is required", details: nil))
            return
        }

        guard let format = parseAudioFormat(args: formatMap) else {
            result(FlutterError(code: formatKey, message: "Failed to parse format", details: nil))
            return
        }

        guard let trackId else {
            result(FlutterError(code: trackIdKey, message: "\(trackIdKey) is required", details: nil))
            return
        }

        guard let rendererId else {
            result(FlutterError(code: rendererIdKey, message: "\(rendererIdKey) is required", details: nil))
            return
        }

        guard let processors = audioProcessors(for: trackId) else {
            result(FlutterError(code: trackIdKey, message: "No such track", details: nil))
            return
        }

        // Already exists
        if processors.renderers[rendererId] != nil {
            result(true)
            return
        }

        let renderer = AudioRenderer(track: processors.track,
                                     binaryMessenger: binaryMessenger!,
                                     rendererId: rendererId,
                                     format: format)
        // Retain
        processors.renderers[rendererId] = renderer

        result(true)
    }

    public func handleStopAudioRenderer(args: [String: Any?], result: @escaping FlutterResult) {
        let rendererId = args[rendererIdKey] as? String

        guard let rendererId else {
            result(FlutterError(code: rendererIdKey, message: "\(rendererIdKey) is required", details: nil))
            return
        }

        for processors in audioProcessors.values {
            if let renderer = processors.renderers[rendererId] {
                renderer.detach()
                processors.renderers.removeValue(forKey: rendererId)
            }
        }

        result(true)
    }

    public func handleConfigureNativeAudio(args: [String: Any?], result: @escaping FlutterResult) {
        #if os(macOS)
        result(FlutterMethodNotImplemented)
        #else

        let configuration = RTCAudioSessionConfiguration.webRTC()

        // Category
        if let string = args["appleAudioCategory"] as? String,
           let category = categoryMap[string]
        {
            configuration.category = category.rawValue
            print("[LiveKit] Configuring category: ", configuration.category)
        }

        // CategoryOptions
        if let strings = args["appleAudioCategoryOptions"] as? [String] {
            configuration.categoryOptions = categoryOptions(fromFlutter: strings)
            print("[LiveKit] Configuring categoryOptions: ", strings)
        }

        // Mode
        if let string = args["appleAudioMode"] as? String,
           let mode = modeMap[string]
        {
            configuration.mode = mode.rawValue
            print("[LiveKit] Configuring mode: ", configuration.mode)
        }

        // get `RTCAudioSession` and lock
        let rtcSession = RTCAudioSession.sharedInstance()
        rtcSession.lockForConfiguration()

        var isLocked = true
        let unlock = {
            guard isLocked else {
                print("[LiveKit] not locked, ignoring unlock")
                return
            }
            rtcSession.unlockForConfiguration()
            isLocked = false
        }

        // always `unlock()` when exiting scope, calling multiple times has no side-effect
        defer {
            unlock()
        }

        do {
            try rtcSession.setConfiguration(configuration, active: true)
            // unlock here before configuring `AVAudioSession`
            // unlock()
            print("[LiveKit] RTCAudioSession Configure success")

            // also configure longFormAudio
            // let avSession = AVAudioSession.sharedInstance()
            // try avSession.setCategory(AVAudioSession.Category(rawValue: configuration.category),
            //                      mode: AVAudioSession.Mode(rawValue: configuration.mode),
            //                      policy: .default,
            //                      options: configuration.categoryOptions)
            // print("[LiveKit] AVAudioSession Configure success")

            // preferSpeakerOutput
            if let preferSpeakerOutput = args["preferSpeakerOutput"] as? Bool {
                try rtcSession.overrideOutputAudioPort(preferSpeakerOutput ? .speaker : .none)
            }
            result(true)
        } catch {
            print("[LiveKit] Configure audio error: ", error)
            result(FlutterError(code: "configure", message: error.localizedDescription, details: nil))
        }
        #endif
    }

    private static let processInfo = ProcessInfo()

    /// Returns os version as a string.
    /// format: `12.1`, `15.3.1`, `15.0.1`
    private static func osVersionString() -> String {
        let osVersion = processInfo.operatingSystemVersion
        var versions = [osVersion.majorVersion]
        if osVersion.minorVersion != 0 || osVersion.patchVersion != 0 {
            versions.append(osVersion.minorVersion)
        }
        if osVersion.patchVersion != 0 {
            versions.append(osVersion.patchVersion)
        }
        return versions.map { String($0) }.joined(separator: ".")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any?] else {
            print("[LiveKit] arguments must be a dictionary")
            result(FlutterMethodNotImplemented)
            return
        }

        switch call.method {
        case "configureNativeAudio":
            handleConfigureNativeAudio(args: args, result: result)
        case "startVisualizer":
            handleStartAudioVisualizer(args: args, result: result)
        case "stopVisualizer":
            handleStopAudioVisualizer(args: args, result: result)
        case "startAudioRenderer":
            handleStartAudioRenderer(args: args, result: result)
        case "stopAudioRenderer":
            handleStopAudioRenderer(args: args, result: result)
        case "osVersionString":
            result(LiveKitPlugin.osVersionString())
        #if os(iOS)
        case "broadcastRequestActivation":
            BroadcastManager.shared.requestActivation()
            result(true)
        case "broadcastRequestStop":
            BroadcastManager.shared.requestStop()
            result(true)
        #endif
        default:
            print("[LiveKit] method not found: ", call.method)
            result(FlutterMethodNotImplemented)
        }
    }
}
