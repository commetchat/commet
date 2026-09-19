// COMMET: the system mix as a reference for Commet's voice DSP.
//
// The DSP (rust/audio_dsp, `bleed`) removes whatever part of the microphone
// is explained by what the loudspeakers are playing. WebRTC's own playout it
// sees through the APM render hook; everything else - a video in a browser,
// music, a game - it only sees through this: the same loopback capturers
// that give screen share its audio, run with no WebRTC source, handing each
// packet straight to a Rust callback.
//
// The capturers exclude our own process on both Windows (source id "0") and
// Linux (see PulseLoopbackCapturer), so WebRTC playout is not counted twice.
//
// Lifetime: Stop() detaches the callback before it returns, under the same
// lock the capture thread takes to call it, so the Rust handle may be freed
// as soon as Stop() returns. On Linux the rest of the stop runs on a
// detached thread: the PulseAudio capturer used to block there while the
// sink was suspended, and tearing down its pulse connection is still best
// kept off the platform thread.
#ifndef COMMET_SYSTEM_AUDIO_REFERENCE_H_
#define COMMET_SYSTEM_AUDIO_REFERENCE_H_

#include <cstddef>
#include <cstdint>
#include <memory>
#include <mutex>
#include <thread>

#include "loopback_capturer.h"

namespace flutter_webrtc_plugin {

class CommetSystemAudioReference {
 public:
  // Matches `commet_dsp_feed_reference` in rust/audio_dsp/src/ffi.rs.
  typedef void (*FeedFn)(void* ctx, const int16_t* samples, size_t frames,
                         size_t channels, int sample_rate);

  CommetSystemAudioReference() = default;
  ~CommetSystemAudioReference() { Stop(); }

  CommetSystemAudioReference(const CommetSystemAudioReference&) = delete;
  CommetSystemAudioReference& operator=(const CommetSystemAudioReference&) =
      delete;

  // Starts (or restarts) the loopback capture, feeding `feed(ctx, ...)`.
  // False when the platform has no loopback capture or it failed to start.
  bool Start(void* ctx, FeedFn feed) {
    Stop();
    if (!ctx || !feed) return false;
    auto capturer = CreateLoopbackCapturer("0");
    if (!capturer) return false;
    auto sink = std::make_shared<Sink>(ctx, feed);
    capturer->SetRawTap([sink](const int16_t* samples, size_t frames,
                               size_t channels, int sample_rate) {
      sink->Deliver(samples, frames, channels, sample_rate);
    });
    if (!capturer->Start(nullptr)) {
      sink->Detach();
      return false;
    }
    sink_ = std::move(sink);
    capturer_ = std::move(capturer);
    return true;
  }

  void Stop() {
    if (sink_) {
      sink_->Detach();
      sink_.reset();
    }
    if (!capturer_) return;
#ifdef __linux__
    std::thread([c = std::move(capturer_)]() mutable { c->Stop(); }).detach();
#else
    capturer_->Stop();
    capturer_.reset();
#endif
  }

  bool running() const { return capturer_ != nullptr; }

 private:
  class Sink {
   public:
    Sink(void* ctx, FeedFn feed) : ctx_(ctx), feed_(feed) {}

    void Deliver(const int16_t* samples, size_t frames, size_t channels,
                 int sample_rate) {
      std::lock_guard<std::mutex> lock(mutex_);
      if (feed_) feed_(ctx_, samples, frames, channels, sample_rate);
    }

    void Detach() {
      std::lock_guard<std::mutex> lock(mutex_);
      feed_ = nullptr;
      ctx_ = nullptr;
    }

   private:
    std::mutex mutex_;
    void* ctx_;
    FeedFn feed_;
  };

  std::shared_ptr<Sink> sink_;
  std::unique_ptr<LoopbackCapturer> capturer_;
};

}  // namespace flutter_webrtc_plugin

#endif  // COMMET_SYSTEM_AUDIO_REFERENCE_H_
