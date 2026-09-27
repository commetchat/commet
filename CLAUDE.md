# roscord

Hard fork of Commet (a Flutter Matrix client) by PondLabs. Layout:

- `commet/` the app (Flutter). `tiamat/` the widget library. `widgets/` Matrix widget helpers.
- `rust/rust` the Rust library shipped as `librust_lib_commet` (flutter_rust_bridge, built by cargokit for Linux and Windows only; Android and web do not build it).
- `rust/audio_decode` soundboard clip decoder (symphonia, C ABI linked into `librust_lib_commet`); loudness is measured in Dart (`soundboard_normalizer.dart`).
- `rust/audio_dsp` voice DSP crate (noise suppression with DeepFilterNet3, vendored in `third_party/deep_filter`; input gate, ducking). See `docs/voice-audio-processing.md`.
- `browser_surface/` Flutter plugin (Linux, Windows) that draws the CEF hosts' shared-memory frames into a texture. The hosts are `commet/windows/cef_host` (C++) and `cef_host` in `rust/rust` plus `commet/linux/cef_engine` (C++) on Linux. See `docs/cef-browser-runtime-hosts.md`.
- `rust/dj_audio` DJ booth music player (symphonia decode, 48 kHz stereo, C ABI linked into `librust_lib_commet`). See `docs/dj-booth.md`.
- Voice call health: every second a voice room checks that our microphone still gets through and that we still receive everyone, and repairs either without a rejoin. See `docs/voice-call-health.md`.
- Away status: the amber dot, and where idle time comes from on each platform. See `docs/away-status.md`.
- Call controls outside the window: taskbar thumbnail buttons (Windows), Dock menu (macOS), launcher actions and quicklist (Linux), floating panel (browser). See `docs/voice-controls.md`.
- Updating: check GitHub Releases, and on desktop install one over the running build. See `docs/updating.md`.
- Instagram reels and posts in the chat: native builds play the MP4 from the embed page and show photo posts as their photos, web frames Instagram's embed. See `docs/instagram-reels.md`.
- `third_party/` vendored packages we modify in place. See `third_party/README.md`.

## Rules

- **Never target upstream.** Do not prepare patches, PRs or "upstreamable" designs for Commet (commetchat) or the commetchat forks of flutter-webrtc, livekit-client-sdk-flutter and matrix-dart-sdk. When their code needs changing, copy it into `third_party/` and change it here. Mark local changes with `// COMMET` comments.
- Path dependencies for vendored packages go in `dependency_overrides` in `commet/pubspec.yaml`.
- Browser support matters as much as desktop. Any voice feature needs a web path.

## Toolchains

- `flake.nix` provides Flutter, Dart and the Android SDK via `nix develop`.
- Rust: `cargo test -p audio_dsp`. Without a local toolchain use Docker: `docker run --rm -v "$PWD":/w -w /w rust:1 cargo test -p audio_dsp`.
- Full CI-equivalent builds without a local Flutter: `docker run -d --name build -v "$PWD":/w -w /w/commet ghcr.io/cirruslabs/flutter:3.41.9 sleep infinity`, then inside it `apt-get install -y ninja-build libgtk-3-dev libmpv-dev mpv ffmpeg libmimalloc-dev libkeybinder-3.0-dev libayatana-appindicator3-dev libpulse-dev clang lld cmake pkg-config curl` (`libpulse-dev` is what lets the vendored flutter-webrtc capture system audio for screen share on Linux; without it the build still passes but `getDisplayMedia({audio: true})` yields no audio track), install rustup (cargokit needs cargo), `flutter pub get`, `dart run scripts/codegen.dart`, then `flutter build linux --debug --dart-define PLATFORM=linux` or `flutter build web --release --dart-define PLATFORM=web`. Chown the build output back afterwards.
- Web assets that are built, not written (`e2ee.worker.dart.js`, `audio_dsp.wasm`) come from `commet/scripts/prepare-web.sh` and are gitignored.

## Voice rooms

Multi-user voice is the MatrixRTC/LiveKit path (`commet/lib/client/matrix/components/voip_room/`). Legacy 1:1 calls go through matrix-dart-sdk (`.../components/voip/`). Audio processing hooks into both on native through WebRTC's audio processing module, and into the LiveKit path on web through an AudioWorklet.

## Agent skills

### Issue tracker

Issues live as GitHub issues in `PondLabs/roscord`. See `docs/agents/issue-tracker.md`.

### Triage labels

Defaults: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
