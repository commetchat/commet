# Voice audio processing

Client-side noise suppression, input gate and far-end ducking for voice
rooms. Everything runs on the user's own device before audio leaves the
client. Browser support is a first-class target.

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
| Model | RNNoise via the `nnnoiseless` crate (BSD-3). DeepFilterNet is the upgrade path if quality is insufficient |

## Architecture

One DSP core, three transports.

```
rust/audio_dsp            C ABI: commet_dsp_*          (tested, cargo test -p audio_dsp)
   |                       |
   | re-exported by        | compiled to wasm32-unknown-unknown
   v                       v
librust_lib_commet     commet/web/audio_dsp.wasm
   |                       |
   | dart:ffi addresses    | instantiated inside the AudioWorklet
   v                       v
vendored livekit plugin (Linux/Windows C++)          commet/web/audio_dsp.worklet.js
   commetSetExternalAudioProcessing                   commet/web/audio_dsp.js (graph glue)
   -> RTCAudioProcessing::SetCapturePostProcessing    -> LiveKit TrackProcessor (processedTrack)
   -> RTCAudioProcessing::SetRenderPreProcessing      -> second worklet input = remote mix
```

Dart entry point: `commet/lib/client/components/voip/audio_processing/`.
`AudioProcessingManager.instance` is created lazily with a conditional
import (stub / native / web). `CallManager` calls `onSessionStarted` and
`onSessionEnded`; `MatrixLivekitBackend.join` passes
`createTrackProcessor()` (web only) and turns the WebRTC/browser noise
suppressor off when ours is on.

### Signal chain

Native (Linux, Windows): mic → WebRTC ADM → APM (AEC3, NS off when ours is
on, AGC off) → **capture post-processing hook → Rust** → Opus. Playout →
**render pre-processing hook → Rust (level only)** → speakers. The hook is
process-global on the shared APM, so it also covers legacy 1:1 calls.
While the DSP is installed and "Filter out sound from your speakers" is on,
the vendored flutter-webrtc also runs its system-audio loopback (WASAPI
process loopback excluding ourselves on Windows, the default sink's monitor
on Linux) and hands every packet to `commet_dsp_feed_reference` from its
capture thread, ahead of the Windows feeder's 160 ms pre-buffer
(`commet_system_audio_reference.h`, `LoopbackCapturer::SetRawTap`).

Web: `getUserMedia` (browser AEC on, NS off, AGC on) →
`MediaStreamAudioSourceNode` → **`commet-dsp` AudioWorklet (wasm)** →
`MediaStreamAudioDestinationNode` → published track. Every remote audio
track is also connected to the worklet's second input for far-end level.

Frame format everywhere: one 10 ms block, mono, float. Native hands
int16-scale floats (480 samples at 48 kHz, or 160/320 at 16/32 kHz which the
crate resamples). The worklet hands unit-scale 128-sample quanta; the crate
buffers them into 480-sample frames, adding 10 ms of latency.

### Processing inside `audio_dsp`

1. Resample to 48 kHz if needed (windowed-sinc FIR, `resample.rs`).
2. Loudspeaker bleed (`bleed.rs`), against the playout and the system mix
   separately: is there anything in the microphone the loudspeakers do not
   explain? See "Loudspeaker bleed" below.
3. RNNoise (`nnnoiseless`), which also yields a speech probability.
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
directly). The audio-thread entry points never allocate after construction
(there is a test for it).
RNNoise does very little against pure full-band white noise; real noise is
coloured and the fixtures reflect that.

### Microphone test

`AudioProcessingManager.startMicTest()` captures the microphone through the
DSP without a call so Settings → VoIP can show the live meter and let the
user hear the result ("Hear myself", `setMicTestMonitor`). Joining a call
stops the test; leaving the settings page stops it too.

