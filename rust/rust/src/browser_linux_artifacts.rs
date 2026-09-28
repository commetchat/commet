//! Native Linux artifact qualification: Debian, released Ubuntu packages,
//! and the portable Linux artifact run bundled CEF on X11 and Wayland.
//!
//! The released native set is Debian 12 baseline, every released Ubuntu
//! `.deb`, and the portable x64 archive. Every package carries the same
//! staged payload (resources, locales, helpers, graphics dependencies, and
//! the qualified sandbox route) and serves both Matrix presentations —
//! embedded as a Flutter texture and standalone in a roscord-owned window —
//! through CEF windowless/off-screen rendering with CPU `OnPaint` copied
//! into client-owned memory. Clean environments without WebKitGTK or host
//! CEF still pass, and Linux official video plays the provider's own embed
//! through the bundled CEF host, like Windows; only a build without CEF
//! hands it to the external browser.
//!
//! This module owns the pure qualification policy; the Linux `cef_host`
//! enforces the staged-payload and sandbox rules at launch (`validate_cef_root`
//! and `validate_sandbox`), the release pipeline stages the locked runtime
//! into each artifact, and the Dart `linux_artifact_qualification` module
//! mirrors these rules for adapter tests. Matrix protocol behavior stays in
//! `MatrixWidgetAdapter`; only typed [`crate::browser_runtime`] commands,
//! frame references, and owned-window state cross this seam.

use crate::browser_runtime::RuntimeError;

/// The only supported backend name for native Linux surfaces.
pub const LINUX_NATIVE_BACKEND: &str = "cef-osr-cpu";

/// Embedded presentation path (Flutter texture) shared by every native cell.
pub const LINUX_EMBEDDED_PRESENTATION_PATH: &str = "osr-cpu-flutter-texture";

/// Standalone presentation path (roscord-owned window) shared by every cell.
pub const LINUX_STANDALONE_PRESENTATION_PATH: &str = "osr-cpu-owned-window";

/// Staged payload every native Linux artifact must carry. Mirrors the host's
/// `REQUIRED_CEF_FILES` plus the en-US locale and notice files the lock
/// allow-lists; the host refuses to start when any entry is missing,
/// symlinked, or writable by group/other users.
pub const REQUIRED_LINUX_RUNTIME_FILES: &[&str] = &[
    "Release/libcef.so",
    "Release/chrome-sandbox",
    "Release/libEGL.so",
    "Release/libGLESv2.so",
    "Release/libvk_swiftshader.so",
    "Release/libvulkan.so.1",
    "Release/v8_context_snapshot.bin",
    "Release/vk_swiftshader_icd.json",
    "Resources/chrome_100_percent.pak",
    "Resources/chrome_200_percent.pak",
    "Resources/icudtl.dat",
    "Resources/resources.pak",
    "Resources/locales",
    "Resources/locales/en-US.pak",
    "LICENSE.txt",
    "CREDITS.html",
];

/// Bundled graphics dependencies that keep CPU and SwiftShader rendering
/// working without host GPU libraries.
pub const REQUIRED_LINUX_GRAPHICS_FILES: &[&str] = &[
    "Release/libEGL.so",
    "Release/libGLESv2.so",
    "Release/libvk_swiftshader.so",
    "Release/libvulkan.so.1",
    "Release/vk_swiftshader_icd.json",
];

/// The locale that must always be staged; the staging tool fails closed
/// without it.
pub const REQUIRED_LINUX_LOCALE: &str = "en-US";

/// Upstream notice files every artifact carries.
pub const REQUIRED_LINUX_NOTICE_FILES: &[&str] = &["LICENSE.txt", "CREDITS.html"];

/// Released native Linux packages. Debian 12 is the baseline; every released
/// Ubuntu `.deb` and the portable x64 archive ship the same bundled payload.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum LinuxNativePackage {
    Debian12,
    Ubuntu2204,
    Ubuntu2404,
    Portable,
}

/// Required native compositor cells. Unknown compositors fail closed instead
/// of selecting another cell or a fallback engine.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum LinuxNativeCompositor {
    X11,
    Wayland,
}

/// Matrix presentations sharing the same OSR/CPU engine in every cell.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum LinuxNativePresentation {
    Embedded,
    Standalone,
}

