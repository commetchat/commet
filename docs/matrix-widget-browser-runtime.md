# Matrix widgets and BrowserRuntime

`MatrixWidgetAdapter` is the contract seam between the Matrix widget protocol
and `BrowserRuntime`. It keeps Matrix-specific behavior in Dart while the CEF
host receives only the generic `SurfaceSpec`, `ScriptCommand`, and
`SurfaceEvent` values defined by BrowserRuntime.

## Launch data

`MatrixWidgetAdapterLaunch.fromMatrixWidget` builds one immutable launch
record from a `MatrixUserWidgetInfo` and `MatrixRoom`. The record preserves the
existing substitutions:

- `$matrix_user_id`, `$matrix_room_id`, and `$matrix_display_name`;
- `$org.matrix.msc3819.matrix_device_id` and
  `$org.matrix.msc4039.matrix_base_url`;
- `$chat.commet.color_scheme` and `$org.matrix.msc2873.client_theme`.

`buildWidgetUri` adds `parentUrl`, `widgetId`, `accountId`, and `profileKey` to
the URL. `profileKey` is the stable local `MatrixClient.identifier`; it is not
a Matrix user id or a homeserver URL. The generated `SurfaceSpec` carries the
same profile, presentation/privacy mode, initial navigation, allowed page and
parent origins, and capability policy.

## Widget bridge

`MatrixWidgetBrowserRuntimeTransceiver` adapts the old `WidgetTransceiver`
interface to BrowserRuntime script envelopes. Opening a session waits for the
typed `ReadyEvent`, then sends a generic `evaluate_javascript` command
containing the adapter-owned bridge script. The native host evaluates that
command in the page and completes it with a host-sourced terminal script event.
The script is the BrowserRuntime equivalent of `widgets_ipc.js` and
the Rust `call_ipc.js` fallback: it installs the `window.parent.postMessage`
shim, recursive binary conversion, `sessionStorage` rendezvous, and the
`__roscordBrowserRuntimeReceive`/`__roscordBrowserRuntimeSend` callbacks.
Matrix vocabulary remains in the adapter and existing Matrix
message/capability handlers; `cef_host` sees only an opaque script channel and
generic script values.

The bridge intentionally retains the old wire details:

- outbound values use `chat.commet.toWidget:<counter>` storage keys;
- inbound values must use `chat.commet.fromWidget:<counter>` keys;
- each payload is an underscore-prefixed, newline-delimited UTF-8 frame;
- both directions remove their session-storage key after the handoff, matching
  the existing in-app transceiver behavior;
- page/app origin checks are applied before a frame is delivered;
- recursive `ArrayBuffer` and `Blob` values are decoded by
  `MatrixWidgetTransport`, including nested lists and maps.

App-to-page messages use a generic `dispatch_script_message` command. The
host invokes `window.__roscordBrowserRuntimeReceive` in the ready page, while
the renderer callback sends page-to-app JSON back as a `ScriptMessageEvent`
with `source: page`. The host never parses Matrix actions, capabilities, or
storage-key prefixes; the adapter performs those protocol and origin checks.
Bridge installation errors close the just-opened surface and remain retryable.

`MatrixWidgetBrowserRuntimeRunner` reuses `MatrixWidgetMessageHandler` and
`MatrixWidgetCapabilitiesManager`, so capability prompts, accepted/rejected
state, and the Matrix widget API continue to use their existing protocol
names and implementations. Those Matrix capability names stay in Dart; only
optional generic host policy flags are copied into `SurfacePolicy`.

## Lifecycle and platform boundaries

`MatrixWidgetAdapter` owns at most one active BrowserRuntime session. Opening a
new session is serialized with other opens and awaits deterministic disposal of
the previous one. Closing sends
the typed BrowserRuntime close operation, waits for the closed event (with a
bounded timeout), and then tears down the transceiver and event subscriptions.

Android, web, iOS, macOS, remote HTTP, calendar, and deliberate
external-browser flows keep their existing runners as preserved paths (see
`docs/cef-browser-runtime-preserved-flows.md`). The adapter does not add a
fallback browser backend.

## Windows embedded presentation (#121)

