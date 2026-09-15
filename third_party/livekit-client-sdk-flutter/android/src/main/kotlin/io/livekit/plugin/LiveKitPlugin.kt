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

import android.annotation.SuppressLint
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import com.cloudwebrtc.webrtc.FlutterWebRTCPlugin
import com.cloudwebrtc.webrtc.audio.LocalAudioTrack
import io.flutter.plugin.common.BinaryMessenger
import org.webrtc.AudioTrack

/** LiveKitPlugin */
class LiveKitPlugin : FlutterPlugin, MethodCallHandler {
  private var audioProcessors = mutableMapOf<String, AudioProcessors>()
  private var flutterWebRTCPlugin = FlutterWebRTCPlugin.sharedSingleton
  private var binaryMessenger: BinaryMessenger? = null

  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel: MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "livekit_client")
    channel.setMethodCallHandler(this)
    binaryMessenger = flutterPluginBinding.binaryMessenger
  }

  @SuppressLint("SuspiciousIndentation")
  private fun handleStartVisualizer(@NonNull call: MethodCall, @NonNull result: Result) {
    val trackId = call.argument<String>("trackId")
    val visualizerId = call.argument<String>("visualizerId")
    if (trackId == null || visualizerId == null) {
      result.error("INVALID_ARGUMENT", "trackId and visualizerId is required", null)
      return
    }

    val barCount = call.argument<Int>("barCount") ?: 7
    val isCentered = call.argument<Boolean>("isCentered") ?: true
    var smoothTransition = call.argument<Boolean>("smoothTransition") ?: true

    val processors = getAudioProcessors(trackId)
    if (processors == null) {
      result.error("INVALID_ARGUMENT", "track not found", null)
      return
    }

    // Check if visualizer already exists
    if (processors.visualizers[visualizerId] != null) {
      result.success(null)
      return
    }

    val visualizer = Visualizer(
      barCount = barCount,
      isCentered = isCentered,
      smoothTransition = smoothTransition,
      audioTrack = processors.track,
      binaryMessenger = binaryMessenger!!,
      visualizerId = visualizerId
    )

    processors.visualizers[visualizerId] = visualizer
    result.success(null)
  }

  private fun handleStopVisualizer(@NonNull call: MethodCall, @NonNull result: Result) {
    val trackId = call.argument<String>("trackId")
    val visualizerId = call.argument<String>("visualizerId")
    if (trackId == null || visualizerId == null) {
      result.error("INVALID_ARGUMENT", "trackId and visualizerId is required", null)
      return
    }

    // Find and remove visualizer from all processors
    for (processors in audioProcessors.values) {
      processors.visualizers[visualizerId]?.let { visualizer ->
        visualizer.stop()
        processors.visualizers.remove(visualizerId)
      }
    }

    result.success(null)
  }

  /**
   * Get or create AudioProcessors for a given trackId
   */
  private fun getAudioProcessors(trackId: String): AudioProcessors? {
    // Return existing if found
    audioProcessors[trackId]?.let { return it }

    // Create new AudioProcessors for this track
    var audioTrack: LKAudioTrack? = null

    val localTrack = flutterWebRTCPlugin.getLocalTrack(trackId)
    if (localTrack != null) {
      audioTrack = LKLocalAudioTrack(localTrack as LocalAudioTrack)
    } else {
      val remoteTrack = flutterWebRTCPlugin.getRemoteTrack(trackId)
      if (remoteTrack != null) {
        audioTrack = LKRemoteAudioTrack(remoteTrack as AudioTrack)
      }
    }

    return audioTrack?.let { track ->
      val processors = AudioProcessors(track)
      audioProcessors[trackId] = processors
      processors
    }
  }

  /**
   * Handle startAudioRenderer method call
   */
  private fun handleStartAudioRenderer(@NonNull call: MethodCall, @NonNull result: Result) {
    val trackId = call.argument<String>("trackId")
    val rendererId = call.argument<String>("rendererId")
    val formatMap = call.argument<Map<String, Any?>>("format")

    if (trackId == null) {
      result.error("INVALID_ARGUMENT", "trackId is required", null)
      return
    }

    if (rendererId == null) {
      result.error("INVALID_ARGUMENT", "rendererId is required", null)
      return
    }

    if (formatMap == null) {
      result.error("INVALID_ARGUMENT", "format is required", null)
      return
    }

    val format = RendererAudioFormat.fromMap(formatMap)
    if (format == null) {
      result.error("INVALID_ARGUMENT", "Failed to parse format", null)
      return
    }

    val processors = getAudioProcessors(trackId)
    if (processors == null) {
      result.error("INVALID_ARGUMENT", "No such track", null)
      return
    }

    // Check if renderer already exists
    if (processors.renderers[rendererId] != null) {
      result.success(true)
      return
    }

    try {
      val renderer = AudioRenderer(
        processors.track,
        binaryMessenger!!,
        rendererId,
        format,
      )

      processors.renderers[rendererId] = renderer
      result.success(true)
    } catch (e: Exception) {
      result.error("RENDERER_ERROR", "Failed to create audio renderer: ${e.message}", null)
    }
  }

  /**
   * Handle stopAudioRenderer method call
   */
  private fun handleStopAudioRenderer(@NonNull call: MethodCall, @NonNull result: Result) {
    val rendererId = call.argument<String>("rendererId")

    if (rendererId == null) {
      result.error("INVALID_ARGUMENT", "rendererId is required", null)
      return
    }

    // Find and remove renderer from all processors
    for (processors in audioProcessors.values) {
      processors.renderers[rendererId]?.let { renderer ->
        renderer.detach()
        processors.renderers.remove(rendererId)
      }
    }

    result.success(true)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "startVisualizer" -> {
        handleStartVisualizer(call, result)
      }

      "stopVisualizer" -> {
        handleStopVisualizer(call, result)
      }

      "startAudioRenderer" -> {
        handleStartAudioRenderer(call, result)
      }

      "stopAudioRenderer" -> {
        handleStopAudioRenderer(call, result)
      }

      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)

    // Cleanup all processors
    audioProcessors.values.forEach { it.cleanup() }
    audioProcessors.clear()
  }
}
