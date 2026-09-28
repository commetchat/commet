# Release-candidate matrix, fault, and performance gate

This note defines the atomic acceptance gate for the BrowserRuntime cutover
(epic #110, ticket #131). A release candidate is one Windows/Linux set: one
Windows x64 artifact plus every released Linux x64 artifact (Debian 12
baseline, each released Ubuntu `.deb`, the portable archive, and the GNOME 48
x86_64 Flatpak). One failed mandatory cell blocks publication of the entire
set, and rollback always covers the complete desktop set.

## Compatibility matrix

`G` is a mandatory release-gate cell, `P` is a deliberately preserved non-CEF
path, `N/A` is not currently exposed and must not silently substitute a
backend, and `X` is prohibited in the production target graph or artifact.

| Surface / presentation | Windows x64 | Native Linux X11 | Native Linux Wayland | Flatpak X11 | Flatpak Wayland |
| --- | --- | --- | --- | --- | --- |
| Matrix widget / embedded | G: OSR/CPU Flutter texture | G: OSR/CPU Flutter texture | G: OSR/CPU Flutter texture | G: OSR/CPU Flutter texture | G: OSR/CPU Flutter texture |
| Matrix widget / standalone owned window | G: windowed CEF in owned HWND | G: OSR/CPU in owned window | G: OSR/CPU in owned window | G: OSR/CPU in owned window | G: OSR/CPU in owned window |
| Official video / embedded | G: CEF with loopback origin/Referer | P: external browser | P: external browser | P: external browser | P: external browser |
| Official video / standalone | N/A | N/A | N/A | N/A | N/A |
| Remote-device, external links, SSO | P: deliberate external | P: deliberate external | P: deliberate external | P: deliberate external | P: deliberate external |
| WebView2, WebKitGTK/Wry, system CEF, runtime download, unowned browser | X | X | X | X | X |

Concretely the gate enforces 23 mandatory G cells (3 Windows, 16 native
Linux Matrix cells across 4 packages x 2 compositors x 2 presentations, 4
Flatpak Matrix cells), 11 preserved P flows (8 Linux official-video cells
plus 3 external/remote flows), 5 N/A boundaries (official-video standalone),
and 5 prohibited X markers (absent everywhere).

## Fault injection

Every fault family below must have passing evidence on every mandatory G
cell (230 records: 10 families x 23 cells). Each record carries the artifact
and hash, locked CEF version, OS/compositor/presentation, injection, ordered
events, command outcomes, metric/log deltas, dump sidecar or explicit
no-dump result, screenshots, proof that forbidden backends were not loaded,
and proof that side effects were not replayed.

| Family | Injections covered |
| --- | --- |
| host | kill at idle, during load, during each command class; clean-start failure |
| renderer | every termination status (crash, OOM, killed, abnormal exit, launch failed, integrity failure), hang with 5 s grace, per-surface recovery budget (2 per 60 s) |
| gpu | crash, launch failure, degrade to CPU, disable after 2 failures per 60 s |
| utility | crash, network-service failure, launch failure |
| heartbeat | 10 s without heartbeat marks unresponsive; 5 s grace, diagnostics, terminate, require PID/lock release before restart |
| bundle | deterministic invalid bundle/hash/signature (terminal, no retry) |
| protocol | version/framing/auth violations (terminal, no retry) |
| sandbox | missing sandbox handle, bypass flags (terminal, blocks open) |
| profile-lock | locked, corrupt, unavailable profiles; quarantine and re-authentication |
| retry-budget | 3 host restarts per 60 s (250 ms, 1 s, 4 s); healthy 60 s resets; manual Retry starts one fresh epoch |

## Performance thresholds

On declared minimum/reference hardware, every G cell must satisfy:

| Metric | Threshold |
| --- | --- |
| Host ready, cold | at most 5 s |
| First local-fixture paint after open | at most 3 s |
| Surface close | at most 2 s |
| 1280x720 CPU OSR fixture | at least 30 FPS for 60 s, no stale/corrupt frames |
| p95 input-to-present latency | at most 100 ms |
| 30-minute mixed soak | host RSS growth at most 15 % after warm-up |
| Orphaned host/helper processes after close | none |

## Manual evidence

Each G-cell group requires hands-on evidence (not merely a build pass) for:
permissions (allow/deny/revoke, camera/microphone/capture), IME and
keyboard-only navigation, accessibility (NVDA/Orca, focus, zoom,
high-contrast), forced-CPU rendering, official-video provider playback with
loopback/Referer and external-link handling, crash/retry recovery, and
rollback rehearsal (withdraw the complete set, install the last known-good
complete release).

## Release record and atomic rule

`tools/qualify_release_candidate.py` evaluates one JSON release record with
`cells`, `faults`, `perf`, `manual`, and `forbidden` sections (see
`--example`). Any missing or failing mandatory cell, preserved flow, N/A
boundary, prohibited backend, fault record, perf threshold, or manual topic
blocks the candidate; the tool exits non-zero and names every blocking item.
A passing record yields a signed gate report. Rollback withdraws/stops the
complete desktop set and installs the last known-good complete application
release; Windows-only or Linux-only rollbacks and legacy-engine revivals are
forbidden.