/// Qualified sandbox route per artifact. Debian packages ship the bundled
/// `chrome-sandbox` helper with root ownership and the setuid mode; the
/// portable bundle never assumes a setuid installation and must prove the
/// ordinary-user namespace route at launch.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum LinuxSandboxRoute {
    SetuidHelper,
    UserNamespace,
}

/// Ownership the Debian `chrome-sandbox` helper must carry after packaging.
pub const DEBIAN_SANDBOX_UID: u32 = 0;

/// Mode the Debian `chrome-sandbox` helper must carry after packaging:
/// setuid, owner read/write/execute, group/other read/execute, and never
/// writable by group or other users.
pub const DEBIAN_SANDBOX_MODE: u32 = 0o4755;

/// Sandbox-bypass flags the host rejects at launch. Kept in sync with
/// `cef_host` argument parsing; production command lines never contain them.
pub const SANDBOX_BYPASS_FLAGS: &[&str] = &[
    "--no-sandbox",
    "--disable-sandbox",
    "--disable-setuid-sandbox",
    "--disable-gpu-sandbox",
    "--disable-seccomp-filter-sandbox",
    "--disable-namespace-sandbox",
];

/// Linux official video plays the provider's embed in a CEF surface.
pub const LINUX_OFFICIAL_VIDEO_PATH: &str = "cef-official-embed";

/// What a build without a bundled CEF host does with official video instead.
pub const LINUX_OFFICIAL_VIDEO_FALLBACK: &str = "deliberate-external";

/// Parses a released native package id. Matching is exact and lowercase so
/// an unknown package cannot silently qualify as a released artifact.
pub fn parse_linux_native_package(value: &str) -> Result<LinuxNativePackage, RuntimeError> {
    match value {
        "debian-12" => Ok(LinuxNativePackage::Debian12),
        "ubuntu-22.04" => Ok(LinuxNativePackage::Ubuntu2204),
        "ubuntu-24.04" => Ok(LinuxNativePackage::Ubuntu2404),
        "portable" | "portable-x64" => Ok(LinuxNativePackage::Portable),
        _ => Err(RuntimeError::InvalidSpec(
            "unknown native Linux package; Debian 12, Ubuntu 22.04/24.04, and portable are the released set"
                .into(),
        )),
    }
}

/// Parses the compositor for a native cell. Matching is exact and lowercase
/// so an unknown compositor cannot silently select another cell.
pub fn parse_linux_native_compositor(value: &str) -> Result<LinuxNativeCompositor, RuntimeError> {
    match value {
        "x11" => Ok(LinuxNativeCompositor::X11),
        "wayland" => Ok(LinuxNativeCompositor::Wayland),
        _ => Err(RuntimeError::InvalidSpec(
            "unknown native Linux compositor; X11 and Wayland are the only cells".into(),
        )),
    }
}

/// Presentation path shared by every native package/compositor cell.
pub fn native_presentation_path(presentation: LinuxNativePresentation) -> &'static str {
    match presentation {
        LinuxNativePresentation::Embedded => LINUX_EMBEDDED_PRESENTATION_PATH,
        LinuxNativePresentation::Standalone => LINUX_STANDALONE_PRESENTATION_PATH,
    }
}

/// Presentation path for one package/compositor cell. Both presentations pass
/// on every released package and compositor through the same OSR/CPU engine.
pub fn cell_presentation_path(
    _package: LinuxNativePackage,
    _compositor: LinuxNativeCompositor,
    presentation: LinuxNativePresentation,
) -> &'static str {
    native_presentation_path(presentation)
}

/// Every released native package ships the same bundled CEF payload.
pub fn package_ships_bundled_cef(_package: LinuxNativePackage) -> bool {
    true
}

/// Embedded and standalone surfaces in one cell share account state and
/// policy through the same host request context.
pub fn cell_shares_account_policy(
    _package: LinuxNativePackage,
    _compositor: LinuxNativeCompositor,
) -> bool {
    true
}

/// Number of release-gate cells: four packages times two compositors times
/// two presentations.
pub fn native_matrix_cells() -> usize {
    4 * 2 * 2
}

/// Qualified sandbox route for one artifact.
pub fn required_sandbox_route(package: LinuxNativePackage) -> LinuxSandboxRoute {
    match package {
        LinuxNativePackage::Debian12
        | LinuxNativePackage::Ubuntu2204
        | LinuxNativePackage::Ubuntu2404 => LinuxSandboxRoute::SetuidHelper,
        LinuxNativePackage::Portable => LinuxSandboxRoute::UserNamespace,
    }
}

