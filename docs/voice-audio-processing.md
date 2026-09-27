# Voice audio processing

Client-side noise suppression, input gate and far-end ducking for voice
rooms. Everything runs on the user's own device before audio leaves the
client. Browser support is a first-class target.

Status (2026-09-25, last): after the knocks, eighteen other noises were
measured, alone and under speech, loud and quiet (see "Background noise").
Two more things were fixed on the way: DeepFilterNet leaves everything
below 60 Hz alone, so a 70 Hz high-pass now follows it; and the gate opened
on what it left of loud steady noise and of nearby chatter, so opening it
now takes speech heard on the microphone too and DeepFilterNet's own
estimate of speech above the noise. What no setting removes: other people
talking in the room.

Status (2026-09-25, later): knocking on the table ("toc toc toc") still
reached the room after the audit. RNNoise takes steady noise out but a knock
only about 6 dB, and its speech detector fired on real knocks, which opened
the gate: a recording of knuckles on a table came out 26 dB down with the
gate open on 3 % of the blocks, and while the user talked a knock went
through at up to 36 dB over the voice. DeepFilterNet3 now does the
suppressing (`rust/audio_dsp/src/dfn.rs`, vendored in
`third_party/deep_filter`), RNNoise judges speech on what it leaves: the same
knocks come out 80 dB down with the gate shut, and under speech they add
1.2 dB on average (RNNoise: 2.6). See "Impulsive noise". On the web the DSP
moved into a Web Worker (`audio_dsp.worker.js`), the model being too heavy
for the audio thread.

Status (2026-09-25): an audit fixed seventeen ways suppression failed or
silently was not there (docs/noise-suppression-checklist.md), and noise
suppression is now measured end to end: a recording of speech in a noisy
room goes through the DSP inside the real WebRTC on Linux, through the
browser's DSP, and through the web app's own Dart, and CI fails the release
when the noise is not at least 20 dB down or the voice more than 4 dB down.
See "What the tests guard" and "What still needs a person". The notes below
from 2026-09-14 on are history.

Status (2026-09-14): Phase 0 and Phase 1 code is written on branch
`feature/voice-dsp`. Verified so far, all inside a Flutter 3.41.9 container
mirroring CI:

- `cargo test -p audio_dsp`: 25 unit tests and 15 recording driven ones pass
  (2026-09-17, see "Loudspeaker bleed"); wasm build is 483 KB.
- `dart analyze` in `commet/`: no new issues. The vendored LiveKit files
  analyze clean.
- `flutter build linux --debug`: passes, including the vendored C++ plugin
  and the cargokit Rust build. The bundled `librust_lib_commet.so` exports
  all 24 `commet_dsp_*` symbols; a dart:ffi smoke test through the app's
  struct layouts and callback signatures processes 100 frames correctly.
- The prebuilt libwebrtc 1.4.0 contains `RTCAudioProcessingImpl` and
  `CustomProcessingAdapter`, so the hook is implemented, not just declared.
- `flutter build web --release`: passes; `audio_dsp.js`, the worklet and
  the wasm land in `build/web`.

Not yet verified: anything at runtime with a real microphone and a real
room. See "What to verify first".

Runtime finding (2026-09-15, Windows): joining a voice room killed the
process. libwebrtc's `CustomProcessingAdapter::SetExternalAudioProcessing`
calls `Initialize` on whatever pointer it is given, null included, once the
APM is initialized. The host used to pass nullptr to detach before
installing and again on clear; since the mic track already exists at that
point this was a null virtual call. The host now installs one long-lived
no-op proxy per slot exactly once and swaps the Rust callbacks inside it
(`shared_cpp/commet_external_audio_processing.h`).

Investigation (2026-09-15, Windows, "no audible difference" report): the
wiring is complete end to end (LiveKit session → `CallManager` →
`NativeAudioProcessingManager` → APM hook → Rust; `noiseSuppression`
constraint → `RTCAudioOptions` → libwebrtc), and the four Windows crash
dumps in `%LOCALAPPDATA%\CrashDumps` are all `flutter_inappwebview` /
DirectComposition, not the DSP. Two real reasons the toggle felt like
nothing:

- Nobody can hear their own microphone in a call, and with ours off the
  WebRTC suppressor takes over, so an A/B needs a second listener or a
  playback path. The settings page now has a microphone test with "Hear
  myself" for exactly this.
- The WebRTC suppressor is chosen when the track is created. Toggling ours
  mid-call used to leave it as it was (both on, or neither).
  `MatrixLivekitVoipSession` now restarts the microphone track with the
  opposite option when the preference flips.

The level meter only moved during a call because nothing captures the
microphone outside one; see "Microphone test" below.

## Decisions

| Question | Decision |
|----------|----------|
| Default state of noise suppression | On for desktop and web, off on Android until the hardware DSP interplay is tested |
| Upstream | Never. Third-party code we change is vendored under `third_party/` (see `third_party/README.md`) |
| Where the web wasm lives | `commet/web/audio_dsp.wasm`, gitignored, built by `commet/scripts/prepare-web.sh` like the e2ee worker |
| Sensitivity UI | Level meter in dBFS with a threshold marker, plus an "Automatic" switch that uses the VAD |
| Model | DeepFilterNet3 (libDF and its model, MIT/Apache-2.0, vendored and trimmed in `third_party/deep_filter`) since 2026-09-25: RNNoise (`nnnoiseless`, BSD-3) let knocks through. RNNoise stays as the speech detector and the fallback |
| Where the web DSP runs | A Web Worker (`audio_dsp.worker.js`); the AudioWorklet only moves 10 ms blocks. The model takes about 4 ms of each 10 ms block in wasm, a worklet quantum has 2.67 ms |

## Architecture

One DSP core, three transports.