`EmbeddedBrowserSurface` (`commet/lib/browser_runtime/embedded_browser_surface.dart`)
owns one `PresentationMode.embedded` surface through the four-operation seam.
The host renders windowless OSR. It copies each CPU `OnPaint` into the next
slot of the surface's shared-memory frame ring and publishes a `frame_ready`
event carrying the ring name, slot, size, stride, format and sequence. The
Dart `ClientFrameRing` keeps the newest frame, coalescing older frames. The
`browser_surface` plugin draws the slot into the Flutter `Texture` that
`EmbeddedBrowserView` shows (frame metadata in tests without a native
binding). A per-slot seqlock keeps a slot the host is rewriting from being
drawn. No CEF buffer is retained past the paint callback, and pixels never
reach Dart. See `docs/cef-browser-runtime-hosts.md`.

Input, resize/DPI, focus, and close travel as ordered typed commands:
pointer down/up/move/enter/leave, wheel deltas, keyboard press/release,
IME start/update/commit/cancel with ordered selection, `WasResized` plus
`GetScreenInfo` for DPI, `SetFocus`, and deterministic `CloseBrowser`. Page
selection stays owned by the page; the host only delivers ordered input.

Forced software rendering (`WindowsBrowserRuntime(forceSoftwareRendering: true)`
→ `--cef-software-rendering` → `--disable-gpu --disable-gpu-compositing`)
keeps the same CPU frame/input/resize/focus contract; it never selects another
engine. Failures remain typed and bounded, and no legacy, system, or unowned
browser backend is reachable from the embedded path.

## Windows standalone presentation (#122)

`StandaloneBrowserSurface` (`commet/lib/browser_runtime/standalone_browser_surface.dart`)
owns one `PresentationMode.standalone` surface through the same four-operation
seam. Standalone and embedded surfaces share one lazily started host, one
account request context, one policy, and one permission mediation without
starting another host; two surfaces for one account observe the same browser
state while different accounts stay isolated.

The Windows host creates a roscord-owned top-level `HWND` per standalone
surface (`CreateStandaloneWindow`/`RegisterStandaloneWindowClass`) and parents
the windowed CEF browser as its child (`SetAsChild`). Geometry travels through
ordered `resize` commands applied with `SetWindowPos`/`MoveWindow` plus
`NotifyMoveOrResizeStarted`/`NotifyScreenInfoChanged` for DPI; focus and
z-order travel through ordered `focus` commands applied with
`SetForegroundWindow`/`BringWindowToTop`/`SetWindowPos` plus `SetFocus`.
Validated geometry and focus are reported back as `window_changed` events,
which the Dart surface tracks as `StandaloneWindowGeometry` and `isFocused`.
Pointer, keyboard, wheel, and IME input use the same ordered synthetic channel
as embedded (windowed browsers additionally receive native `HWND` input and
IME messages); popups stay canceled synchronously and become owned child
surfaces or explicit external actions, never unowned native windows. Close is
deterministic `CloseBrowser` plus `DestroyStandaloneWindow` in
`OnBrowserClosed`, so no orphan `HWND` survives process cleanup.

Windowed standalone surfaces never emit frames through Flutter: the Flutter
`StandaloneBrowserWindow` only ever builds a status placeholder for its owned
surface (geometry, focus, lifecycle), never a texture, platform view, or
another engine view. Forced software rendering uses the same host flag with
the same input/resize/focus/close contract in software; cleanup shares the
same `CloseBrowser`/`OnBrowserClosed`/`Shutdown` path and request-context
release as embedded.

## Official video (MediaEmbedAdapter, #126)

`MediaEmbedAdapter`
(`commet/lib/client/components/video_embed/media_embed_adapter.dart`)
migrates Windows official-video playback through the same four-operation seam.
Only `OfficialVideoEmbedSource` enters CEF; native direct-stream sources keep
using the media-kit player and are never adapted.

- `MediaEmbedLaunch` is the immutable caller record: provider embed URL,
  autoplay flag, `official-video` shared persistent profile (third-party
  provider cookies, not Matrix account state), embedded presentation, and the
  loopback wrapper URI. Standalone presentation is rejected at construction:
  no standalone official-video surface exists.
- The wrapper page is byte-identical in contract to the WebView one: served
  from `http://127.0.0.1:<port>/embed` (real origin, so provider iframes send
  a Referer), `pageOrigin` stays `https://www.youtube.com` for YouTube,
  autoplay stays a URL parameter, and the iframe keeps
  `allow="autoplay; encrypted-media; fullscreen; picture-in-picture"`,
  `allowfullscreen`, and `referrerpolicy="strict-origin-when-cross-origin"`.
