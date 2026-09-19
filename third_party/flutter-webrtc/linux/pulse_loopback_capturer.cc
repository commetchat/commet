// Linux system-audio (loopback) capture for flutter_webrtc.
//
// Mirrors windows/application_loopback_capturer.cc: every application's
// playback except our own process, see pulse_loopback_capturer.h. Compiled
// only when the plugin build found libpulse (HAVE_LIBPULSE, set in
// linux/CMakeLists.txt); otherwise this translation unit is empty and
// CreateLoopbackCapturer returns nullptr (getDisplayMedia continues without
// system audio), so a missing libpulse degrades gracefully instead of
// breaking the build.
//
// PipeWire ships a PulseAudio compatibility layer, so this covers both the
// PulseAudio and PipeWire stacks through the same libpulse API.

#if defined(__linux__) && defined(HAVE_LIBPULSE)

#include "pulse_loopback_capturer.h"

#include <pulse/pulseaudio.h>
#include <unistd.h>

#include <algorithm>
#include <chrono>
#include <climits>
#include <cstdint>
#include <iostream>
#include <vector>

namespace flutter_webrtc_plugin {

namespace {

// Frame contract fed to RTCAudioSource::CaptureFrame, matching the value the
// Windows capturer feeds downstream: 16-bit PCM, 48 kHz, 2 channels, 480
// samples per channel = one 10 ms frame.
constexpr int    kBitsPerSample = 16;
constexpr int    kSampleRate    = 48000;
constexpr size_t kChannels      = 2;
constexpr size_t kFramesPer10ms = kSampleRate / 100;  // 480
constexpr size_t kSamplesPer10ms = kFramesPer10ms * kChannels;  // 960
constexpr size_t kFrameBytes = kSamplesPer10ms * sizeof(int16_t);  // 1920

// A stream is mixed from once it holds this much. Kept short: the raw tap
// is the voice DSP's loudspeaker reference, which has to reach it before
// the same sound reaches the microphone through the air.
constexpr size_t kPrimeSamples = 2 * kSamplesPer10ms;  // 20 ms
// Above this a stream is running ahead of the mixer's clock (the two clocks
// drift): one frame is dropped per tick to pull it back, inaudibly.
constexpr size_t kHighSamples = 6 * kSamplesPer10ms;  // 60 ms
// Hard cap, for a mixer that stalled.
constexpr size_t kMaxSamples = 20 * kSamplesPer10ms;  // 200 ms

constexpr auto kTick = std::chrono::milliseconds(10);

// One listing of the sink inputs, collected across callbacks.
struct SinkInputList {
  PulseLoopbackCapturer* owner;
  std::map<uint32_t, bool> inputs;
};

void SinkInputListCallback(pa_context* /*c*/, const pa_sink_input_info* info,
                           int eol, void* userdata) {
  auto* list = static_cast<SinkInputList*>(userdata);
  if (eol < 0) {
    delete list;
    return;
  }
  if (eol > 0) {
    list->owner->OnSinkInputs(list->inputs);
    delete list;
    return;
  }
  if (info && info->sink == list->owner->default_sink() &&
      !list->owner->IsOwnStream(info->proplist)) {
    list->inputs[info->index] = true;
  }
}

void SinkInfoCallback(pa_context* c, const pa_sink_info* info, int eol,
                      void* userdata) {
  if (eol != 0 || !info) return;
  auto* owner = static_cast<PulseLoopbackCapturer*>(userdata);
  owner->OnDefaultSink(info->index, info->monitor_source_name
                                        ? info->monitor_source_name
                                        : std::string());
  pa_operation* op = pa_context_get_sink_input_info_list(
      c, SinkInputListCallback, new SinkInputList{owner, {}});
  if (op) pa_operation_unref(op);
}

void ServerInfoCallback(pa_context* c, const pa_server_info* info,
                        void* userdata) {
  if (!info || !info->default_sink_name) return;
  pa_operation* op = pa_context_get_sink_info_by_name(
      c, info->default_sink_name, SinkInfoCallback, userdata);
  if (op) pa_operation_unref(op);
}

void SubscribeCallback(pa_context* /*c*/, pa_subscription_event_type_t type,
                       uint32_t /*index*/, void* userdata) {
  const auto facility = type & PA_SUBSCRIPTION_EVENT_FACILITY_MASK;
  if (facility == PA_SUBSCRIPTION_EVENT_SINK_INPUT ||
      facility == PA_SUBSCRIPTION_EVENT_SERVER) {
    static_cast<PulseLoopbackCapturer*>(userdata)->Refresh();
  }
}

void StreamReadCallback(pa_stream* /*s*/, size_t /*nbytes*/, void* userdata) {
  auto* app = static_cast<PulseLoopbackCapturer::AppStream*>(userdata);
  app->owner->OnStreamData(app);
}

}  // namespace

// ---------------------------------------------------------------------------
// PulseLoopbackCapturer
// ---------------------------------------------------------------------------

PulseLoopbackCapturer::PulseLoopbackCapturer(const std::string& source_id)
    : source_id_(source_id) {}

PulseLoopbackCapturer::~PulseLoopbackCapturer() {
  Stop();
}

bool PulseLoopbackCapturer::Start(scoped_refptr<RTCAudioSource> source) {
  if (running_) return true;

  source_ = source;

  // libpulse puts these in every client's properties, and so in the
  // properties of our own playback streams.
  own_pid_ = std::to_string(getpid());
  char exe[PATH_MAX];
  const ssize_t len = readlink("/proc/self/exe", exe, sizeof(exe) - 1);
  if (len > 0) {
    exe[len] = '\0';
    const std::string path(exe);
    own_binary_ = path.substr(path.find_last_of('/') + 1);
  }

  auto fail = [this](const char* what) {
    std::cerr << "[LoopbackCapturer] " << what
              << "; system-audio capture unavailable.\n";
    Teardown();
    source_ = nullptr;
    return false;
  };

  mainloop_ = pa_threaded_mainloop_new();
  if (!mainloop_) return fail("pa_threaded_mainloop_new failed");

  context_ = pa_context_new(pa_threaded_mainloop_get_api(mainloop_),
                            "flutter_webrtc_loopback");
  if (!context_) return fail("pa_context_new failed");

  if (pa_context_connect(context_, nullptr, PA_CONTEXT_NOFLAGS, nullptr) < 0) {
    return fail("pa_context_connect failed");
  }
  if (pa_threaded_mainloop_start(mainloop_) < 0) {
    return fail("pa_threaded_mainloop_start failed");
  }

  // Bounded, polled rather than waited on: this runs on the platform thread
  // inside getDisplayMedia, and a wedged daemon must cost "no audio track",
  // not a frozen app.
  const auto deadline =
      std::chrono::steady_clock::now() + std::chrono::seconds(3);
  while (true) {
    pa_threaded_mainloop_lock(mainloop_);
    const pa_context_state_t state = pa_context_get_state(context_);
    pa_threaded_mainloop_unlock(mainloop_);
    if (state == PA_CONTEXT_READY) break;
    if (!PA_CONTEXT_IS_GOOD(state)) return fail("pulse context failed");
    if (std::chrono::steady_clock::now() >= deadline) {
      return fail("pulse context timed out");
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(5));
  }

  pa_threaded_mainloop_lock(mainloop_);
  pa_context_set_subscribe_callback(context_, SubscribeCallback, this);
  pa_operation* op = pa_context_subscribe(
      context_,
      static_cast<pa_subscription_mask_t>(PA_SUBSCRIPTION_MASK_SINK_INPUT |
                                          PA_SUBSCRIPTION_MASK_SERVER),
      nullptr, nullptr);
  if (op) pa_operation_unref(op);
  Refresh();
  pa_threaded_mainloop_unlock(mainloop_);

  running_ = true;
  mix_thread_ = std::thread(&PulseLoopbackCapturer::MixThread, this);
  return true;
}

void PulseLoopbackCapturer::Stop() {
  if (running_) {
    running_ = false;
    // Never blocked on pulse: it sleeps a tick at most.
    if (mix_thread_.joinable()) mix_thread_.join();
  }
  Teardown();
  source_ = nullptr;
}

void PulseLoopbackCapturer::Teardown() {
  if (!mainloop_) return;

  pa_threaded_mainloop_lock(mainloop_);
  for (auto& entry : streams_) {
    pa_stream* stream = entry.second->stream;
    pa_stream_set_read_callback(stream, nullptr, nullptr);
    pa_stream_disconnect(stream);
    pa_stream_unref(stream);
  }
  {
    std::lock_guard<std::mutex> lock(mix_mutex_);
    streams_.clear();
  }
  if (context_) {
    pa_context_set_subscribe_callback(context_, nullptr, nullptr);
    pa_context_disconnect(context_);
    pa_context_unref(context_);
    context_ = nullptr;
  }
  pa_threaded_mainloop_unlock(mainloop_);

  pa_threaded_mainloop_stop(mainloop_);
  pa_threaded_mainloop_free(mainloop_);
  mainloop_ = nullptr;
}

// Mainloop thread (or with the mainloop lock held).
void PulseLoopbackCapturer::Refresh() {
  if (!context_) return;
  pa_operation* op =
      pa_context_get_server_info(context_, ServerInfoCallback, this);
  if (op) pa_operation_unref(op);
}

void PulseLoopbackCapturer::OnDefaultSink(uint32_t index,
                                          const std::string& monitor_source) {
  if (index != default_sink_) {
    // The default output changed: what plays on the old one is no longer
    // what the user hears. The listing that follows re-watches the rest.
    std::vector<uint32_t> all;
    for (auto& entry : streams_) all.push_back(entry.first);
    for (uint32_t input : all) Unwatch(input);
  }
  default_sink_ = index;
  monitor_source_ = monitor_source;
}

void PulseLoopbackCapturer::OnSinkInputs(
    const std::map<uint32_t, bool>& inputs) {
  std::vector<uint32_t> gone;
  for (auto& entry : streams_) {
    const pa_stream_state_t state = pa_stream_get_state(entry.second->stream);
    // A stream that failed (its input moved, the server hiccuped) is opened
    // again below if the input is still there.
    if (!inputs.count(entry.first) || !PA_STREAM_IS_GOOD(state)) {
      gone.push_back(entry.first);
    }
  }
  for (uint32_t input : gone) Unwatch(input);

  for (auto& entry : inputs) {
    if (!streams_.count(entry.first)) Watch(entry.first);
  }
}

bool PulseLoopbackCapturer::IsOwnStream(const pa_proplist* props) const {
  if (!props) return false;
  const char* pid = pa_proplist_gets(props, PA_PROP_APPLICATION_PROCESS_ID);
  if (pid && own_pid_ == pid) return true;
  // In a Flatpak the server may see the host's pid for us; the binary name
  // still matches.
  const char* binary =
      pa_proplist_gets(props, PA_PROP_APPLICATION_PROCESS_BINARY);
  return binary && !own_binary_.empty() && own_binary_ == binary;
}

void PulseLoopbackCapturer::Watch(uint32_t sink_input) {
  const pa_sample_spec spec = {
      /*format=*/PA_SAMPLE_S16LE,
      /*rate=*/kSampleRate,
      /*channels=*/static_cast<uint8_t>(kChannels),
  };

  pa_stream* stream =
      pa_stream_new(context_, "System audio loopback", &spec, nullptr);
  if (!stream) return;

  auto app = std::make_unique<AppStream>();
  app->owner = this;
  app->sink_input = sink_input;
  app->stream = stream;

  if (pa_stream_set_monitor_stream(stream, sink_input) < 0) {
    pa_stream_unref(stream);
    return;
  }
  pa_stream_set_read_callback(stream, StreamReadCallback, app.get());

  // ~10 ms fragments; -1 leaves the rest at the server default.
  pa_buffer_attr attr;
  attr.maxlength = static_cast<uint32_t>(-1);
  attr.tlength   = static_cast<uint32_t>(-1);
  attr.prebuf    = static_cast<uint32_t>(-1);
  attr.minreq    = static_cast<uint32_t>(-1);
  attr.fragsize  = static_cast<uint32_t>(kFrameBytes);

  if (pa_stream_connect_record(
          stream, monitor_source_.empty() ? nullptr : monitor_source_.c_str(),
          &attr,
          static_cast<pa_stream_flags_t>(PA_STREAM_DONT_MOVE |
                                         PA_STREAM_ADJUST_LATENCY)) < 0) {
    std::cerr << "[LoopbackCapturer] Could not record sink input "
              << sink_input << ": "
              << pa_strerror(pa_context_errno(context_)) << "\n";
    pa_stream_set_read_callback(stream, nullptr, nullptr);
    pa_stream_unref(stream);
    return;
  }

  std::lock_guard<std::mutex> lock(mix_mutex_);
  streams_[sink_input] = std::move(app);
}

void PulseLoopbackCapturer::Unwatch(uint32_t sink_input) {
  auto it = streams_.find(sink_input);
  if (it == streams_.end()) return;

  pa_stream* stream = it->second->stream;
  pa_stream_set_read_callback(stream, nullptr, nullptr);
  pa_stream_disconnect(stream);
  pa_stream_unref(stream);

  std::lock_guard<std::mutex> lock(mix_mutex_);
  streams_.erase(it);
}

void PulseLoopbackCapturer::OnStreamData(AppStream* app) {
  while (pa_stream_readable_size(app->stream) > 0) {
    const void* data = nullptr;
    size_t nbytes = 0;
    if (pa_stream_peek(app->stream, &data, &nbytes) < 0 || nbytes == 0) {
      return;
    }

    const size_t samples = nbytes / sizeof(int16_t);
    {
      std::lock_guard<std::mutex> lock(mix_mutex_);
      auto& fifo = app->fifo;
      if (data) {
        const auto* pcm = static_cast<const int16_t*>(data);
        fifo.insert(fifo.end(), pcm, pcm + samples);
      } else {
        // A hole in the stream: silence of that length.
        fifo.insert(fifo.end(), samples, int16_t{0});
      }
      if (fifo.size() > kMaxSamples) {
        fifo.erase(fifo.begin(), fifo.begin() + (fifo.size() - kMaxSamples));
      }
    }

    pa_stream_drop(app->stream);
  }
}

// ---------------------------------------------------------------------------
// MixThread
// Every 10 ms, sums what each application stream has buffered into one
// 48 kHz stereo s16 frame. Paced by the steady clock rather than by a pulse
// read, so a silent or suspended sink yields silent frames instead of a
// stalled track.
// ---------------------------------------------------------------------------
void PulseLoopbackCapturer::MixThread() {
  std::vector<int32_t> acc(kSamplesPer10ms);
  std::vector<int16_t> out(kSamplesPer10ms);

  auto next = std::chrono::steady_clock::now();
  while (running_) {
    next += kTick;
    const auto now = std::chrono::steady_clock::now();
    // Woke up far too late (the machine slept): start the clock afresh
    // instead of bursting out the backlog.
    if (next + 10 * kTick < now) next = now;
    std::this_thread::sleep_until(next);
    if (!running_) break;

    std::fill(acc.begin(), acc.end(), 0);
    {
      std::lock_guard<std::mutex> lock(mix_mutex_);
      for (auto& entry : streams_) {
        auto& app = *entry.second;
        auto& fifo = app.fifo;
        if (!app.primed) {
          if (fifo.size() < kPrimeSamples) continue;
          app.primed = true;
        }
        const size_t n = std::min(fifo.size(), kSamplesPer10ms);
        for (size_t i = 0; i < n; ++i) acc[i] += fifo[i];
        fifo.erase(fifo.begin(), fifo.begin() + n);
        // Ran dry: buffer up again before mixing more.
        if (n < kSamplesPer10ms) app.primed = false;
        // Running ahead of our clock: drop one frame to catch up.
        if (fifo.size() > kHighSamples) {
          fifo.erase(fifo.begin(), fifo.begin() + kChannels);
        }
      }
    }

    for (size_t i = 0; i < kSamplesPer10ms; ++i) {
      out[i] = static_cast<int16_t>(
          std::clamp<int32_t>(acc[i], INT16_MIN, INT16_MAX));
    }

    // COMMET: see LoopbackCapturer::RawTap.
    if (raw_tap_) {
      raw_tap_(out.data(), kFramesPer10ms, kChannels, kSampleRate);
    }
    if (source_) {
      source_->CaptureFrame(out.data(), kBitsPerSample, kSampleRate, kChannels,
                            kFramesPer10ms);
    }
  }
}

}  // namespace flutter_webrtc_plugin

#endif  // __linux__ && HAVE_LIBPULSE
