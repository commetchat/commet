// COMMET: hook Commet's Rust voice DSP into libwebrtc's audio processing
// module. Used by the Linux and Windows plugin implementations.
//
// libwebrtc (webrtc-sdk) exposes two custom processing slots on the APM:
// capture post-processing (after AEC/NS, before encoding) and render
// pre-processing (playout, before it reaches the AEC reference). Both receive
// one 10 ms block of channel 0 as int16-scale floats.
//
// Dart passes raw function pointers (looked up in librust_lib_commet via
// dart:ffi) plus an opaque context. We wrap them in CustomProcessing objects
// and hand those to the APM. The APM keeps raw pointers, so the objects live
// here until they are cleared; clear before the Rust handle is destroyed.
#ifndef COMMET_EXTERNAL_AUDIO_PROCESSING_H_
#define COMMET_EXTERNAL_AUDIO_PROCESSING_H_

#include <cstdint>
#include <memory>
#include <mutex>

#include "rtc_audio_processing.h"

namespace livekit_client_plugin {

typedef void (*CommetDspInitFn)(void* ctx, int sample_rate_hz, int num_channels);
typedef void (*CommetDspProcessFn)(void* ctx, int num_bands, int num_frames,
                                   int buffer_size, float* buffer);
typedef void (*CommetDspResetFn)(void* ctx, int new_rate);

class CommetExternalAudioProcessor
    : public libwebrtc::RTCAudioProcessing::CustomProcessing {
 public:
  CommetExternalAudioProcessor(void* ctx, CommetDspInitFn init,
                               CommetDspProcessFn process,
                               CommetDspResetFn reset)
      : ctx_(ctx), init_(init), process_(process), reset_(reset) {}
  ~CommetExternalAudioProcessor() override {}

  void Initialize(int sample_rate_hz, int num_channels) override {
    if (init_) init_(ctx_, sample_rate_hz, num_channels);
  }
  void Process(int num_bands, int num_frames, int buffer_size,
               float* buffer) override {
    if (process_) process_(ctx_, num_bands, num_frames, buffer_size, buffer);
  }
  void Reset(int new_rate) override {
    if (reset_) reset_(ctx_, new_rate);
  }
  // Lifetime is owned by CommetExternalAudioProcessingHost, not libwebrtc.
  void Release() override {}

 private:
  void* ctx_;
  CommetDspInitFn init_;
  CommetDspProcessFn process_;
  CommetDspResetFn reset_;
};

class CommetExternalAudioProcessingHost {
 public:
  explicit CommetExternalAudioProcessingHost(
      libwebrtc::scoped_refptr<libwebrtc::RTCAudioProcessing> apm)
      : apm_(apm) {}

  ~CommetExternalAudioProcessingHost() { Clear(); }

  bool available() const { return apm_ != nullptr; }

  // Passing null function pointers clears that slot.
  void SetCapture(void* ctx, CommetDspInitFn init, CommetDspProcessFn process,
                  CommetDspResetFn reset) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!apm_) return;
    // Detach first: the APM swaps the pointer under its own lock, so once
    // this returns no audio thread is inside the old processor.
    apm_->SetCapturePostProcessing(nullptr);
    capture_.reset();
    if (process) {
      capture_ = std::make_unique<CommetExternalAudioProcessor>(ctx, init,
                                                                process, reset);
      apm_->SetCapturePostProcessing(capture_.get());
    }
  }

  void SetRender(void* ctx, CommetDspInitFn init, CommetDspProcessFn process,
                 CommetDspResetFn reset) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!apm_) return;
    apm_->SetRenderPreProcessing(nullptr);
    render_.reset();
    if (process) {
      render_ = std::make_unique<CommetExternalAudioProcessor>(ctx, init,
                                                               process, reset);
      apm_->SetRenderPreProcessing(render_.get());
    }
  }

  void Clear() {
    SetCapture(nullptr, nullptr, nullptr, nullptr);
    SetRender(nullptr, nullptr, nullptr, nullptr);
  }

 private:
  libwebrtc::scoped_refptr<libwebrtc::RTCAudioProcessing> apm_;
  std::unique_ptr<CommetExternalAudioProcessor> capture_;
  std::unique_ptr<CommetExternalAudioProcessor> render_;
  std::mutex mutex_;
};

}  // namespace livekit_client_plugin

#endif  // COMMET_EXTERNAL_AUDIO_PROCESSING_H_
