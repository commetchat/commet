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
import Foundation
import WebRTC

public class LKRemoteAudioTrack: Track, AudioTrack {
    let audioTrack: RTCAudioTrack
    init(name _: String,
         track: RTCAudioTrack)
    {
        audioTrack = track
        super.init(track: track)
    }
}

public extension LKRemoteAudioTrack {
    func add(audioRenderer: RTCAudioRenderer) {
        audioTrack.add(audioRenderer)
    }

    func remove(audioRenderer: RTCAudioRenderer) {
        audioTrack.remove(audioRenderer)
    }
}
