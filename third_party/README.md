# third_party

Vendored copies of packages this repo needs to modify. We do not push changes
back to their origin; we change them here.

| Directory | Origin | Ref |
|-----------|--------|-----|
| `livekit-client-sdk-flutter` | https://github.com/commetchat/livekit-client-sdk-flutter (branch `hkdf`) | `19f6b86d7a391876aceabf8ef3e117d399c23899` (2026-05-23) |
| `flutter-webrtc` | https://github.com/flutter-webrtc/flutter-webrtc (tag `1.6.2+hotfix.2`) | `d77879b` (2026-09) |

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
loudspeaker reference.

`livekit-client-sdk-flutter` carries a backport of the upstream 2.8.0/2.11.0
unpublish fixes (issue #79): `removePublishedTrack` removes every simulcast
codec sender (a backup codec publishes over its own sender) before it disposes
the publication and renegotiates, backup codec state is cleared on unpublish
and before a full-reconnect republish, and the degradation preference is
applied to backup senders too. Marked `// COMMET` in
`lib/src/participant/local.dart` and `lib/src/track/local/video.dart`.
