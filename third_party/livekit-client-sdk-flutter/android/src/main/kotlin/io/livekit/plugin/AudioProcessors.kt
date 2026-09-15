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
 * Container for managing audio processors (renderers and visualizers) for a specific audio track
 * Similar to iOS AudioProcessors implementation
 */
class AudioProcessors(
  val track: LKAudioTrack
) {
  val renderers = mutableMapOf<String, AudioRenderer>()
  val visualizers = mutableMapOf<String, Visualizer>()

  /**
   * Clean up all processors and release resources
   */
  fun cleanup() {
    renderers.values.forEach { it.detach() }
    renderers.clear()

    visualizers.values.forEach { it.stop() }
    visualizers.clear()
  }
}