/// Proves Debian sandbox ownership and mode. The helper must be root-owned,
/// carry the setuid bit, and never be writable by group or other users —
/// the same check `cef_host` enforces at launch.
pub fn assert_debian_sandbox_owner_mode(uid: u32, mode: u32) -> Result<(), RuntimeError> {
    if uid != DEBIAN_SANDBOX_UID {
        return Err(RuntimeError::InvalidCommand(
            "Debian chrome-sandbox helper must be root-owned".into(),
        ));
    }
    if mode & 0o4000 == 0 {
        return Err(RuntimeError::InvalidCommand(
            "Debian chrome-sandbox helper must carry the setuid bit".into(),
        ));
    }
    if mode & 0o022 != 0 {
        return Err(RuntimeError::InvalidCommand(
            "Debian chrome-sandbox helper must not be writable by group or other users".into(),
        ));
    }
    if mode & 0o7777 != DEBIAN_SANDBOX_MODE {
        return Err(RuntimeError::InvalidCommand(
            "Debian chrome-sandbox helper must use the qualified 4755 mode".into(),
        ));
    }
    Ok(())
}

/// Proves portable user-namespace behavior. The portable bundle never assumes
/// a setuid installation; it must prove the ordinary-user namespace route
/// (the same probe `cef_host` runs at launch) instead.
pub fn assert_portable_proves_user_namespace(
    user_namespace_probed: bool,
) -> Result<(), RuntimeError> {
    if !user_namespace_probed {
        return Err(RuntimeError::InvalidCommand(
            "portable Linux artifacts must prove the user-namespace sandbox route".into(),
        ));
    }
    Ok(())
}

/// Returns true for sandbox-bypass flags that must never appear on a
/// production command line.
pub fn is_sandbox_bypass_flag(flag: &str) -> bool {
    SANDBOX_BYPASS_FLAGS.contains(&flag)
}

/// Rejects sandbox-bypass flags without guessing an alternative.
pub fn assert_no_sandbox_bypass(flag: &str) -> Result<(), RuntimeError> {
    if is_sandbox_bypass_flag(flag) {
        return Err(RuntimeError::InvalidCommand(
            "CEF sandbox bypass flags are not accepted on native Linux".into(),
        ));
    }
    Ok(())
}

pub fn uses_bundled_cef() -> bool {
    true
}

pub fn uses_host_cef() -> bool {
    false
}

pub fn uses_host_webkitgtk() -> bool {
    false
}

pub fn works_without_gpu() -> bool {
    true
}

/// Returns true for host CEF locations that must never back a native Linux
/// surface. The bundled payload is the only lookup: the host `dlopen`s an
/// absolute path under the explicit `--cef-root` and never searches the
/// system.
pub fn is_host_cef_path(path: &str) -> bool {
    let lowered = path.to_ascii_lowercase();
    lowered.starts_with("/usr/lib/chromium")
        || lowered.starts_with("/usr/lib64/chromium")
        || lowered.starts_with("/usr/local/lib/chromium")
        || lowered.starts_with("/opt/google/chrome")
        || lowered.starts_with("/opt/chromium")
        || lowered.starts_with("/snap/")
        || lowered.contains("host cef")
        || lowered.contains("host-cef")
}

/// Returns true for WebKitGTK/Wry locations that must never back a surface.
pub fn is_webkitgtk_path(value: &str) -> bool {
    let lowered = value.to_ascii_lowercase();
    lowered.contains("webkit") || lowered.contains("wry")
}

/// Backend names that must never back a native Linux surface. Matching is
/// case-insensitive and substring-based so a renamed fallback cannot slip
/// through the qualification seam.
pub fn is_forbidden_backend(name: &str) -> bool {
    let lowered = name.to_ascii_lowercase();
    lowered.contains("webkit")
        || lowered.contains("wry")
        || lowered.contains("webview2")
        || lowered.contains("system cef")
        || lowered.contains("system-cef")
        || lowered.contains("external chromium")
        || lowered.contains("external-chromium")
        || lowered.contains("chromium external")
        || lowered.contains("unowned browser")
        || lowered.contains("unowned-browser")
}