- `toSurfaceSpec()` declares the embed host, page origin, the shared
  YouTube/YouTube-nocookie/Instagram allowlist, and the loopback origin, with
  `allowExternalNavigation: true`. Disallowed user-initiated links surface as
  normalized `external` outcomes that the dialog opens via `LinkUtils`
  (explicit external action, embed stays); blocked/cancelled outcomes are
  cancellations with no callback.
- `MediaEmbedSession` owns one `EmbeddedBrowserSurface`, exposes its
  frame/event streams for the dialog's loading/error/retry/close chrome, and
  forwards pointer/wheel/focus plus resize/DPI. `MediaEmbedAdapter` keeps one
  active session with serialized opens. Disposal closes the runtime surface
  and the loopback server: no profile, host, or owned-window leak.
- Windows and Linux route through CEF (`mediaEmbedUsesCef`:
  `!isWeb && (isWindows || isLinux)`) when the build bundles the host. A
  Linux build without it, or where CEF's sandbox cannot start, opens the
  video in the external browser. Web, macOS,
  Android, and iOS keep their existing paths. There is no standalone
  official-video surface. The legacy WebView
  branches were deleted at the cutover (#132); desktop routing is now
  unconditional (see below).

## Recovery, diagnostics, and observability fan-in (#127)

`surface_recovery.dart`, `surface_diagnostics.dart`, and
`recovery_surface_ui.dart` integrate bounded recovery across every surface
above (Windows embedded/standalone, Linux embedded/standalone, Flatpak both
presentations, official video). Host restart restores only declarative
`SurfaceSpec` state in stable `SurfaceId` order; side-effecting commands,
permissions, downloads, and history are never replayed. Renderer recovery is
surface-scoped, GPU failure degrades to CPU, and retry budgets plus terminal
states are enforced by `RuntimeLifecycle`. Reconnecting, crashed-surface,
retry, close, and diagnostic-reporting UI is accessible, logs/metrics/dumps
and diagnostic IDs are consent-gated, rate-limited, and redacted, and clean
close drains surfaces and host processes without orphaning. See
`docs/cef-browser-runtime-recovery.md`.

## Cutover: unconditional desktop routing (#132)

After the aggregate gate (#131) went green, desktop Matrix widgets use this
adapter unconditionally. `matrixWidgetUsesCef` routes Windows and Linux to
`MatrixWidgetComponent.openCefMatrixWidget`; the deleted runners are the Dart
`subprocess/` Wry module, the Rust/Wry child-runner binary, module, export,
and native dispatch (`--widget_runner`), the host-Chromium launcher inside
the remote-HTTP runner, the developer launcher, and the Windows web-view
branches. `WidgetHostType` is now `embedded`, `standalone`,
`remoteHttpClient`, and `androidActivity`: desktop offers embedded plus
standalone (a roscord-owned CEF window), remote HTTP stays as the
remote-device QR flow, and Android/web keep their existing runners.

`_CefMatrixWidget` opens one adapter session per overlay, attaches an
`EmbeddedBrowserSurface.attached` (Flutter texture plus ordered
pointer/wheel/focus/resize/key input) or a `StandaloneBrowserSurface.attached`
(status placeholder; the owned window presents natively), and forwards
`external` navigation outcomes to explicit `LinkUtils` actions. Protocol
ownership stays with the adapter session: presentation `dispose` never sends
`close`. `main.dart` constructs `WindowsBrowserRuntime` (named pipes) on
Windows and the new `LinuxBrowserRuntime` (owner-only Unix socket,
`--socket/--parent-nonce/--cef-root` launch) on Linux; both share the framed
protocol, lifecycle, and recovery through `CefHostFlavor`.

Preserved flows are untouched: Android activity, remote HTTP, web/macOS/iOS
in-app runners, calendar, deliberate external links, Linux native video, and
shared audio/WebRTC. SSO keeps working through the external system browser
plus loopback server: `flutter_web_auth_2` is vendored into `third_party/`
with its WebView2 webview deleted, and the Windows `flutter_inappwebview`
plugin is a no-op stub (`third_party/flutter_inappwebview_windows_stub/`)
that links no foreign engine.
