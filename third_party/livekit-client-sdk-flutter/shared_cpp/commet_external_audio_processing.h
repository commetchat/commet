// COMMET: hook Commet's Rust voice DSP into libwebrtc's audio processing
// module. Used by the Linux and Windows plugin implementations.
//
// libwebrtc (webrtc-sdk) exposes two custom processing slots on the APM:
// capture post-processing (after AEC/NS, before encoding) and render
// pre-processing (playout, before it reaches the AEC reference). Both receive
// one 10 ms block of channel 0 as int16-scale floats.
//
// Dart passes raw function pointers (looked up in librust_lib_commet via
// dart:ffi) plus an opaque context. We keep one long-lived proxy object per
// slot, install it on the APM exactly once, and swap the callbacks inside it.
//
// Why a proxy and not install/remove: libwebrtc's CustomProcessingAdapter
// (src/rtc_audio_processing_impl.cc) does
//
//   custom_processor_ = processor;
//   if (initialized_) custom_processor_->Initialize(rate, channels);
//
// with no null check. Once a microphone track exists the adapter is
// initialized, so passing nullptr to SetCapturePostProcessing /
// SetRenderPreProcessing (to clear or to detach before re-installing)
// dereferences null and takes the whole process down. That is exactly what
// happened when joining a voice room: the mic track is created right before
// the DSP is installed. So: never hand libwebrtc a null pointer, and never
// let the proxy die while the APM exists. With no callbacks set the proxy is
// a no-op and the pipeline behaves as if nothing were installed.
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
  CommetExternalAudioProcessor() {}
  ~CommetExternalAudioProcessor() override {}

  // Swap the callbacks. A null `process` clears the slot. If the APM has
  // already initialized this slot, the new callbacks get an Initialize with
  // the last known format so the Rust side runs at the right rate. Waits for
  // any in-flight Process on the audio thread, so once this returns the old
  // ctx is no longer referenced and may be destroyed.
  void Set(void* ctx, CommetDspInitFn init, CommetDspProcessFn process,
           CommetDspResetFn reset) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (process) {
      ctx_ = ctx;
      init_ = init;
      process_ = process;
      reset_ = reset;
      if (initialized_ && init_) init_(ctx_, sample_rate_hz_, num_channels_);
    } else {
      ctx_ = nullptr;
      init_ = nullptr;
      process_ = nullptr;
      reset_ = nullptr;
    }
  }

  void Clear() { Set(nullptr, nullptr, nullptr, nullptr); }

  bool active() {
    std::lock_guard<std::mutex> lock(mutex_);
    return process_ != nullptr;
  }

  // libwebrtc::RTCAudioProcessing::CustomProcessing
  void Initialize(int sample_rate_hz, int num_channels) override {
    std::lock_guard<std::mutex> lock(mutex_);
    sample_rate_hz_ = sample_rate_hz;
    num_channels_ = num_channels;
    initialized_ = true;
    if (init_) init_(ctx_, sample_rate_hz, num_channels);
  }
  void Process(int num_bands, int num_frames, int buffer_size,
               float* buffer) override {
    // Uncontended except while Set/Clear runs, same cost as the lock
    // libwebrtc's own adapter takes around this call.
    std::lock_guard<std::mutex> lock(mutex_);
    if (process_) process_(ctx_, num_bands, num_frames, buffer_size, buffer);
  }
  void Reset(int new_rate) override {
    std::lock_guard<std::mutex> lock(mutex_);
    sample_rate_hz_ = new_rate;
    if (reset_) reset_(ctx_, new_rate);
  }
  // Lifetime is owned by CommetExternalAudioProcessingHost, not libwebrtc.
  void Release() override {}

 private:
  std::mutex mutex_;
  void* ctx_ = nullptr;
  CommetDspInitFn init_ = nullptr;
  CommetDspProcessFn process_ = nullptr;
  CommetDspResetFn reset_ = nullptr;
  bool initialized_ = false;
  int sample_rate_hz_ = 0;
  int num_channels_ = 0;
};

class CommetExternalAudioProcessingHost {
 public:
  explicit CommetExternalAudioProcessingHost(
      libwebrtc::scoped_refptr<libwebrtc::RTCAudioProcessing> apm)
      : apm_(apm),
        capture_(std::make_unique<CommetExternalAudioProcessor>()),
        render_(std::make_unique<CommetExternalAudioProcessor>()) {}

  // The APM keeps raw pointers to the proxies. The host lives as long as the
  // plugin, which outlives every call, so only the callbacks are detached
  // here; the proxies themselves are not unregistered (see file comment).
  ~CommetExternalAudioProcessingHost() { Clear(); }

  bool available() const { return apm_ != nullptr; }

  // Passing a null `process` clears that slot.
  void SetCapture(void* ctx, CommetDspInitFn init, CommetDspProcessFn process,
                  CommetDspResetFn reset) {
    if (!apm_) return;
    capture_->Set(ctx, init, process, reset);
    InstallOnce();
  }

  void SetRender(void* ctx, CommetDspInitFn init, CommetDspProcessFn process,
                 CommetDspResetFn reset) {
    if (!apm_) return;
    render_->Set(ctx, init, process, reset);
    InstallOnce();
  }

  void Clear() {
    capture_->Clear();
    render_->Clear();
  }

 private:
  void InstallOnce() {
    std::lock_guard<std::mutex> lock(install_mutex_);
    if (installed_) return;
    // libwebrtc calls Initialize on these right away if the APM is already
    // running, otherwise when it starts.
    apm_->SetCapturePostProcessing(capture_.get());
    apm_->SetRenderPreProcessing(render_.get());
    installed_ = true;
  }

  libwebrtc::scoped_refptr<libwebrtc::RTCAudioProcessing> apm_;
  std::unique_ptr<CommetExternalAudioProcessor> capture_;
  std::unique_ptr<CommetExternalAudioProcessor> render_;
  std::mutex install_mutex_;
  bool installed_ = false;
};

}  // namespace livekit_client_plugin

#endif  // COMMET_EXTERNAL_AUDIO_PROCESSING_H_