```
rust/audio_dsp            C ABI: commet_dsp_*          (tested, cargo test -p audio_dsp)
   |  + third_party/deep_filter (DeepFilterNet3, tract)
   |                       |
   | re-exported by        | compiled to wasm32-unknown-unknown, no imports
   v                       v
librust_lib_commet     commet/web/audio_dsp.wasm
   |                       |
   | dart:ffi addresses    | instantiated inside a Web Worker
   v                       v
vendored livekit plugin (Linux/Windows C++)          commet/web/audio_dsp.worker.js (runs the DSP)
   commetSetExternalAudioProcessing                   commet/web/audio_dsp.worklet.js (10 ms blocks to and fro)
   -> RTCAudioProcessing::SetCapturePostProcessing    commet/web/audio_dsp.js (graph glue)
   -> RTCAudioProcessing::SetRenderPreProcessing      -> LiveKit TrackProcessor (processedTrack)
                                                      -> second worklet input = remote mix
```

Dart entry point: `commet/lib/client/components/voip/audio_processing/`.
`AudioProcessingManager.instance` is created lazily with a conditional
import (stub / native / web). `CallManager` calls `onSessionStarted` and
`onSessionEnded`; `MatrixLivekitBackend.join` passes
`createTrackProcessor()` (web only) and turns the WebRTC/browser noise
suppressor off when ours is on.

### Every microphone through one door

Who takes the noise out of a capture (our DSP, or WebRTC's / the browser's
own suppressor, never both and never neither) is decided in one place,
`MicrophoneNoiseSuppression` (`audio_processing/microphone_noise_suppression.dart`),
and every capture is made through it:

- voice rooms: `prepareMicrophoneCaptureOptions` / `microphoneCaptureOptions`
  (`voip_room/livekit_microphone.dart`), which waits for
  `AudioProcessingManager.ensureReady` (on the web: audio_dsp.wasm fetched
  and test-run). During the call `MicrophoneNoiseSuppression.update()`
  keeps the capture in line (a preference flip, an unmute, once a second;
  a restart only while the microphone is live) and watches the DSP: fed no
  audio for 4 s of live microphone, it gives up on it for the call, turns
  WebRTC's suppressor back on and tells the user. The microphone is found by
  `TrackSource.microphone`, never as "the first audio track";
- the microphone test and legacy 1:1 calls: `microphoneConstraints`, built
  from LiveKit's own `AudioCaptureOptions` so the device is named the way
  desktop WebRTC reads it; legacy calls get it through
  `NoiseSuppressedMediaDevices`, the MediaDevices matrix-dart-sdk captures
  with, which on the web also runs the stream through the DSP
  (`processMicrophoneStream`).

The DSP counts the calls it serves itself (`onSessionStarted` /
`onSessionEnded` per session, compared with `==`) and changes what is
installed one step at a time.

### Signal chain

Native (Linux, Windows): mic → WebRTC ADM → APM (AEC3, NS off when ours is
on, AGC off) → **capture post-processing hook → Rust** → Opus. Playout →
**render pre-processing hook → Rust (level only)** → speakers. The hook is
process-global on the shared APM, so it also covers legacy 1:1 calls.
While the DSP is installed and "Filter out sound from your speakers" is on,
the vendored flutter-webrtc also runs its system-audio loopback (WASAPI
process loopback excluding ourselves on Windows, one monitor stream per
application except ours on Linux) and hands every packet to
`commet_dsp_feed_reference` from its capture thread, ahead of the Windows
feeder's 160 ms pre-buffer (`commet_system_audio_reference.h`,
`LoopbackCapturer::SetRawTap`).

Three properties of that WebRTC matter here, all found by the native loop:

- The hook runs inside the APM's capture processing, which WebRTC skips
  while every sender of a peer connection is muted (`capture_output_used`,
  set by `WebRtcVoiceSendChannel::MuteStream` on the one APM the whole
  process shares). A disabled local audio track anywhere stops the DSP.