- Native: WebRTC only records while a sending audio stream exists, so the
  test builds two local peer connections (`_MicLoopback`) and sends the
  microphone from one to the other. That drives the ADM → APM → hook path
  identically to a call. The received track is `enabled` only while
  monitoring, otherwise it is silent.
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
| `rust/audio_dsp/` | DSP crate, C ABI in `src/ffi.rs`, loudspeaker bleed in `src/bleed.rs`, recordings in `testdata/` (see its README) |
| `rust/audio_dsp/tests/speaker_bleed.rs` | what leaves the client with speakers and no headset, on real speech through a simulated room |
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
| `commet/web/audio_dsp.js`, `commet/web/audio_dsp.worklet.js` | browser glue |
| `commet/scripts/prepare-web.sh` | builds `audio_dsp.wasm` |

Preferences: `voipNoiseSuppression`, `voipInputSensitivityAuto`,
`voipInputSensitivityDb`, `voipFarEndDucking`, `voipSpeakerBleed`.

Vendored LiveKit and flutter-webrtc changes are marked `// COMMET`.

## Building and testing

```sh
# 25 unit tests and 15 recording driven ones (tests/speaker_bleed.rs)
cargo test -p audio_dsp
# every scenario with its measured numbers
cargo test -p audio_dsp --test speaker_bleed -- --nocapture
# or without a local toolchain
docker run --rm -v "$PWD":/w -w /w rust:1 cargo test -p audio_dsp

# WebAssembly (also done by commet/scripts/prepare-web.sh)
cargo build -p audio_dsp --release --target wasm32-unknown-unknown

# Diagnostic: attenuation / VAD / allocations for synthetic input
cargo run -p audio_dsp --release --example diag
```

After changing `pubspec.yaml` (LiveKit is now a path dependency) run
`flutter pub get` in `commet/`.

## What to verify first

Ordered by how badly it hurts if wrong.

1. **Hook receives frames (Linux and Windows).** Open Settings → VoIP and
   press "Test microphone": the meter must move and the status line must
   read "Processing 48 kHz audio" (or 16/32 kHz). "attached but no
   microphone audio is reaching it" means the APM hook is not being called.
   Then toggle noise suppression with "Hear myself" on and listen.
2. **Web mic switch keeps the filter.** `setProcessor` now calls
   `replaceTrack(processedTrack)`; switch microphones mid-call and record the
   remote side.
3. **Web AudioContext is running.** `audio_dsp.js` resumes the context in
   `create`; if the join did not come from a user gesture the log says so.
4. **Screen-share system audio on Linux and Windows.** Comes from the
   vendored flutter-webrtc 1.6.2 (`third_party/flutter-webrtc`), which feeds
   a loopback capture into a `kCustom` audio source. Custom sources bypass
   the ADM, so they should not pass the capture APM (and our gate); check by
   sharing music with suppression on. If it is denoised or gated, gate the
   processor on the mic source.
5. **Encrypted rooms on web** still decrypt with the processed track, before
   and after a mic switch.
6. ~~libwebrtc exports the hook~~ Done: the methods are virtual (not in
   `nm -D`), but `strings libwebrtc.so` shows `RTCAudioProcessingImpl` and
   `CustomProcessingAdapter`, so the implementation is in the 1.4.0 binary.
7. **Packaged builds** (flatpak, .deb, MSIX, web bundle with
   `application/wasm` MIME type), not only `flutter run`.

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

- Android: no Rust library is built (cargokit is commented out in
  `rust/rust_builder/android/build.gradle`), so the manager reports
  unsupported. The vendored LiveKit Android plugin already reaches
  `FlutterWebRTCPlugin.sharedSingleton.getAudioProcessingController()`, so
  the glue is a Kotlin `ExternalAudioFrameProcessing` calling into Rust over
  JNI once the library builds.
- macOS/iOS: `AudioProcessingAdapter.addProcessing` exists in flutter-webrtc,
  glue not written.
- Web legacy 1:1 calls (matrix-dart-sdk) bypass the worklet. Wrap the
  `MediaDevices` handed to the SDK in `MatrixVoipComponent.mediaDevices`.
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
