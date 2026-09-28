# Preserved flows outside the CEF BrowserRuntime

This note closes the documentation half of the atomic cutover (epic #110,
ticket #133): every deliberately preserved non-CEF path stays on its existing
runner, and no CEF-owned surface silently substitutes another backend.

## Matrix widget runners that stay

- Android activity, web, iOS, and macOS in-app runners keep their existing
  implementations and presentations (`matrixWidgetUsesCef` is desktop-only).
- Remote HTTP stays as the remote-device QR flow (`remoteHttpClient`).
- Calendar and other non-widget surfaces never enter `BrowserRuntime`.

## Deliberate external flows

- Ordinary external links, SSO (external system browser plus loopback
  server via the vendored `third_party/flutter_web_auth_2`), and
  remote-device Matrix flows remain explicit external/remote actions.
  `MediaEmbedAdapter` and `MatrixWidgetAdapter` turn disallowed links into
  normalized `external` outcomes the caller opens via `LinkUtils`; the
  runtime never navigates them inline.

## Linux official video without a usable CEF host

Linux official video plays through the bundled CEF host, as on Windows
(`mediaEmbedUsesCef` covers Windows and Linux; `linuxOfficialVideoUsesCef` is
true). A build without the host, or a system where CEF's sandbox cannot start
(`linuxCefSandboxUsable`), opens the video in the external browser
(`deliberate-external`). There is no standalone
official-video surface on any platform (N/A boundary).

## Shared media paths

Shared audio crates and the vendored Flutter WebRTC package stay: the old
Linux Pion/WebRTC shim is not a second browser path, and voice/video capture
still goes through the CEF permission broker plus OS/portal mediation (see
`docs/cef-browser-runtime-media.md`).

## What was deleted

After the aggregate gate (#131) went green, CEF routing became
unconditional and the legacy desktop graph was deleted (#132): the Dart
Matrix in-app WebView runner, subprocess/Wry runner, old backend branches,
developer `--widget_runner` launcher, Windows official-video WebView branch,
runner-only IPC assets and polyfills, the Rust/Wry child-runner module and
its crates, `desktop_webview_window` registrations, `flutter_inappwebview_windows`
from the Windows graph (now a no-op stub in
`third_party/flutter_inappwebview_windows_stub/`), WebView2/NuGet/WIL setup,
and Linux WebKitGTK inputs. The matrix gate (`N/A` boundaries, `X`
prohibited markers) and the signed release record prove no deleted backend
can return: a clean image without legacy engines, host CEF, or system
browser libraries still opens every required G cell from the bundle.

See `docs/matrix-widget-browser-runtime.md` for the adapter contract,
`docs/cef-browser-runtime-release-candidate.md` for the G/P/N/A/X matrix,
`docs/cef-browser-runtime-release-record.md` for the signed gate, and
`docs/cef-browser-runtime-rollback.md` for the complete-set rollback that
never revives a legacy engine.
