#ifndef PULSE_LOOPBACK_CAPTURER_H_
#define PULSE_LOOPBACK_CAPTURER_H_

#ifdef __linux__

#include <atomic>
#include <cstdint>
#include <deque>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <thread>

#include "loopback_capturer.h"

// Forward-declared so this header does not need the pulse dev headers just to
// be included. The .cc pulls them in behind the HAVE_LIBPULSE guard.
struct pa_threaded_mainloop;
struct pa_context;
struct pa_stream;
struct pa_proplist;

namespace flutter_webrtc_plugin {

// Linux PulseAudio / PipeWire (pulse compat) implementation of
// LoopbackCapturer: "system audio" for screen share, minus our own process.
//
// COMMET: this used to record the default sink's monitor, which carries
// everything the speakers play, including Commet playing the call. Everyone
// in the call then heard themselves in the screen share. The Windows
// capturer excludes our process tree (PROCESS_LOOPBACK_MODE_EXCLUDE_TARGET_
// PROCESS_TREE); the pulse equivalent is to record each other application's
// playback stream on its own (pa_stream_set_monitor_stream, which PipeWire's
// pulse layer supports too) and mix them here:
//
//   * a threaded mainloop watches the sink inputs on the default sink, and
//     opens one monitor record stream per input that isn't ours (matched by
//     process id, or by binary name where a sandbox hides the pid);
//   * each stream's read callback appends to that stream's FIFO;
//   * a mixer thread sums the FIFOs every 10 ms into one 48 kHz stereo s16
//     frame for the RTCAudioSource and the raw tap. It runs off a clock, so
//     it keeps delivering (silence) when nothing plays, and Stop() never
//     blocks on a suspended sink the way the old pa_simple_read did.
class PulseLoopbackCapturer : public LoopbackCapturer {
 public:
  explicit PulseLoopbackCapturer(const std::string& source_id);
  ~PulseLoopbackCapturer() override;

  bool Start(scoped_refptr<RTCAudioSource> source) override;
  void Stop() override;

  // One application playback stream being recorded. Public only so the
  // libpulse callbacks in the .cc can reach it.
  struct AppStream {
    PulseLoopbackCapturer* owner = nullptr;
    uint32_t sink_input = 0;
    pa_stream* stream = nullptr;
    // Interleaved stereo s16 samples not mixed yet. Guarded by mix_mutex_.
    std::deque<int16_t> fifo;
    // Mixed from only once it has buffered a little, so the jitter between
    // pulse delivering and the mixer's clock doesn't cause gaps.
    bool primed = false;
  };

  // Called on the pulse mainloop thread by the callbacks in the .cc.
  void OnDefaultSink(uint32_t index, const std::string& monitor_source);
  void OnSinkInputs(const std::map<uint32_t, bool>& inputs);
  void OnStreamData(AppStream* app);
  void Refresh();
  bool IsOwnStream(const pa_proplist* props) const;
  uint32_t default_sink() const { return default_sink_; }

 private:
  void MixThread();
  void Watch(uint32_t sink_input);
  void Unwatch(uint32_t sink_input);
  void Teardown();

  // Unused on Linux: no per-window audio isolation. Kept for parity with the
  // Windows factory, which resolves a window's process from it.
  std::string source_id_;

  scoped_refptr<RTCAudioSource> source_;
  std::atomic<bool> running_{false};
  std::thread mix_thread_;

  pa_threaded_mainloop* mainloop_ = nullptr;
  pa_context* context_ = nullptr;

  // Mainloop thread only.
  uint32_t default_sink_ = UINT32_MAX;
  std::string monitor_source_;

  // Streams by sink input index. The map changes on the mainloop thread and
  // the FIFOs are drained by the mixer, both under mix_mutex_.
  std::mutex mix_mutex_;
  std::map<uint32_t, std::unique_ptr<AppStream>> streams_;

  // How our own playback identifies itself to the pulse server.
  std::string own_pid_;
  std::string own_binary_;
};

}  // namespace flutter_webrtc_plugin

#endif  // __linux__
#endif  // PULSE_LOOPBACK_CAPTURER_H_
