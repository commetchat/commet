# Native Linux artifacts and sandbox

Debian, released Ubuntu packages, and the portable Linux artifact run bundled
CEF on X11 and Wayland.

The released native set is Debian 12 baseline, every released Ubuntu `.deb`
(Ubuntu 22.04 and Ubuntu 24.04), and the portable x64 archive. Every package
carries the same staged payload and serves both Matrix presentations through
one release-authoritative engine: CEF windowless/off-screen rendering, with
CPU `OnPaint` frames published through a shared-memory frame ring (see
`docs/cef-browser-runtime-hosts.md`). Embedded presents as a Flutter texture
(`osr-cpu-flutter-texture`); standalone presents the same OSR/CPU frames
inside a roscord-owned window (`osr-cpu-owned-window`).

## Staged resources, locales, helpers, graphics, and sandbox route

The release tooling fetches only the locked `linux-x64` archive, verifies
its size, sidecar SHA-1, project SHA-256, and raw manifest, then stages the
allow-listed runtime (`tools/cef_runtime.py stage --strip`, which also
strips the libraries) and records notices, a CycloneDX SBOM, provenance, and
the staged manifest (`metadata`). The staged directory is installed into the
bundle as `cef/` by `commet/linux/CMakeLists.txt` (`ROSCORD_CEF_RUNTIME_DIR`).
The build SDK staged by `tools/cef_runtime.py stage-sdk`
(`ROSCORD_CEF_SDK_ROOT`) compiles the CEF engine library that `cef_host`
loads (`lib/libroscord_cef_engine.so`). Both flow through the environment,
so release and CI builds stage the same locked inputs. `desktop-build.yml`
(the build behind `ci`'s releases) stages both for its Linux leg. The Debian
job in `release.yml` does not yet.

The staged runtime is flat. CEF on Linux loads ICU data, the `.pak`
resources and `locales/` from the directory that holds `libcef.so`, whatever
`CefSettings` says, so staging moves the archive's `Resources/` into
`Release/`. Every native artifact carries, at minimum:

- `Release/libcef.so`, `Release/v8_context_snapshot.bin`,
  `Release/chrome_100_percent.pak`, `Release/chrome_200_percent.pak`,
  `Release/icudtl.dat`, `Release/resources.pak`;
- locales under `Release/locales`, always including `en-US.pak`;
- the `Release/chrome-sandbox` helper;
- graphics dependencies `Release/libEGL.so`, `Release/libGLESv2.so`,
  `Release/libvk_swiftshader.so`, `Release/libvulkan.so.1`, and
  `Release/vk_swiftshader_icd.json`, so CPU and SwiftShader rendering work
  without host GPU libraries;
- upstream `LICENSE.txt` and `CREDITS.html` notices.

The Dart `requiredLinuxRuntimeFiles`/`requiredLinuxGraphicsFiles` sets and
the Rust `REQUIRED_LINUX_RUNTIME_FILES`/`REQUIRED_LINUX_GRAPHICS_FILES`
constants encode the same list, and `cef_host` refuses to start when any
entry is missing, symlinked, or writable by group/other users
(`validate_cef_root`). The qualified sandbox route is staged with the
payload: Debian packages ship the setuid helper while the portable bundle
relies on the user-namespace route the host probes at launch. Production
command lines never contain `--no-sandbox`, `--disable-sandbox`,
`--disable-setuid-sandbox`, `--disable-gpu-sandbox`,
`--disable-seccomp-filter-sandbox`, or `--disable-namespace-sandbox`; the
host rejects them and the qualification modules deny them by name.

## Debian sandbox ownership/mode and portable user-namespace behavior

`cef_host` accepts exactly two ordinary-user sandbox routes
(`validate_sandbox`): a root-owned setuid helper, or an available
user-namespace/seccomp sandbox. It never runs elevated and never weakens to
`--no-sandbox`.

Debian packages must install the bundled `chrome-sandbox` helper with root
ownership and mode 4755. The required release step sets `root:root` and
`4755` on the staged helper before `dpkg-deb`, so the installed helper is a
setuid-root binary that is never writable by group or other users.
`assertDebianSandboxOwnerMode`/`assert_debian_sandbox_owner_mode`
prove the same rule in fixtures: non-root owners, a missing setuid bit,
group/other writability, and any non-4755 mode all fail closed — matching the
host's launch check bit for bit.

The portable bundle must prove the user-namespace route rather than assume a
setuid installation: no ownership or mode is asserted on its helper copy,
and `assertPortableProvesUserNamespace`/`assert_portable_proves_user_namespace`
fail closed unless the ordinary-user namespace probe (the same `unshare`
probe the host runs) succeeded.

## Both Matrix presentations on every package/compositor cell

The release gate is sixteen cells: four packages (Debian 12, Ubuntu 22.04,
Ubuntu 24.04, portable x64) times two compositors (X11, Wayland) times two
presentations (embedded, standalone). Package ids parse exactly
(`debian-12`, `ubuntu-22.04`, `ubuntu-24.04`, `portable`/`portable-x64`) and
compositor ids parse exactly (`x11`, `wayland`); unknown values fail closed
instead of selecting another cell or a fallback engine.

Every cell reports the same OSR/CPU path — `osr-cpu-flutter-texture` for
embedded, `osr-cpu-owned-window` for standalone — and every cell shares
account state and policy: embedded and standalone surfaces for one account
use the same host request context through the same four-operation seam, so
Matrix contract, profiles, navigation, permissions, input, IME, focus,
resize, DPI, and close behavior match across packages exactly as they match
across compositors. The Dart `linuxNativePresentationPath`/
`linuxCellSharesAccountPolicy` functions and the Rust
`cell_presentation_path`/`cell_shares_account_policy` functions expose the
same matrix vocabulary so fixtures stay aligned.

## Clean environments without WebKitGTK or host CEF

Native cells resolve no host engine. The host `dlopen`s an absolute path
under the explicit `--cef-root` and never searches the system; Debian
`Depends` carry no WebKitGTK entry; and the qualification modules deny host
CEF paths (`/usr/lib/chromium`, `/usr/lib64/chromium`,
`/usr/local/lib/chromium`, `/opt/google/chrome`, `/opt/chromium`,
`/snap/`, host-named lookups), WebKitGTK/Wry names, and every fallback
backend (`webkit`, `wry`, `webview2`, `system cef`, `external chromium`,
unowned browsers) by name, case-insensitively. `assertCleanEnvironment`/
`assert_clean_environment` prove both presentations pass with no host CEF,
no WebKitGTK, and no GPU availability, with forced CPU rendering as the
release-authoritative path. Static contract checks assert the Linux sources
contain the OSR/CPU/bundled vocabulary and none of the host-engine tokens.

## Linux official video plays through the bundled CEF host

Linux official video is an embedded CEF surface, as on Windows
(`cef-official-embed`; `mediaEmbedUsesCef` is true on Linux). It is used when
the build bundles the host and runtime and CEF's sandbox can start
(`isBundledBrowserRuntimeAvailable`, `linuxCefSandboxUsable`). Otherwise the
video opens in the external browser (`deliberate-external`). There is no
standalone
official-video presentation. `assertLinuxVideoUsesCef`/
`assert_linux_video_uses_cef` fail closed if a caller marks the Linux video
path as not CEF-backed.
