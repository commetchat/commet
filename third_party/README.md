# third_party

Vendored copies of packages this repo needs to modify. We do not push changes
back to their origin; we change them here.

| Directory | Origin | Ref |
|-----------|--------|-----|
| `livekit-client-sdk-flutter` | https://github.com/commetchat/livekit-client-sdk-flutter (branch `hkdf`) | `19f6b86d7a391876aceabf8ef3e117d399c23899` (2026-05-23) |
| `flutter-webrtc` | https://github.com/flutter-webrtc/flutter-webrtc (tag `1.6.2+hotfix.2`) | `d77879b` (2026-09) |
| `tray_manager` | https://pub.dev/packages/tray_manager | `0.5.3` (2026-09) |
| `flutter_web_auth_2` | https://github.com/ThexXTURBOXx/flutter_web_auth_2 (tag `v4.1.0`) | `4.1.0` (2026) + cutover: `desktop_webview_window` dependency and `lib/src/webview.dart` deleted, `linows.dart` always uses the external-browser loopback server |
| `flutter_inappwebview_windows_stub` | purpose-built cutover stub (no upstream) | `0.0.0-cutover.1`: keeps the `flutter_inappwebview_windows` plugin name with a no-op native registration; links no WebView2 |
| `deep_filter` | https://github.com/Rikorose/DeepFilterNet (`libDF/`, `models/DeepFilterNet3_onnx.tar.gz`, MIT or Apache-2.0) | `d375b2d8309e0935d165700c91da9de862a99c31` (2024-10-17), trimmed to the real-time inference |

`example/`, `test/`, `testfiles/`, `.github/` and git metadata were dropped
from the copies. Local changes are marked with `// COMMET:` comments in Dart
and C++ and listed in `docs/voice-audio-processing.md`.

`flutter-webrtc` replaced the commetchat fork (branch `hkdf`, 1.4.1). Upstream
1.6.2 already carries the fork's only change (`KeyDerivationAlgorithm`
handling in the frame cryptor) and adds what we needed it for: system-audio
capture in `getDisplayMedia({audio: true})` on Windows (WASAPI process
loopback) and Linux (PulseAudio / PipeWire monitor source, needs `libpulse`
dev headers at build time). It pulls the prebuilt libwebrtc `m150.7871.01` at
configure time into `flutter-webrtc/third_party/{downloads,libwebrtc}/`, both
gitignored. `// COMMET` changes: `LoopbackCapturer::SetRawTap` (packets as
they come off the OS, fed by both capturers) and `commet_system_audio_reference.h`
with the `commetStartSystemAudioReference` / `commetStopSystemAudioReference`
methods in `flutter_webrtc.cc`, which give the voice DSP the system mix as a
loudspeaker reference. `commet_music_source.h` with the
`commetCreateMusicTrack` / `commetStopMusicTrack` methods: a local audio
track fed from Rust (`commet_music_pull`) by a 10 ms pacing thread, for the
DJ booth (`docs/dj-booth.md`).

`livekit-client-sdk-flutter` carries a backport of the upstream 2.8.0/2.11.0
unpublish fixes (issue #79): `removePublishedTrack` removes every simulcast
codec sender (a backup codec publishes over its own sender) before it disposes
the publication and renegotiates, backup codec state is cleared on unpublish
and before a full-reconnect republish, and the degradation preference is
applied to backup senders too. Marked `// COMMET` in
`lib/src/participant/local.dart` and `lib/src/track/local/video.dart`.
`AudioPublishOptions.stereo` (DJ booth music): `TF_STEREO` on the published
track, `stereo=1;sprop-stereo=1` munged into our offer for it
(`lib/src/core/transport.dart`), and the subscriber answer asks for stereo
wherever the server's offer has it (`lib/src/core/engine.dart`).
`AudioCaptureOptions.copyWith` carries every field
(`lib/src/track/options.dart`): it used to rebuild the options from six of
the nine, so a copy went back to `stopAudioCaptureOnMute: true` and dropped
the `processor`, which took the web AudioWorklet off the track whenever the
microphone was restarted to change one option. `LocalTrack.restartTrack`
(`lib/src/track/local/local.dart`) takes the processor before `stop()`,
which drops it (upstream reads it after, so every restart lost it), and
puts it on before touching the sender, so the raw capture never goes out.
`restartTrack` also takes the new options only once the new capture exists
(upstream took them first, so a capture that could not be opened was never
tried again), opens the new capture before it stops the old one on desktop
and mobile (a failed open leaves the old one sending; the browser has to
close the old one first, or the new one gets its processing), keeps a web
processor across a failed restart, keeps a track that was muted during the
restart muted, and watches the capture it made for its end. A microphone whose capture ended
stays published (`lib/src/participant/local.dart`), for the app's microphone
watch to repair, instead of being unpublished; a microphone opened for a
publish that failed is stopped; and the local participant's lookup by source
no longer falls back to a publication without a source (it took the DJ
booth's music for the microphone). See
`docs/voice-call-health.md`.

`deep_filter` is libDF, DeepFilterNet's Rust library, which the voice DSP
(`rust/audio_dsp/src/dfn.rs`) suppresses noise with; crates.io only has an
old version without the inference. Only `src/lib.rs`, `src/tract.rs`, the
DeepFilterNet3 model and the licences were copied, and the manifest keeps
just what the inference needs. `// COMMET` changes: the dataset, transforms,
C API, wasm-bindgen and CLI modules dropped; tract 0.21.13 instead of
0.21.4, for its wasm SIMD kernels (a symbol table rename in three places)
and its own ndarray, re-exported as `df::tract::ndarray`; `DEFAULT_MODEL`,
the model's bytes, so a load error is not a panic; the model's path; and on
wasm a getrandom backend that refuses, since tract-onnx's random operators
pull getrandom in and the worker instantiates the wasm without imports.

`tools/voice_dsp/check_contracts.py` fails CI when the `// COMMET` count of
any of these packages goes down or a change noise suppression needs goes missing:
raise its floor when you add markers.

Two upstream flutter-webrtc behaviours on desktop that bit us (see
`docs/voice-audio-processing.md`, "Signal chain"): `getUserMedia` selects
the input only from `optional: [{sourceId}]` and records from device 0
otherwise, and `MediaTrackForId` finds local tracks before received ones
with the same id. A third comes from libwebrtc underneath: its audio device
module keeps the microphone as a position in the device list and looks it
up again whenever recording starts, which it does on every unmute. The
`// COMMET` change in `common/cpp` (`ReselectRecordingDevice`) selects the
microphone again by id before a local audio track is enabled.
The iOS and macOS podspecs pin `WebRTC-SDK` to `150.7871.01`, the version the
vendored `flutter-webrtc` pins (upstream livekit_client made the same move in
2.13.0). CocoaPods installs a single copy of the pod, so if the two pins
differ `pod install` fails. Bump them together.

`tray_manager` shows the system tray icon (voice status: idle, live, muted).
The `// COMMET` change makes the Linux appindicator optional: without
`libayatana-appindicator3-dev` (or `libappindicator3-dev`) at build time the
plugin still builds, answers every call with "not implemented", and the app
runs without a tray icon, instead of the build failing (the Flatpak runtime
has no appindicator). Marked in `linux/CMakeLists.txt` and
`linux/tray_manager_plugin.cc`.