- flutter-webrtc on desktop picks the input device only from
  `optional: [{sourceId}]` and records from its device 0 for anything else,
  and resolves track ids among local tracks first (a received track that
  shares a local track's id is looked up as the local one).
- WebRTC stops recording altogether while every sender is muted and starts
  again on the unmute (`MuteStream` in stop-on-mute mode, the default of
  the audio device module libwebrtc creates). The audio device module keeps
  the microphone as a position in the device list and looks that position
  up again each time it starts, so a device that appeared or went away
  during a mute (a webcam, a headset, a virtual device) moved it onto
  another microphone, usually a silent one. The call went on sending
  silence: no speaking indicator, no noise suppression warning (the DSP
  still got frames), nothing a mute and unmute fixed, until the user left
  the call. On Windows the app's own device-change handler did not catch
  it: WebRTC only reports a device changing state, not one added or
  removed, and the handler only acts on a picked device. The vendored
  flutter-webrtc now remembers the selected microphone by id and selects it
  again, by id, before a local audio track is enabled
  (`ReselectRecordingDevice`, a `// COMMET` change).

Web: `getUserMedia` (browser AEC on, NS off, AGC on) →
`MediaStreamAudioSourceNode` → **`commet-dsp` AudioWorklet ⇄
`audio_dsp.worker.js` (wasm)** → `MediaStreamAudioDestinationNode` →
published track. The worklet gathers 10 ms blocks (the microphone and the
far end), transfers each to the worker the moment its last sample is in,
and plays the processed blocks 20 ms behind the input; a block that comes
back late is played late (silence in the gap, the delay grows by it, at
most four blocks). Every remote audio track is also connected to the
worklet's second input for far-end level. `commetAudioDsp.probe()`
(worklet module, worker script, wasm, exports, ABI, checked in a worker)
decides whether the DSP can run before a call turns the browser's
suppressor off, and `create()` only hands out a graph whose worker has
built the DSP: until then the worklet passes the microphone through
untouched. The worker times the model and hands suppression to RNNoise for
the call when a block takes over 8 ms on average (it says so on the
console).

Frame format everywhere: one 10 ms block, mono, float. Native hands
int16-scale floats (480 samples at 48 kHz, or 160/320 at 16/32 kHz which the
crate resamples). The worker hands unit-scale 480-sample blocks.

### Processing inside `audio_dsp`

1. Resample to 48 kHz if needed (windowed-sinc FIR, `resample.rs`).
2. Loudspeaker bleed (`bleed.rs`), against the playout and the system mix
   separately: is there anything in the microphone the loudspeakers do not
   explain? See "Loudspeaker bleed" below.
3. DeepFilterNet3 (`dfn.rs`) takes the noise out and a 70 Hz high-pass
   (`highpass.rs`) what it leaves below the voice, then RNNoise judges the
   speech probability on the result (on the raw microphone RNNoise calls a
   knock speech). To *open* the gate a second RNNoise has to hear speech
   on the raw microphone as well, and DeepFilterNet has to have estimated
   speech above the noise (its local SNR over 0 dB) in one of its last four
   blocks (`Dsp::gate_vad`); keeping it open takes only the first. Without the model RNNoise does both, as it used to: in
   the app's first half second while the model is built on a thread of its
   own (`ModelLoad::Background`, `commet_dsp_create`), and for good when
   the model takes over 6 ms a block on average (`dfn::CostMeter`, native)
   or 8 ms (the web worker's timer), or cannot be built. The model's lookahead holds the last audio it heard,
   so a model that arrives mid-stream, one switched back on and one after
   the capture restarts run 20 blocks beside RNNoise before they are heard.
4. Gate (`gate.rs`): manual threshold, or VAD-driven with hysteresis
   (open above 0.5, close below 0.3) *and* above the same threshold, 150 ms
   hold, 5 ms attack, 200 ms release, closed gain -40 dB (not a hard mute).
   Held shut while step 2 says the microphone holds only bleed.
5. Ducker: when the far-end peak (300 ms hold) is above -45 dBFS and the
   user is not talking, apply -20 dB. "Talking" comes from step 2 when it has
   learned the playout, from the VAD (below 0.4) otherwise.
6. Resample back.

Parameters and the report cross threads through atomics, and so do the
render and reference levels (a `fetch_max` mailbox the capture side empties
once per block; before ABI 2 the render thread wrote the gate's state
directly). The audio-thread entry points never allocate after
construction, except inside DeepFilterNet's inference, which tract does
with allocations (there is a test for everything else). RNNoise does very
little against pure full-band white noise; real noise is coloured and the
fixtures reflect that.

Latency added to the microphone: 30 ms natively (DeepFilterNet's window
overlap and two blocks of lookahead; RNNoise alone was 10 ms), 50 ms on
the web (the same 30, plus the worklet's 20 ms round trip through the
worker; the worklet used to add 10).

Cost: natively about 1 ms per 10 ms block on a 2017 laptop (i7-7700HQ), and
half a second to build the model when a call starts. In wasm about 4 ms per
block and 0.7 s to build, off the audio thread.

## Background noise

Question (2026-09-25): which other noises were tested, what comes through,
and what keeps it from regressing?

`tests/background_noise.rs` measures eighteen noises at the shipping
settings: steady ones made in the test (fan and PC, white, pink and brown
noise, mains hum), and recordings (`testdata/README.md`: applause, hand
claps, knuckles on a table, a mechanical and a desktop keyboard, mouse
clicks, a pen on paper, a far crowd, a restaurant, piano, an electronic
beat, a pop song with singing, and another person talking). Each one alone
at -38 dBFS (the user quiet) and at -25 dBFS (nearly as loud as the user),
and under the user's speech at 10 dB and at 0 dB speech to noise. With the
voice, the measure is SI-SDR against the clean voice: how clean it comes
out, whatever the gate and the suppressor did.

The same measurements at 10 s of each noise and at 48 kHz, before this work
(RNNoise, as shipped until 2026-09-25) and now:

| Noise | Alone -38 dBFS: dB down (gate open), before → now | Loud -25 dBFS, gate open, before → now | Under speech at 10 dB, SI-SDR before → now (input 9.0) | At 0 dB (input -1.0) |
|---|---|---|---|---|
| fan and PC | >90 (0 %) → 71 (0 %) | 85 % → 2 % | 10.3 → 13.8 | 3.9 → 6.9 |
| knuckles on a table | 12 (4.1 %) → >90 (0 %) | 12 % → 0 % | 8.3 → 15.4 | 0.2 → 10.7 |
| white noise | 58 (0 %) → 65 (0 %) | 84 % → 0 % | 12.7 → 18.3 | 8.5 → 12.1 |
| pink noise | 79 (0 %) → 71 (0 %) | 99 % → 0 % | 11.4 → 16.5 | 6.2 → 10.2 |
| brown noise | >90 (0 %) → >90 (0 %) | 0 % → 0 % | 14.7 → 28.3 | 14.4 → 24.7 |
| mains hum | >90 (0 %) → >90 (0 %) | 0 % → 0 % | 9.9 → 14.5 | 4.0 → 8.8 |
| applause | 64 (0 %) → >90 (0 %) | 92 % → 0 % | 11.1 → 15.1 | 6.2 → 9.5 |
| hand claps | 15 (5.4 %) → >90 (0 %) | 6 % → 0 % | 9.4 → 21.1 | 3.9 → 17.3 |
| desktop keyboard | >90 (0 %) → >90 (0 %) | 0 % → 0 % | 14.8 → 28.4 | 14.7 → 27.2 |
| mechanical keyboard | 66 (0 %) → >90 (0 %) | 0 % → 0 % | 10.7 → 15.0 | 5.4 → 8.9 |
| mouse clicks | 85 (0 %) → >90 (0 %) | 0 % → 0 % | 13.2 → 23.6 | 10.4 → 18.5 |
| pen on paper | 26 (2.0 %) → 64 (0 %) | 6 % → 3 % | 9.8 → 15.1 | 2.3 → 9.6 |
| far crowd | 28 (2.2 %) → >90 (0 %) | 7 % → 13 % | 10.4 → 14.0 | 3.4 → 7.5 |
| restaurant | 15 (7.1 %) → 19 (16.5 %) | 29 % → 55 % | 9.8 → 14.4 | 1.2 → 6.9 |
| another person talking | 0 (95 %) → 0 (94 %) | 97 % → 96 % | 7.9 → 11.9 | -1.7 → 3.2 |
| piano | 5 (60 %) → 79 (0 %) | 68 % → 7 % | 8.9 → 13.0 | -0.5 → 5.6 |
| electronic beat | 9 (47 %) → 36 (1.7 %) | 73 % → 5 % | 9.7 → 14.3 | 1.6 → 8.6 |
| pop song with singing | 16 (34 %) → >90 (0 %) | 55 % → 0 % | 10.6 → 16.6 | 4.5 → 10.8 |

The voice under any of them: at 10 dB at most 1.0 dB lost and the gate
open for at least 97 % of it; at 0 dB (noise as loud as the voice) up to
3 dB lost and the gate open for 90 to 99 % of it. On clean speech
DeepFilterNet's output is 25.9 dB SI-SDR, RNNoise's 14.5: RNNoise coloured
the voice itself.

Found and fixed on the way:

- DeepFilterNet passes what is below 60 Hz untouched, which is most of the
  energy of brown noise and of a keyboard heard through the desk: under
  speech they came out -0.5 dB SI-SDR. The 70 Hz high-pass after it fixed
  that (24.7). In front of the model it made mains hum worse instead: with
  the 50 Hz fundamental gone, the model took the harmonics for a voice.
- With DeepFilterNet the gate opened on what it left of some noises, which
  RNNoise then took for speech: nearby chatter (65 % of the time), a loud
  fan (29 %), loud piano (15 %). Opening now takes RNNoise on the raw
  microphone too (not while open: that cost the voice 1 to 8 % of its
  blocks in heavy noise), and DeepFilterNet's local SNR estimate over
  0 dB in its last four blocks: the fan fell to 2 %, the chatter to 17 %,
  and no speech number moved.

What still comes through:

- **Other people talking.** Another voice is speech to both models: it
  goes through whole, as it did with RNNoise, and nearby chatter (the
  restaurant) opens the gate a sixth of the time, half the time when loud.
  The input sensitivity slider is the tool: above the other voices'
  level, below the user's.
- **Singing and instruments.** The pop song, singing included, is removed
  like any music. So would the user's own singing or playing be, with
  suppression on.
- **Noise as loud as the voice.** At 0 dB the voice loses up to 3 dB
  (piano, another person) and the gate misses up to 10 % of it.
- **A knock on a quiet syllable** ("Impulsive noise" below).

`cargo run -p audio_dsp --release --example process_wav -- in.wav out.wav`
puts any 48 kHz recording through the DSP (`--rnnoise` for the old
suppressor, `--no-gate`, `--blocks` for per-block levels, gate and SNR
estimate), for listening to what a noise leaves.

## Impulsive noise

Report (2026-09-25): "the microphone keeps picking up noises like me
knocking toc toc toc on a wooden table", after the audit.

`tests/impulsive_noise.rs` puts two kinds of knocking through the DSP: a
recording of knuckles on a table (`testdata/knuckles_on_table_16k.wav`)
and synthetic knocks on wood whose timing is known, laid under speech. At
the shipping settings:

| Scenario | RNNoise | DeepFilterNet |
|---|---|---|
| knuckles on a table, nobody talking | 25.6 dB down, gate open 3 % | 80.4 dB down, gate shut |
| synthetic knocks, nobody talking | 11.9 dB down, gate open 10 % | 64.9 dB down, gate shut |
| knuckles, suppressor alone (the gate is open while talking) | 12.5 dB down | 44.7 dB down |
| synthetic knocks, suppressor alone | 8.1 dB down | 25.0 dB down |
| knocks under speech, added to their 10 ms blocks | +2.6 dB on average, 90 % under +8.5, worst +36.5 | +1.2 dB, 90 % under +4.0, worst +17.5 |
| the user talking, lost | 0.1 dB | 0.2 dB |

Two things RNNoise did wrong: it removes about 6 to 12 dB of a knock, and
its speech probability goes over the gate's 0.5 on real knocks, so the gate
opened and let the knock through whole. RNNoise's probability on
DeepFilterNet's output stays near 0 for knocks.

What is still not perfect:

- A knock that lands on a quiet syllable. The model keeps the speech's
  bands open, and the first 10 ms of a knock 15 to 20 dB louder than the
  voice at that moment comes through about 5 dB down: the "worst" column.
- The model settles on a quiet room when it is built (`DeepFilter::settle`):
  without that, its input normalisation took about a second, and a knock
  half a second into a call came through 20 dB down and opened the gate.
- A muffled thump with nothing above 1 kHz (a door heard from the other
  side of it; recordings from Wikimedia Commons, not committed) comes out
  only about 13 dB down, and its low hum still reads as speech. The table
  under a desk microphone may couple some of that in.

### Microphone test

`AudioProcessingManager.startMicTest()` captures the microphone through the
DSP without a call so Settings → VoIP can show the live meter and let the
user hear the result ("Hear myself", `setMicTestMonitor`). Joining a call
stops the test; leaving the settings page stops it too.

- Native: WebRTC only records while a sending audio stream exists, so the
  test builds two local peer connections (`_MicLoopback`) and sends the
  microphone from one to the other. That drives the ADM → APM → hook path
  identically to a call. The playback is silenced by volume while not
  monitoring (`Helper.setVolume`), never by disabling the received track:
  it has the microphone track's id, so that disabled the microphone and
  the DSP got nothing (see "Signal chain").
- Web: `getUserMedia` → the same worklet graph; monitoring connects the
  worklet node to `ctx.destination` (`graph.setMonitor`).
- Both capture with the same constraints as a call (browser/WebRTC
  suppressor off when ours is on) and restart the capture when the noise
  suppression preference flips during the test.

The status line under the meter reports the sample rate, whether RNNoise is
running and the gate state, or says explicitly that the DSP is attached but
receiving no frames. That is the first thing to read when the meter is dead.

## Files

| Path | Role |
|------|------|
| `rust/audio_dsp/` | DSP crate, C ABI in `src/ffi.rs`, loudspeaker bleed in `src/bleed.rs`, DeepFilterNet in `src/dfn.rs`, recordings in `testdata/` (see its README) |
| `third_party/deep_filter/` | libDF from DeepFilterNet, trimmed to the inference, with the DeepFilterNet3 model (`models/`, 8 MB) |
| `rust/audio_dsp/tests/speaker_bleed.rs` | what leaves the client with speakers and no headset, on real speech through a simulated room |
| `rust/audio_dsp/tests/impulsive_noise.rs` | knocks on the table, alone and under speech, both suppressors side by side |
| `rust/audio_dsp/tests/background_noise.rs` | eighteen noises alone and under speech, with what each has to keep doing |
| `rust/audio_dsp/src/highpass.rs` | the 70 Hz high-pass after noise suppression |
| `rust/audio_dsp/examples/process_wav.rs` | a recording through the DSP, for listening and measuring |
| `third_party/flutter-webrtc/common/cpp/include/commet_system_audio_reference.h` | system mix to `commet_dsp_feed_reference`; `commetStartSystemAudioReference` / `commetStopSystemAudioReference` in `flutter_webrtc.cc` |
| `third_party/flutter-webrtc/common/cpp/include/loopback_capturer.h`, `{windows/application,linux/pulse}_loopback_capturer.cc` | `SetRawTap`: packets as they come off the OS, before the Windows feeder's pre-buffer |
| `rust/rust/src/lib.rs` | `pub use audio_dsp;` so the symbols ship in `librust_lib_commet` |
| `third_party/livekit-client-sdk-flutter/shared_cpp/commet_external_audio_processing.h` | CustomProcessing adapters |
| `third_party/livekit-client-sdk-flutter/{linux,windows}/livekit_plugin.cpp` | `commetSetExternalAudioProcessing` / `commetClearExternalAudioProcessing` |
| `third_party/livekit-client-sdk-flutter/lib/src/support/native.dart` | Dart side of those methods (`Native.setExternalAudioProcessing`) |
| `third_party/livekit-client-sdk-flutter/lib/src/track/local/local.dart` | `replaceTrack` after a processor is set, restore on stop |
| `third_party/livekit-client-sdk-flutter/lib/src/track/remote/audio.dart`, `track/web/_audio_{html,api}.dart` | `RemoteAudioTrack.setVolume`: per-track playback volume on web (audio element, 0..1) |
| `commet/lib/client/components/voip/audio_processing/` | manager (stub, native, web), settings and report models |
| `commet/lib/ui/pages/settings/categories/app/voip_settings/voip_audio_processing_settings.dart` | toggles and level meter |
| `commet/lib/client/components/voip/audio_processing/microphone_noise_suppression.dart` | who suppresses, the watchdog, `microphoneConstraints` |
| `commet/lib/client/components/voip/audio_processing/noise_suppressed_media_devices.dart` | legacy 1:1 calls' MediaDevices |
| `commet/lib/client/components/voip/audio_processing/noise_suppression_notice.dart` | what the user is told when suppression falls back |
| `commet/lib/client/matrix/components/voip_room/livekit_microphone.dart` | a voice room's microphone: created, found, toggled |
| `commet/web/audio_dsp.js`, `commet/web/audio_dsp.worklet.js`, `commet/web/audio_dsp.worker.js` | browser glue: the graph, the worklet moving blocks, the worker running the wasm |
| `commet/scripts/build-audio-dsp-wasm.sh` | builds `audio_dsp.wasm` (called by `prepare-web.sh` and CI) |
| `commet/unit_test/noise_suppression/` | the Dart tests below |
| `commet/integration_test/voice_dsp/` | entry points of the native and web app loops |
| `rust/audio_dsp/examples/noisy_speech.rs` | the fixture every loop plays |
| `tools/voice_dsp/` | the loops and the contracts check |

Preferences: `voipNoiseSuppression`, `voipInputSensitivityAuto`,
`voipInputSensitivityDb`, `voipFarEndDucking`, `voipSpeakerBleed`.

Vendored LiveKit and flutter-webrtc changes are marked `// COMMET`.

## Building and testing

```sh
# 29 unit tests, 15 recording driven ones (tests/speaker_bleed.rs), 5 on
# knocking (tests/impulsive_noise.rs) and 18 on background noise
# (tests/background_noise.rs)
cargo test -p audio_dsp
# every scenario with its measured numbers
cargo test -p audio_dsp --test speaker_bleed -- --nocapture
cargo test -p audio_dsp --test impulsive_noise -- --nocapture
cargo test -p audio_dsp --test background_noise -- --nocapture
# or without a local toolchain
docker run --rm -v "$PWD":/w -w /w rust:1 cargo test -p audio_dsp

# WebAssembly (also done by commet/scripts/prepare-web.sh), about 24 MB, 8 of
# them the model
cargo build -p audio_dsp --release --target wasm32-unknown-unknown

# Diagnostic: attenuation / VAD / allocations for synthetic input
cargo run -p audio_dsp --release --example diag
```

After changing `pubspec.yaml` (LiveKit is now a path dependency) run
`flutter pub get` in `commet/`.

Debug builds optimise every dependency and leave their debug info out (the
workspace `Cargo.toml`): unoptimised, DeepFilterNet cannot keep up with
real time, and the native cost guard would hand every debug build of the
app to RNNoise. The first debug build compiles tract for a few minutes.

The loops, from the repository root (each builds the fixture with cargo
when it is missing):

```sh
# seconds: names, ABI and vendored changes the chain depends on
python3 tools/voice_dsp/check_contracts.py
# Dart: the FFI loop, the decisions, the vendored LiveKit track
(cd commet && flutter test unit_test/noise_suppression)
# browser: the glue alone (commet/web needs audio_dsp.wasm)
node tools/voice_dsp/web_noise_loop.mjs
# browser: everything CI's voice-dsp job does (about 4 min)
tools/voice_dsp/web_loops.sh
# Linux: inside the real WebRTC (about a minute after the first build)
tools/voice_dsp/native_noise_loop.sh
```

## What the tests guard

| Invariant | Guarded by | In CI |
|-----------|------------|-------|
| The DSP takes room noise out (≥ 20 dB) and keeps the voice (≥ -4 dB) | `cargo test -p audio_dsp` | ci `test` |
| Knocks on the table: > 40 dB down and the gate shut while nobody talks, > 20 dB by the suppressor alone, little added under speech | `tests/impulsive_noise.rs` | ci `test` |
| Sixteen background noises: removed while the user is quiet (≥ 50 dB), the gate shut even when loud, the voice cleaner under them by what was measured, at most 1.5 dB (10 dB SNR) or 5 dB (0 dB) of it lost and the gate open for ≥ 95 % / 80 % of it; restaurant chatter and another person recorded as they are | `tests/background_noise.rs` | ci `test` |
| A model loading in the background takes over after its warm-up; a disabled one leaves RNNoise suppressing | `audio_dsp` unit tests | ci `test` |
| In the app's own create path (FFI, model built in the background) DeepFilterNet takes over and suppresses | `native_dsp_test.dart` | ci `test` |
| The browser runs DeepFilterNet in the worker (or says it was too slow); a missing worker script is caught by `probe()` and `create()` | `web_noise_loop.mjs` | ci `voice-dsp` |
| `audio_dsp.wasm` has no imports (the worker gives it none) | `check_contracts.py --web-build` | ci `voice-dsp`, build, release |
| The same through the callback addresses and struct layouts the native plugin gets, and a preference change reaches a running DSP | `native_dsp_test.dart` | ci `test` |
| A library missing any entry point is unsupported from the start | `native_dsp_test.dart` | ci `test` |
| A leave and a join fired together leave the DSP on the hook; one call ending leaves another's DSP | `native_dsp_test.dart` | ci `test` |
| `isProcessing` only with audio | `native_dsp_test.dart` | ci `test` |
| Ours or WebRTC's, never both or neither: at creation, on a flip while live, muted, or before publishing; the watchdog; the microphone found by source; a first unmute creates a room microphone | `microphone_noise_suppression_test.dart` | ci `test` |
| A call waits for `ensureReady` before choosing | `microphone_noise_suppression_test.dart` | ci `test` |
| Legacy calls: the preference and the device reach the capture; a failed web DSP recaptures with the browser's suppressor | `legacy_call_microphone_test.dart` | ci `test` |
| The web processor survives restart, device switch and mute; `copyWith` keeps it | `livekit_processor_restart_test.dart` | ci `test` |
| Legacy sessions leave CallManager; #48 stays fixed | `call_manager_dsp_test.dart` | ci `test` |
| Names, ABI, method channels, vendored changes, overrides, `// COMMET` count | `check_contracts.py` | ci `voice-dsp` |
| The web build carries `audio_dsp.js`, the worklet and a real wasm | `check_contracts.py --web-build` | ci `voice-dsp`, build, release |
| The browser DSP suppresses; a missing or broken wasm or worklet is caught by `probe()` and `create()` | `web_noise_loop.mjs` | ci `voice-dsp` |
| What a room's RTCRtpSender carries in the browser is suppressed, before and after a restart; a legacy call's too; no wasm keeps the browser's suppressor | `web_noise_loop.mjs --app` | ci `voice-dsp` |
| Inside the real WebRTC (Linux): the microphone test on the picked device, "Hear myself" off, noise ≥ 20 dB down in what is encoded, DeepFilterNet suppressing by the end (measured 2026-09-25: 61 dB) | `native_noise_loop.sh` | integration-test |
| Screen audio and DJ music do not leave the microphone without WebRTC's processing: restored after negotiation, not for the mic itself, not while muted, desktop only | `shared_audio_processing_test.dart` | ci `test` |
| ... and inside the real WebRTC, with the DJ's music track: restored to within 3 dB of before (the libwebrtc internal it relies on still holds) | `native_noise_loop.sh` | integration-test |
| After a mute during which a device listed before the microphone went away, the microphone is heard again, within 3 dB of before (`ReselectRecordingDevice`) | `native_noise_loop.sh` | integration-test |
| One NaN, infinity or huge input sample leaves the voice as it was a second later (it used to silence the DSP for good); state that went bad is rebuilt | `tests/non_finite.rs` | ci `test` |
| A capture WebRTC stopped recording from, a web DSP whose worker traps or hangs, a suspended audio context: the call repairs them or keeps the microphone going (docs/voice-call-health.md) | `native_noise_loop.sh`, `web_health_loop.mjs`, `unit_test/voice_health/` | integration-test, ci |

`publish` in ci.yml waits for `voice-dsp`: a release does not go out with
browser suppression broken. The Rust and Dart tests run in `test`, which
`publish` waits for too.

## What still needs a person

Ordered by how badly it hurts if wrong.

1. **Windows.** The native loop runs on Linux. Windows shares the C++ hook
   (`commet_external_audio_processing.h`, checked by the contracts), the
   Dart manager and the Rust library, and CI compiles it, but nothing plays
   audio through it. In Settings → VoIP, "Test microphone" with "Hear
   myself" off: the status line must read "Processing 48 kHz audio".
2. **A real microphone in a real room, and a second person listening.** The
   loops play a recording into a virtual device; a real room has
   reverberation, a real microphone its own noise, and WASAPI/PulseAudio
   their own timing. Speakers, a fan, "Test microphone" with "Hear myself"
   and headphones, then a call with someone else.
3. **A call through a LiveKit server.** The loops cover the microphone as a
   call makes it and puts it on a sender, and the SFU does not touch audio,
   but no loop joins a room: a native test against a local `livekit-server
   --dev` would close that.
4. **Screen-share system audio and DJ music with speakers.** Custom sources
   bypass the capture APM, so they are not gated, and the microphone's echo
   cancellation is restored after they start (see "Known gaps"). The loop
   measures noise suppression coming back; that the echo canceller comes
   back with it follows from the same options, but only a listener hears
   echo: share a video with sound on speakers and ask someone whether they
   hear themselves.
5. **Encrypted rooms on web** still decrypt with the processed track, before
   and after a mic switch.
6. **Packaged builds** (flatpak, .deb, MSIX, a web server serving
   `application/wasm`), not only `flutter run` / `flutter build`.

## Loudspeaker bleed

Report (2026-09-17): "I could watch videos unmuted and nobody heard them,
now they do", on a speakers-and-microphone setup with no headset.

### What went wrong

`tests/speaker_bleed.rs` puts real recordings (`testdata/README.md`)
through a loudspeaker-and-room simulation (band limiting, 20 ms of air, a
Schroeder room) and measures what leaves the client. Before the fix, at the
shipping defaults:

| Scenario, capture level | Attenuation | Gate open | VAD |
|---|---|---|---|
| user talking, -22 dBFS | 0.0 dB | 91 % | 0.67 |
| noisy room (fan, PC), -40 dBFS | 48.9 dB | 0 % | 0.01 |
| video dialogue on speakers, -34 dBFS | 0.2 dB | 89 % | 0.74 |
| music on speakers, -34 dBFS | 2.6 dB | 76 % | 0.59 |
| a friend's stream bleeding back, -30 dBFS | 0.2 dB | 96 % | 0.83 |

Steady background noise was gone, and a loudspeaker playing speech or music
went straight through: in automatic mode the gate only consulted RNNoise's
speech probability, which is high for a voice out of a loudspeaker however
quiet or reverberant; the only level criterion was -70 dBFS; the manual
threshold defaulted to -50 dBFS, 15 to 25 dB below typical bleed; and the
far-end ducker was vetoed by the VAD in exactly the case it was for.

`rust/audio_dsp` had not changed since it landed. What changed on
2026-09-14 is what ran *instead*: `f546eea6` made `MatrixLivekitBackend.join`
pass `noiseSuppression: false` while our DSP is on, and `37ab8327` vendored
flutter-webrtc 1.6.2, whose desktop `GetUserMedia` is the first to map that
flag onto `RTCAudioOptions` (the commetchat `hkdf` fork before it always set
`googNoiseSuppression: true`). From that build on, WebRTC's suppressor was
off on desktop for the first time, and the gate let through what it used to
shave off.

### The fix

`rust/audio_dsp/src/bleed.rs`, fed with two references: WebRTC's playout
(render hook, all platforms) and the system mix (loopback, desktop). Per
10 ms, on levels between 250 Hz and 4 kHz (the band small loudspeakers
reproduce faithfully):

- The reference-to-microphone *lag* is a physical constant, so it is
  established over many 300 ms windows: each window correlates the
  microphone's envelope with the reference's at every lag up to 120 ms,
  over the frames where the reference plays, and a running average per lag
  has to single one out. Two unrelated signals correlate by chance now and
  then, never consistently at one lag, so a headset never establishes one.
- While a lag is established, windows that follow the reference at it
  teach the *coupling* (microphone peak minus reference peak; the estimate
  is the median of the last 16).
- A frame is the user talking if the microphone is 6 dB above the bleed the
  reference predicts (its recent peak plus the coupling, decaying like a
  room after the reference stops), otherwise it is bleed, and the gate stays
  shut whatever the VAD says.
- Windows a quarter of which the stored coupling cannot explain do not vote
  on the lag (conversation must not erode it), but still teach the coupling
  if they follow the reference very closely (0.85): the speakers were
  turned up.
- No reference, no lag, nothing learned: `Idle`, the gate works as before.
  The user talking without a break, a headset, speakers unplugged: the lag
  fades or never forms, `Idle`.

With the fix, same fixtures and settings (numbers after the first 2 s, the
learning time):

| Scenario | Attenuation | Notes |
|---|---|---|
| video dialogue on speakers, -40 / -34 / -28 dBFS | 40.3 dB each | first detected after 1.5 s |
| music on speakers, -30 dBFS | 42.7 dB | learned after 2.1 s |
| same, reference 80 ms late and in 50 ms bursts | 40.3 dB | WASAPI loopback stalls like this |
| speakers turned up 14 dB mid-video | 39.4 dB | 4 s after the change |
| a friend's stream bleeding back (playout reference) | 53.3 dB | before AEC3, which also works on it |
| user talking over the video, then pausing | voice -0.3 dB, video in the pause -40.3 dB | pause judged from 0.5 s in (gate hold and release) |
| 19 s of talking over music without a break | voice -0.4 dB | |
| headset, video playing, user talking | voice -0.0 dB | bleed never reported |
| no reference (browser), dialogue at -34 dBFS | 0.2 dB | unchanged, see below |

Also changed:

- Automatic input sensitivity now requires the threshold as well as the VAD,
  and the slider is shown in both modes. In a browser, where no system audio
  is visible, putting the marker between the loudspeaker's peaks and the
  user's voice is the tool: at -20 dBFS the fixtures' dialogue comes out
  40 dB down and the voice 0.3 dB down, in either mode. The default stays
  at -50 dBFS so nobody quiet is cut off.
- `MatrixLivekitVoipSession` watches `AudioProcessingManager.isProcessing`:
  if the microphone is live and the DSP has seen no frames for 4 s, it
  restarts the track with WebRTC's suppressor on for the rest of the call.
  Before, `isSupported` (the library loaded) was enough to turn WebRTC's
  off, and a hook that never ran left the call with neither.
- The render level used to be written into the gate from the render thread
  while the capture thread read it; it now goes through the same atomic
  mailbox as the system reference.

Preference: `voipSpeakerBleed` ("Filter out sound from your speakers"),
on by default. Report flags: `speakerBleed` (the gate is held for bleed),
`referenceActive` (system audio is arriving); the settings status line says
"Holding back sound from your speakers." while the first is set. ABI 2:
`Params::speaker_bleed` took the padding byte, `commet_dsp_feed_reference`
is new.

Still not verified: any of this with a real microphone in a real room. The
fixtures are real speech through a simulated room; a real loudspeaker adds
distortion, a real room more reverb, and WASAPI's timing is modelled, not
measured. Test: speakers, a video playing, "Test microphone" with "Hear
myself" *off* (on Linux the monitor would hear itself) and a second person
listening in a call; the status line should say "Holding back sound from
your speakers." within two seconds of the video starting.

## Known gaps

- Knocking: see "Impulsive noise" for what still gets through (a knock on
  a quiet syllable, muffled thumps).
- Other people talking, singing, and noise as loud as the voice: see
  "Background noise".
- Size: DeepFilterNet brings tract and its 8 MB model into
  `librust_lib_commet` (38 MB in a Linux release build, 30 MB stripped),
  and `audio_dsp.wasm` went from 0.5 to 24 MB, fetched by the web app when a call or the
  microphone test first needs the DSP. tract's wasm SIMD kernel was tried
  and ran slower than its generic one for this model's shapes (RTF 0.70
  against 0.39), so the wasm is built without SIMD.
- Android: no Rust library is built (cargokit is commented out in
  `rust/rust_builder/android/build.gradle`), so the manager reports
  unsupported. The vendored LiveKit Android plugin already reaches
  `FlutterWebRTCPlugin.sharedSingleton.getAudioProcessingController()`, so
  the glue is a Kotlin `ExternalAudioFrameProcessing` calling into Rust over
  JNI once the library builds.
- macOS/iOS: `AudioProcessingAdapter.addProcessing` exists in flutter-webrtc,
  glue not written.
- Desktop: every audio sender's AudioOptions are merged into its channel's
  and applied to the one APM the process shares
  (`WebRtcVoiceSendChannel::SetAudioSend` → `SetOptions` →
  `ApplyAudioProcessingOptions`), the last writer wins, and removing a
  sender writes nothing back. Screen-share system audio and the DJ booth's
  music are custom sources created with echo cancellation, gain control and
  noise suppression off. Measured by the native loop: WebRTC's processing
  takes the room noise from -29 to -41 dB on the microphone, and with the
  DJ's music published it is back at -29 until the microphone's options are
  written again. What the user loses is echo cancellation (echo for everyone
  listening to someone on loudspeakers) and gain control, and noise
  suppression where WebRTC's is the one meant to run (preference off, DSP
  unavailable, the watchdog's fallback).

  **Mitigation in place (option B, 2026-09-25):** after any local audio
  publication that is not the microphone, once its sender is negotiated
  (it has outbound RTP statistics), `restoreMicrophoneProcessingAfter`
  (`voip_room/livekit_microphone.dart`) turns the microphone's track off
  and on, and re-enabling it makes its sender write its options back
  (`audio_processing/shared_audio_processing.dart`). A muted microphone is
  left alone: unmuting writes them. Each restore logs "Voice: put the
  microphone's echo cancellation, gain control and noise suppression back
  after a custom audio source".

  **The weak point, for whoever looks at this later:** the mitigation relies
  on a libwebrtc internal (a re-enabled sender re-applies its options), not
  on an API. `integration_test/voice_dsp/native_noise_test.dart` ("a custom
  audio source leaves the microphone's processing alone", run by
  `tools/voice_dsp/native_noise_loop.sh` and the integration-test workflow)
  measures it inside the real WebRTC in three phases and prints them:
  `before -40.9 dB, with the custom source -28.8 dB, restored -40.8 dB`.
  - It fails when "restored" does not come back to "before": a libwebrtc
    update stopped re-applying options on re-enable. Then the options have
    to travel with the custom source instead (option A): create the screen
    audio and music sources with the microphone's options
    (`flutter_screen_capture.cc`, `commet_music_source.h`; the values from
    `microphoneConstraints`), and recreate them when the preference flips.
  - It prints "no longer changes the microphone's processing" when "with the
    custom source" stays near "before": the leak is gone in that libwebrtc
    and the mitigation can be removed.
  - `check_contracts.py` fails if a merge drops the call from the session or
    the re-enable from `restoreMicrophoneProcessing`.

  Also: the microphone is disabled for the ~10 ms between the two platform
  calls, and a custom source whose sender is never negotiated gets the
  microphone restored after 10 s anyway.
- Web per-user volume goes through a `volume` constraint browsers ignore;
  fix with the LiveKit audio element's `volume` and a GainNode for boost.
- Only channel 0 reaches the native hook; a stereo mic's second channel is
  unfiltered. `AudioCaptureOptions` has no `channelCount` in this fork.
- Sounds played through media_kit (join, mute) are not in the AEC reference.
- In a browser, sound playing on the machine outside the call (a video in
  another tab) reaches the room from loudspeakers: only WebRTC playout is
  visible there. The input sensitivity marker is the tool ("Loudspeaker
  bleed"). The Media Capture spec's `echoCancellation: "all"` mode (cancel
  all system audio, not only the page's) would be the browser-side answer;
  which browsers ship it has not been checked.
