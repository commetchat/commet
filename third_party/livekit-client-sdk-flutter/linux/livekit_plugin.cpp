// Copyright 2024 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "include/livekit_client/live_kit_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/standard_method_codec.h>

#include <flutter_common.h>
#include <flutter_webrtc.h>
#include <flutter_webrtc/flutter_web_r_t_c_plugin.h>

#include <algorithm>
#include <cstring>
#include <iomanip>
#include <map>
#include <memory>
#include <sstream>

#include "audio_visualizer.h"
#include "commet_external_audio_processing.h"  // COMMET

#include "task_runner_linux.h"

namespace livekit_client_plugin {

/// Centers the sorted bands by placing higher values in the middle.
std::vector<float> centerBands(const std::vector<float> &sortedBands) {
  std::vector<float> centeredBands(sortedBands.size(), 0);
  size_t leftIndex = sortedBands.size() / 2;
  size_t rightIndex = leftIndex;

  for (size_t index = 0; index < sortedBands.size(); ++index) {
    if (index % 2 == 0) {
      // Place value to the right
      centeredBands[rightIndex] = sortedBands[index];
      rightIndex += 1;
    } else {
      // Place value to the left
      leftIndex -= 1;
      centeredBands[leftIndex] = sortedBands[index];
    }
  }

  return centeredBands;
}

class VisualizerSink : public libwebrtc::AudioTrackSink {
public:
  VisualizerSink(BinaryMessenger *messenger, std::string event_channel_name,
                 libwebrtc::scoped_refptr<libwebrtc::RTCMediaTrack> media_track,
                 bool is_centered = false, int bar_count = 7)
      : channel_(
            std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
                messenger, event_channel_name,
                &flutter::StandardMethodCodec::GetInstance())),
        media_track_(media_track), is_centered_(is_centered),
        bar_count_(bar_count) {
    task_runner_ = std::make_unique<livekit_client_plugin::TaskRunnerLinux>();
    auto handler = std::make_unique<
        flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
        [&](const flutter::EncodableValue *arguments,
            std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>
                &&events)
            -> std::unique_ptr<
                flutter::StreamHandlerError<flutter::EncodableValue>> {
          sink_ = std::move(events);
          std::weak_ptr<flutter::EventSink<flutter::EncodableValue>> weak_sink =
              sink_;
          for (auto &event : event_queue_) {
            PostEvent(event);
          }
          event_queue_.clear();
          on_listen_called_ = true;
          return nullptr;
        },
        [&](const flutter::EncodableValue *arguments)
            -> std::unique_ptr<
                flutter::StreamHandlerError<flutter::EncodableValue>> {
          on_listen_called_ = false;
          return nullptr;
        });

    channel_->SetStreamHandler(std::move(handler));
    audio_visualizer_ =
        std::make_unique<AudioVisualizer>(bar_count_, is_centered_);
    ((libwebrtc::RTCAudioTrack *)media_track_.get())->AddSink(this);
  }
  ~VisualizerSink() override {}

public:
  void OnData(const void *audio_data, int bits_per_sample, int sample_rate,
              size_t number_of_channels, size_t number_of_frames) override {
    if (!on_listen_called_) {
      return;
    }
    std::vector<float> bands;
    if (audio_visualizer_->Process((const int16_t *)audio_data,
                                   (unsigned int)number_of_frames,
                                   float(sample_rate), bands)) {
      // Post the processed data to the event sink
      EncodableList bands_list = EncodableList(bands.begin(), bands.end());
      Success(EncodableValue(bands_list));
    }
  }

  void Success(const flutter::EncodableValue &event, bool cache_event = true) {
    if (on_listen_called_) {
      PostEvent(event);
    } else {
      if (cache_event) {
        event_queue_.push_back(event);
      }
    }
  }

  void PostEvent(const flutter::EncodableValue &event) {
    if (task_runner_) {
      std::weak_ptr<flutter::EventSink<EncodableValue>> weak_sink = sink_;
      task_runner_->EnqueueTask([weak_sink, event]() {
        auto sink = weak_sink.lock();
        if (sink) {
          sink->Success(event);
        }
      });
    } else {
      sink_->Success(event);
    }
  }

  void RemoveSink() {
    ((libwebrtc::RTCAudioTrack *)media_track_.get())->RemoveSink(this);
  }

private:
  std::unique_ptr<AudioVisualizer> audio_visualizer_;
  std::unique_ptr<livekit_client_plugin::TaskRunnerLinux> task_runner_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> channel_;
  std::shared_ptr<flutter::EventSink<flutter::EncodableValue>> sink_;
  std::list<flutter::EncodableValue> event_queue_;
  bool on_listen_called_ = false;
  libwebrtc::scoped_refptr<libwebrtc::RTCMediaTrack> media_track_;
  bool is_centered_ = false;
  int bar_count_ = 7;
};

class LiveKitPlugin : public flutter::Plugin {
public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar *registrar);

  LiveKitPlugin(BinaryMessenger *messenger);

  virtual ~LiveKitPlugin();

private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

private:
  flutter_webrtc_plugin::FlutterWebRTC *webrtc_instance_ = nullptr;
  // COMMET: owns the processors installed on the shared APM.
  std::unique_ptr<CommetExternalAudioProcessingHost> audio_processing_host_;
  std::unordered_map<std::string, std::unique_ptr<VisualizerSink>> visualizers_;
  BinaryMessenger *messenger_ = nullptr;
  mutable std::mutex mutex_;
};