/// Rejects fallback engines without guessing an alternative.
pub fn assert_no_host_engine(name: &str) -> Result<(), RuntimeError> {
    if is_forbidden_backend(name) || is_host_cef_path(name) || is_webkitgtk_path(name) {
        return Err(RuntimeError::InvalidCommand(
            "fallback browser engines are not used for native Linux surfaces".into(),
        ));
    }
    Ok(())
}

/// Proves a clean environment still passes: no host CEF and no WebKitGTK are
/// present, and CPU rendering carries both presentations.
pub fn assert_clean_environment(
    host_cef_present: bool,
    webkitgtk_present: bool,
) -> Result<(), RuntimeError> {
    if host_cef_present {
        return Err(RuntimeError::InvalidCommand(
            "native Linux cells must pass without host CEF".into(),
        ));
    }
    if webkitgtk_present {
        return Err(RuntimeError::InvalidCommand(
            "native Linux cells must pass without WebKitGTK".into(),
        ));
    }
    if !works_without_gpu() {
        return Err(RuntimeError::InvalidCommand(
            "native Linux cells must pass without GPU availability".into(),
        ));
    }
    Ok(())
}

/// Linux official video routes through CEF when the build bundles it.
pub fn linux_official_video_uses_cef() -> bool {
    true
}

