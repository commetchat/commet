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

import com.cloudwebrtc.webrtc.audio.LocalAudioTrack
import org.webrtc.AudioTrackSink

class LKLocalAudioTrack(localAudioTrack: LocalAudioTrack) : LKAudioTrack {
    private var localAudioTrack: LocalAudioTrack? = localAudioTrack

    override fun addSink(sink: AudioTrackSink?) {
        localAudioTrack?.addSink(sink)
    }

    override fun removeSink(sink: AudioTrackSink) {
        localAudioTrack?.removeSink(sink)
    }

    override fun id(): String {
        return localAudioTrack?.id() ?: ""
    }
}