# Voice audio processing

Client-side noise suppression, input gate and far-end ducking for voice
rooms. Everything runs on the user's own device before audio leaves the
client. Browser support is a first-class target.

Status (2026-09-14): Phase 0 and Phase 1 code is written on branch
`feature/voice-dsp`. Verified so far, all inside a Flutter 3.41.9 container
mirroring CI:

- `cargo test -p audio_dsp`: 17 tests pass; wasm build is 478 KB.
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
2. RNNoise (`nnnoiseless`), which also yields a speech probability.
3. Gate (`gate.rs`): manual threshold or VAD-driven with hysteresis
   (open above 0.5, close below 0.3), 150 ms hold, 5 ms attack, 200 ms
   release, closed gain -40 dB (not a hard mute).
4. Ducker: when the far-end peak (300 ms hold) is above -45 dBFS and local
   VAD is below 0.4, apply -20 dB. Local speech vetoes ducking.
5. Resample back.

Parameters and the report cross threads through atomics; the audio-thread
entry points never allocate after construction (there is a test for it).
RNNoise does very little against pure full-band white noise; real noise is
coloured and the fixtures reflect that.

## Files

| Path | Role |
|------|------|
| `rust/audio_dsp/` | DSP crate, C ABI in `src/ffi.rs`, fixture in `testdata/` |
| `rust/rust/src/lib.rs` | `pub use audio_dsp;` so the symbols ship in `librust_lib_commet` |
| `third_party/livekit-client-sdk-flutter/shared_cpp/commet_external_audio_processing.h` | CustomProcessing adapters |
| `third_party/livekit-client-sdk-flutter/{linux,windows}/livekit_plugin.cpp` | `commetSetExternalAudioProcessing` / `commetClearExternalAudioProcessing` |
| `third_party/livekit-client-sdk-flutter/lib/src/support/native.dart` | Dart side of those methods (`Native.setExternalAudioProcessing`) |
| `third_party/livekit-client-sdk-flutter/lib/src/track/local/local.dart` | `replaceTrack` after a processor is set, restore on stop |
| `commet/lib/client/components/voip/audio_processing/` | manager (stub, native, web), settings and report models |
| `commet/lib/ui/pages/settings/categories/app/voip_settings/voip_audio_processing_settings.dart` | toggles and level meter |
| `commet/web/audio_dsp.js`, `commet/web/audio_dsp.worklet.js` | browser glue |
| `commet/scripts/prepare-web.sh` | builds `audio_dsp.wasm` |

Preferences: `voipNoiseSuppression`, `voipInputSensitivityAuto`,
`voipInputSensitivityDb`, `voipFarEndDucking`.

Vendored LiveKit changes are marked `// COMMET`.

## Building and testing

```sh
# Rust unit tests (17), including a synthesized speech fixture
cargo test -p audio_dsp
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

1. **Linux hook receives frames.** Join a voice room, watch the log for
   "Voice DSP: installed", open Settings → VoIP and confirm the meter moves.
   The report's `sampleRate` should be 48000 with a 48 kHz device.
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
