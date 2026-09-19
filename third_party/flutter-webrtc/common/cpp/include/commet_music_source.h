// COMMET: a WebRTC audio track fed by Commet's music player (DJ booth).
//
// The DJ's client decodes the song in Rust (rust/dj_audio) and publishes it
// as its own LiveKit track, so everyone in the room hears the same thing and
// sets its volume apart from the DJ's voice. This owns one pacing thread per
// track: every 10 ms it asks Rust for 480 frames of 48 kHz stereo int16
// (`commet_music_pull`) and hands them to a kCustom RTCAudioSource. A custom
// source bypasses the microphone's audio processing, which would treat music
// as noise.
//
// Lifetime: Stop() joins the thread, so once it returns the Rust handle is no
// longer referenced and may be freed.
#ifndef COMMET_MUSIC_SOURCE_H_
#define COMMET_MUSIC_SOURCE_H_

#include <atomic>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <timeapi.h>
#endif

#include "rtc_audio_source.h"
#include "rtc_types.h"

namespace flutter_webrtc_plugin {

using namespace libwebrtc;

class CommetMusicFeeder {
 public:
  // Matches `commet_music_pull` in rust/dj_audio/src/ffi.rs.
  typedef size_t (*PullFn)(void* ctx, int16_t* out, size_t frames,
                           size_t channels, int32_t sample_rate);

  static constexpr int kSampleRate = 48000;
  static constexpr size_t kChannels = 2;
  static constexpr size_t kFrames = kSampleRate / 100;  // 10 ms

  CommetMusicFeeder(scoped_refptr<RTCAudioSource> source, void* ctx,
                    PullFn pull)
      : source_(source), ctx_(ctx), pull_(pull) {
    thread_ = std::thread(&CommetMusicFeeder::Run, this);
  }

  ~CommetMusicFeeder() { Stop(); }

  CommetMusicFeeder(const CommetMusicFeeder&) = delete;
  CommetMusicFeeder& operator=(const CommetMusicFeeder&) = delete;

  void Stop() {
    stop_.store(true);
    if (thread_.joinable()) thread_.join();
  }

 private:
  void Run() {
#ifdef _WIN32
    // Sleeps are 15.6 ms long by default; 10 ms blocks need better. Above
    // normal priority too: the DJ's machine is busy downloading the next
    // songs (yt-dlp, Deno), and a stall over 100 ms is a skip for everyone.
    timeBeginPeriod(1);
    SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_HIGHEST);
#endif
    using Clock = std::chrono::steady_clock;
    std::vector<int16_t> buffer(kFrames * kChannels);
    const auto period = std::chrono::microseconds(10000);
    auto next = Clock::now();
    while (!stop_.load()) {
      pull_(ctx_, buffer.data(), kFrames, kChannels, kSampleRate);
      source_->CaptureFrame(buffer.data(), 16, kSampleRate, kChannels,
                            kFrames);

      next += period;
      const auto now = Clock::now();
      if (now - next > std::chrono::milliseconds(100)) {
        // Suspended or starved for long: catching up would send a burst the
        // receivers' jitter buffers turn into a skip. Start the clock over.
        next = now;
      } else if (next > now) {
        std::this_thread::sleep_until(next);
      }
    }
#ifdef _WIN32
    timeEndPeriod(1);
#endif
  }

  scoped_refptr<RTCAudioSource> source_;
  void* ctx_;
  PullFn pull_;
  std::atomic<bool> stop_{false};
  std::thread thread_;
};

// The music tracks alive in this process, by track id.
class CommetMusicTracks {
 public:
  ~CommetMusicTracks() { StopAll(); }

  void Add(const std::string& track_id,
           std::unique_ptr<CommetMusicFeeder> feeder) {
    std::lock_guard<std::mutex> lock(mutex_);
    feeders_[track_id] = std::move(feeder);
  }

  // False when no such track was running.
  bool Stop(const std::string& track_id) {
    std::unique_ptr<CommetMusicFeeder> feeder;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      auto it = feeders_.find(track_id);
      if (it == feeders_.end()) return false;
      feeder = std::move(it->second);
      feeders_.erase(it);
    }
    feeder->Stop();
    return true;
  }

  void StopAll() {
    std::map<std::string, std::unique_ptr<CommetMusicFeeder>> feeders;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      feeders.swap(feeders_);
    }
    for (auto& entry : feeders) entry.second->Stop();
  }

 private:
  std::mutex mutex_;
  std::map<std::string, std::unique_ptr<CommetMusicFeeder>> feeders_;
};

}  // namespace flutter_webrtc_plugin

#endif  // COMMET_MUSIC_SOURCE_H_