// static
void LiveKitPlugin::RegisterWithRegistrar(flutter::PluginRegistrar *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "livekit_client",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<LiveKitPlugin>(registrar->messenger());

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

LiveKitPlugin::LiveKitPlugin(BinaryMessenger *messenger)
    : messenger_(messenger) {
  webrtc_instance_ = flutter_webrtc_plugin_get_shared_instance();
  // COMMET
  if (webrtc_instance_) {
    audio_processing_host_ = std::make_unique<CommetExternalAudioProcessingHost>(
        webrtc_instance_->audio_processing());
  }
}

LiveKitPlugin::~LiveKitPlugin() {}

void LiveKitPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("startVisualizer") == 0) {
    if (!method_call.arguments()) {
      result->Error("Bad Arguments", "Null arguments received");
      return;
    }
    flutter::EncodableMap params =
        GetValue<flutter::EncodableMap>(*method_call.arguments());
    std::string trackId = findString(params, "trackId");
    std::string visualizerId = findString(params, "visualizerId");
    int barCount = findInt(params, "barCount");
    bool isCentered = findBoolean(params, "isCentered");
    if (trackId.empty() || visualizerId.empty()) {
      result->Error("Invalid Arguments",
                    "trackId and visualizerId are required");
      return;
    }
    libwebrtc::scoped_refptr<libwebrtc::RTCMediaTrack> media_track =
        webrtc_instance_->MediaTrackForId(trackId);
    if (!media_track) {
      result->Error("Track Not Found", "No media track found for the given ID");
      return;
    }
    std::ostringstream oss;
    oss << "io.livekit.audio.visualizer/eventChannel-" << trackId << "-"
        << visualizerId;

    mutex_.lock();
    visualizers_[visualizerId] = std::make_unique<VisualizerSink>(
        messenger_, oss.str(), media_track, isCentered, barCount);
    mutex_.unlock();

    result->Success(flutter::EncodableValue(true));
  } else if (method_call.method_name().compare("stopVisualizer") == 0) {
    if (!method_call.arguments()) {
      result->Error("Bad Arguments", "Null arguments received");
      return;
    }
    flutter::EncodableMap args =
        GetValue<flutter::EncodableMap>(*method_call.arguments());
    std::string trackId = findString(args, "trackId");
    std::string visualizerId = findString(args, "visualizerId");
    if (trackId.empty() || visualizerId.empty()) {
      result->Error("Invalid Arguments",
                    "trackId and visualizerId are required");
      return;
    }
    libwebrtc::scoped_refptr<libwebrtc::RTCMediaTrack> media_track =
        webrtc_instance_->MediaTrackForId(trackId);
    if (!media_track) {
      result->Error("Track Not Found", "No media track found for the given ID");
      return;
    }

    mutex_.lock();
    auto it = visualizers_.find(visualizerId);
    if (it != visualizers_.end()) {
      it->second->RemoveSink();
      visualizers_.erase(it);
      mutex_.unlock();
    } else {
      mutex_.unlock();
      result->Error("Visualizer Not Found",
                    "No visualizer found for the given visualizerId");
      return;
    }

    result->Success();
  } else if (method_call.method_name().compare(
                 "commetSetExternalAudioProcessing") == 0) {
    // COMMET: install Commet's DSP callbacks on the capture post-processing
    // and render pre-processing slots of the APM. All values are pointer
    // sized integers; a zero process pointer clears that slot.
    if (!method_call.arguments()) {
      result->Error("Bad Arguments", "Null arguments received");
      return;
    }
    if (!audio_processing_host_ || !audio_processing_host_->available()) {
      result->Error("Unavailable", "Audio processing module not available");
      return;
    }
    flutter::EncodableMap args =
        GetValue<flutter::EncodableMap>(*method_call.arguments());
    auto ptr = [&args](const char *key) -> uintptr_t {
      auto it = args.find(flutter::EncodableValue(key));
      if (it == args.end() || it->second.IsNull()) return 0;
      return static_cast<uintptr_t>(it->second.LongValue());
    };
    void *ctx = reinterpret_cast<void *>(ptr("ctx"));
    audio_processing_host_->SetCapture(
        ctx, reinterpret_cast<CommetDspInitFn>(ptr("captureInit")),
        reinterpret_cast<CommetDspProcessFn>(ptr("captureProcess")),
        reinterpret_cast<CommetDspResetFn>(ptr("captureReset")));
    audio_processing_host_->SetRender(
        ctx, reinterpret_cast<CommetDspInitFn>(ptr("renderInit")),
        reinterpret_cast<CommetDspProcessFn>(ptr("renderProcess")),
        reinterpret_cast<CommetDspResetFn>(ptr("renderReset")));
    result->Success(flutter::EncodableValue(true));
  } else if (method_call.method_name().compare(
                 "commetClearExternalAudioProcessing") == 0) {
    if (audio_processing_host_) {
      audio_processing_host_->Clear();
    }
    result->Success(flutter::EncodableValue(true));
  } else {
    result->NotImplemented();
  }
}

} // namespace livekit_client_plugin

void live_kit_plugin_register_with_registrar(FlPluginRegistrar *registrar) {
  static auto *plugin_registrar = new flutter::PluginRegistrar(registrar);
  livekit_client_plugin::LiveKitPlugin::RegisterWithRegistrar(plugin_registrar);
}