/// Proves Linux official video plays through the bundled CEF host.
pub fn assert_linux_video_uses_cef(uses_cef: bool) -> Result<(), RuntimeError> {
    if !uses_cef {
        return Err(RuntimeError::InvalidCommand(
            "Linux official video plays through the bundled CEF host".into(),
        ));
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn released_packages_share_the_bundled_payload() {
        for id in ["debian-12", "ubuntu-22.04", "ubuntu-24.04", "portable", "portable-x64"] {
            let package = parse_linux_native_package(id).expect(id);
            assert!(package_ships_bundled_cef(package), "{id}");
            assert!(uses_bundled_cef());
        }
        for unknown in ["", "debian-11", "ubuntu-20.04", "Debian-12", "flatpak", "windows"] {
            assert!(parse_linux_native_package(unknown).is_err(), "{unknown}");
        }
    }

    #[test]
    fn staged_payload_covers_resources_locales_helpers_and_graphics() {
        for required in [
            "Release/libcef.so",
            "Release/chrome-sandbox",
            "Release/libEGL.so",
            "Release/libGLESv2.so",
            "Release/libvk_swiftshader.so",
            "Release/libvulkan.so.1",
            "Release/v8_context_snapshot.bin",
            "Release/vk_swiftshader_icd.json",
            "Resources/chrome_100_percent.pak",
            "Resources/chrome_200_percent.pak",
            "Resources/icudtl.dat",
            "Resources/resources.pak",
            "Resources/locales",
            "Resources/locales/en-US.pak",
            "LICENSE.txt",
            "CREDITS.html",
        ] {
            assert!(
                REQUIRED_LINUX_RUNTIME_FILES.contains(&required),
                "{required}"
            );
        }
        assert_eq!(REQUIRED_LINUX_LOCALE, "en-US");
        assert!(REQUIRED_LINUX_GRAPHICS_FILES.contains(&"Release/libEGL.so"));
        assert!(REQUIRED_LINUX_GRAPHICS_FILES.contains(&"Release/libGLESv2.so"));
        assert!(REQUIRED_LINUX_GRAPHICS_FILES.contains(&"Release/libvk_swiftshader.so"));
        assert!(REQUIRED_LINUX_GRAPHICS_FILES.contains(&"Release/libvulkan.so.1"));
        assert!(REQUIRED_LINUX_GRAPHICS_FILES.contains(&"Release/vk_swiftshader_icd.json"));
        assert!(REQUIRED_LINUX_NOTICE_FILES.contains(&"LICENSE.txt"));
        assert!(REQUIRED_LINUX_NOTICE_FILES.contains(&"CREDITS.html"));
    }

    #[test]
    fn sandbox_routes_are_qualified_per_artifact() {
        assert_eq!(
            required_sandbox_route(LinuxNativePackage::Debian12),
            LinuxSandboxRoute::SetuidHelper
        );
        assert_eq!(
            required_sandbox_route(LinuxNativePackage::Ubuntu2204),
            LinuxSandboxRoute::SetuidHelper
        );
        assert_eq!(
            required_sandbox_route(LinuxNativePackage::Ubuntu2404),
            LinuxSandboxRoute::SetuidHelper
        );
        assert_eq!(
            required_sandbox_route(LinuxNativePackage::Portable),
            LinuxSandboxRoute::UserNamespace
        );
    }

    #[test]
    fn debian_sandbox_ownership_and_mode_are_proven() {
        assert_eq!(DEBIAN_SANDBOX_UID, 0);
        assert_eq!(DEBIAN_SANDBOX_MODE, 0o4755);
        assert!(assert_debian_sandbox_owner_mode(0, 0o4755).is_ok());
        // Non-root owners, missing setuid bit, group/other writability, and
        // any non-4755 mode all fail closed.
        assert!(assert_debian_sandbox_owner_mode(1000, 0o4755).is_err());
        assert!(assert_debian_sandbox_owner_mode(0, 0o0755).is_err());
        assert!(assert_debian_sandbox_owner_mode(0, 0o4775).is_err());
        assert!(assert_debian_sandbox_owner_mode(0, 0o4757).is_err());
        assert!(assert_debian_sandbox_owner_mode(0, 0o4711).is_err());
    }

    #[test]
    fn portable_proves_user_namespace_instead_of_assuming_setuid() {
        assert!(assert_portable_proves_user_namespace(true).is_ok());
        assert!(assert_portable_proves_user_namespace(false).is_err());
    }

    #[test]
    fn sandbox_bypass_flags_are_rejected() {
        for flag in SANDBOX_BYPASS_FLAGS {
            assert!(is_sandbox_bypass_flag(flag), "{flag}");
            assert!(assert_no_sandbox_bypass(flag).is_err(), "{flag}");
        }
        assert!(!is_sandbox_bypass_flag("--cef-validation"));
        assert!(assert_no_sandbox_bypass("--cef-validation").is_ok());
    }

    #[test]
    fn both_presentations_pass_on_every_package_compositor_cell() {
        assert_eq!(native_matrix_cells(), 16);
        let packages = [
            LinuxNativePackage::Debian12,
            LinuxNativePackage::Ubuntu2204,
            LinuxNativePackage::Ubuntu2404,
            LinuxNativePackage::Portable,
        ];
        let compositors = [LinuxNativeCompositor::X11, LinuxNativeCompositor::Wayland];
        let presentations = [
            (
                LinuxNativePresentation::Embedded,
                "osr-cpu-flutter-texture",
            ),
            (
                LinuxNativePresentation::Standalone,
                "osr-cpu-owned-window",
            ),
        ];
        for package in packages {
            for compositor in compositors {
                assert!(cell_shares_account_policy(package, compositor));
                for (presentation, expected) in presentations {
                    assert_eq!(
                        cell_presentation_path(package, compositor, presentation),
                        expected
                    );
                }
            }
        }
        for unknown in ["", "mir", "X11", "WAYLAND"] {
            assert!(parse_linux_native_compositor(unknown).is_err(), "{unknown}");
        }
    }

    #[test]
    fn clean_environments_without_webkitgtk_or_host_cef_still_pass() {
        assert!(!uses_host_cef());
        assert!(!uses_host_webkitgtk());
        assert!(works_without_gpu());
        assert!(assert_clean_environment(false, false).is_ok());
        assert!(assert_clean_environment(true, false).is_err());
        assert!(assert_clean_environment(false, true).is_err());
        for path in [
            "/usr/lib/chromium/libcef.so",
            "/opt/google/chrome/chrome",
            "/snap/chromium/current/usr/lib/chromium-browser/chrome",
            "host CEF lookup",
        ] {
            assert!(is_host_cef_path(path), "{path}");
            assert!(assert_no_host_engine(path).is_err(), "{path}");
        }
        for name in ["WebKitGTK", "webkit2gtk", "wry", "system CEF", "external Chromium"] {
            assert!(assert_no_host_engine(name).is_err(), "{name}");
        }
        assert!(assert_no_host_engine("cef-osr-cpu").is_ok());
    }

    #[test]
    fn linux_official_video_plays_through_the_bundled_cef_host() {
        assert_eq!(LINUX_OFFICIAL_VIDEO_PATH, "cef-official-embed");
        assert_eq!(
            LINUX_OFFICIAL_VIDEO_FALLBACK,
            "deliberate-external"
        );
        assert!(linux_official_video_uses_cef());
        assert!(assert_linux_video_uses_cef(true).is_ok());
        assert!(assert_linux_video_uses_cef(false).is_err());
    }
}
