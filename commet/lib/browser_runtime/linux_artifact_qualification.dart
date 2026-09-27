import 'browser_runtime.dart';

/// Native Linux artifact qualification contract.
///
/// Debian, released Ubuntu packages, and the portable Linux artifact run
/// bundled CEF on X11 and Wayland. Every released native package carries the
/// same staged payload (resources, locales, helpers, graphics dependencies,
/// and the qualified sandbox route) and serves both Matrix presentations —
/// embedded as a Flutter texture and standalone in a roscord-owned window —
/// through CEF windowless/off-screen rendering with CPU `OnPaint` copied into
/// client-owned memory. Clean environments without WebKitGTK or host CEF
/// still pass, and Linux official video plays the provider's own embed
/// through the bundled CEF host, like Windows; only a build without CEF hands
/// it to the external browser.
///
/// This library owns the pure qualification policy; the out-of-process
/// `cef_host` enforces the staged-payload and sandbox rules at launch while
/// the Rust `browser_linux_artifacts` module mirrors these rules for
/// host-side fixtures. Matrix protocol behavior stays in
/// `MatrixWidgetAdapter`; this module only classifies artifacts, cells, and
/// preserved paths.
enum LinuxNativePackage { debian12, ubuntu2204, ubuntu2404, portable }

/// Required native compositor cells. Unknown compositors fail closed.
enum LinuxNativeCompositor { x11, wayland }

/// Qualified sandbox route per artifact. Debian packages ship the bundled
/// `chrome-sandbox` helper with root ownership and the setuid mode; the
/// portable bundle never assumes a setuid installation and must prove the
/// ordinary-user namespace route at launch.
enum LinuxSandboxRoute { setuidHelper, userNamespace }

/// The only supported backend name for native Linux surfaces.
const String linuxNativeBackend = 'cef-osr-cpu';

/// Embedded presentation path (Flutter texture) shared by every native cell.
const String linuxNativeEmbeddedPresentationPathValue =
    'osr-cpu-flutter-texture';

/// Standalone presentation path (roscord-owned window) shared by every cell.
const String linuxNativeStandalonePresentationPathValue =
    'osr-cpu-owned-window';

/// Staged payload every native Linux artifact must carry. Mirrors the host's
/// required CEF files plus the en-US locale and notice files the lock
/// allow-lists; the host refuses to start when any entry is missing,
/// symlinked, or writable by group/other users.
const Set<String> requiredLinuxRuntimeFiles = {
  'Release/libcef.so',
  'Release/chrome-sandbox',
  'Release/libEGL.so',
  'Release/libGLESv2.so',
  'Release/libvk_swiftshader.so',
  'Release/libvulkan.so.1',
  'Release/v8_context_snapshot.bin',
  'Release/vk_swiftshader_icd.json',
  'Resources/chrome_100_percent.pak',
  'Resources/chrome_200_percent.pak',
  'Resources/icudtl.dat',
  'Resources/resources.pak',
  'Resources/locales',
  'Resources/locales/en-US.pak',
  'LICENSE.txt',
  'CREDITS.html',
};

/// Bundled graphics dependencies that keep CPU and SwiftShader rendering
/// working without host GPU libraries.
const Set<String> requiredLinuxGraphicsFiles = {
  'Release/libEGL.so',
  'Release/libGLESv2.so',
  'Release/libvk_swiftshader.so',
  'Release/libvulkan.so.1',
  'Release/vk_swiftshader_icd.json',
};

/// The locale that must always be staged; the staging tool fails closed
/// without it.
const String requiredLinuxLocale = 'en-US';

/// Upstream notice files every artifact carries.
const Set<String> requiredLinuxNoticeFiles = {'LICENSE.txt', 'CREDITS.html'};

/// Ownership the Debian `chrome-sandbox` helper must carry after packaging.
const int debianSandboxUid = 0;

/// Mode the Debian `chrome-sandbox` helper must carry after packaging:
/// setuid, owner read/write/execute, group/other read/execute, and never
/// writable by group or other users.
const int debianSandboxMode = 0x9ed; // 4755

/// Sandbox-bypass flags the host rejects at launch. Production command lines
/// never contain them.
const Set<String> sandboxBypassFlags = {
  '--no-sandbox',
  '--disable-sandbox',
  '--disable-setuid-sandbox',
  '--disable-gpu-sandbox',
  '--disable-seccomp-filter-sandbox',
  '--disable-namespace-sandbox',
};

/// Linux official video plays the provider's embed in a CEF surface.
const String linuxOfficialVideoPath = 'cef-official-embed';

/// What a build without a bundled CEF host does with official video instead.
const String linuxOfficialVideoFallback = 'deliberate-external';

/// Parses a released native package id. Matching is exact and lowercase so an
/// unknown package cannot silently qualify as a released artifact.
LinuxNativePackage parseLinuxNativePackage(String? id) {
  return switch (id) {
    'debian-12' => LinuxNativePackage.debian12,
    'ubuntu-22.04' => LinuxNativePackage.ubuntu2204,
    'ubuntu-24.04' => LinuxNativePackage.ubuntu2404,
    'portable' || 'portable-x64' => LinuxNativePackage.portable,
    _ => throw const BrowserRuntimeException(
        BrowserRuntimeErrorCode.invalidSpec,
        'unknown native Linux package; Debian 12, Ubuntu 22.04/24.04, and portable are the released set',
      ),
  };
}

/// Parses the compositor for a native cell. Matching is exact and lowercase
/// so an unknown compositor cannot silently select another cell.
LinuxNativeCompositor parseLinuxNativeCompositor(String? sessionType) {
  return switch (sessionType) {
    'x11' => LinuxNativeCompositor.x11,
    'wayland' => LinuxNativeCompositor.wayland,
    _ => throw const BrowserRuntimeException(
        BrowserRuntimeErrorCode.invalidSpec,
        'unknown native Linux compositor; X11 and Wayland are the only cells',
      ),
  };
}

/// Presentation path shared by every native package/compositor cell. Both
/// presentations pass on every released package and compositor through the
/// same OSR/CPU engine.
String linuxNativePresentationPath(
  LinuxNativePackage package,
  LinuxNativeCompositor compositor,
  PresentationMode presentation,
) {
  return switch (presentation) {
    PresentationMode.embedded => linuxNativeEmbeddedPresentationPathValue,
    PresentationMode.standalone => linuxNativeStandalonePresentationPathValue,
  };
}

/// Every released native package ships the same bundled CEF payload.
bool linuxPackageShipsBundledCef(LinuxNativePackage package) => true;

/// Embedded and standalone surfaces in one cell share account state and
/// policy through the same host request context.
bool linuxCellSharesAccountPolicy(
  LinuxNativePackage package,
  LinuxNativeCompositor compositor,
) =>
    true;

/// Number of release-gate cells: four packages times two compositors times
/// two presentations.
int get linuxNativeMatrixCells => 4 * 2 * 2;

/// Qualified sandbox route for one artifact.
LinuxSandboxRoute requiredSandboxRoute(LinuxNativePackage package) {
  return switch (package) {
    LinuxNativePackage.debian12 ||
    LinuxNativePackage.ubuntu2204 ||
    LinuxNativePackage.ubuntu2404 =>
      LinuxSandboxRoute.setuidHelper,
    LinuxNativePackage.portable => LinuxSandboxRoute.userNamespace,
  };
}

/// Proves Debian sandbox ownership and mode. The helper must be root-owned,
/// carry the setuid bit, and never be writable by group or other users — the
/// same check `cef_host` enforces at launch.
void assertDebianSandboxOwnerMode({required int uid, required int mode}) {
  if (uid != debianSandboxUid) {
    throw const BrowserRuntimeException(
      BrowserRuntimeErrorCode.invalidCommand,
      'Debian chrome-sandbox helper must be root-owned',
    );
  }
  if (mode & 0x800 == 0) {
    throw const BrowserRuntimeException(
      BrowserRuntimeErrorCode.invalidCommand,
      'Debian chrome-sandbox helper must carry the setuid bit',
    );
  }
  if (mode & 0x12 != 0) {
    throw const BrowserRuntimeException(
      BrowserRuntimeErrorCode.invalidCommand,
      'Debian chrome-sandbox helper must not be writable by group or other users',
    );
  }
  if (mode & 0xfff != debianSandboxMode) {
    throw const BrowserRuntimeException(
      BrowserRuntimeErrorCode.invalidCommand,
      'Debian chrome-sandbox helper must use the qualified 4755 mode',
    );
  }
}

/// Proves portable user-namespace behavior. The portable bundle never assumes
/// a setuid installation; it must prove the ordinary-user namespace route
/// (the same probe `cef_host` runs at launch) instead.
void assertPortableProvesUserNamespace({required bool userNamespaceProbed}) {
  if (!userNamespaceProbed) {
    throw const BrowserRuntimeException(
      BrowserRuntimeErrorCode.invalidCommand,
      'portable Linux artifacts must prove the user-namespace sandbox route',
    );
  }
}

/// Whether CEF's sandbox can start on this system, from the AppArmor
/// unprivileged user namespace restriction ([userNamespaceRestriction], the
/// sysctl's contents, or null where the kernel has none) and the mode bits of
/// the bundled `chrome-sandbox` helper.
///
/// `cef_host` runs the real probe at launch. This only recognises the common
/// case where it would fail, Ubuntu 24.04's default restriction with no
/// setuid helper installed, so callers can keep their non-CEF path instead of
/// offering a surface that cannot open.
bool linuxCefSandboxUsable({
  required String? userNamespaceRestriction,
  required int helperMode,
}) =>
    userNamespaceRestriction?.trim() != '1' || helperMode & 0x800 != 0;

/// Returns true for sandbox-bypass flags that must never appear on a
/// production command line.
bool isSandboxBypassFlag(String flag) => sandboxBypassFlags.contains(flag);

/// Rejects sandbox-bypass flags without guessing an alternative.
void assertNoSandboxBypass(String flag) {
  if (isSandboxBypassFlag(flag)) {
    throw const BrowserRuntimeException(
      BrowserRuntimeErrorCode.invalidCommand,
      'CEF sandbox bypass flags are not accepted on native Linux',
    );
  }
}

bool get linuxNativeUsesBundledCef => true;
bool get linuxNativeUsesHostCef => false;
bool get linuxNativeUsesHostWebKitGtk => false;
bool get linuxNativeWorksWithoutGpu => true;

/// Returns true for host CEF locations that must never back a native Linux
/// surface. The bundled payload is the only lookup: the host opens an
/// absolute path under the explicit `--cef-root` and never searches the
/// system.
bool isNativeHostCefPath(String path) {
  final lowered = path.toLowerCase();
  return lowered.startsWith('/usr/lib/chromium') ||
      lowered.startsWith('/usr/lib64/chromium') ||
      lowered.startsWith('/usr/local/lib/chromium') ||
      lowered.startsWith('/opt/google/chrome') ||
      lowered.startsWith('/opt/chromium') ||
      lowered.startsWith('/snap/') ||
      lowered.contains('host cef') ||
      lowered.contains('host-cef');
}

/// Returns true for WebKitGTK/Wry locations that must never back a surface.
bool isNativeWebKitGtkPath(String value) {
  final lowered = value.toLowerCase();
  return lowered.contains('webkit') || lowered.contains('wry');
}

/// Backend names that must never back a native Linux surface. Matching is
/// case-insensitive and substring-based so a renamed fallback cannot slip
/// through the qualification seam.
bool isForbiddenNativeBackend(String name) {
  final lowered = name.toLowerCase();
  return lowered.contains('webkit') ||
      lowered.contains('wry') ||
      lowered.contains('webview2') ||
      lowered.contains('system cef') ||
      lowered.contains('system-cef') ||
      lowered.contains('external chromium') ||
      lowered.contains('external-chromium') ||
      lowered.contains('chromium external') ||
      lowered.contains('unowned browser') ||
      lowered.contains('unowned-browser');
}

/// Rejects fallback engines without guessing an alternative.
void assertNoHostEngine(String name) {
  if (isForbiddenNativeBackend(name) ||
      isNativeHostCefPath(name) ||
      isNativeWebKitGtkPath(name)) {
    throw const BrowserRuntimeException(
      BrowserRuntimeErrorCode.invalidCommand,
      'fallback browser engines are not used for native Linux surfaces',
    );
  }
}

/// Proves a clean environment still passes: no host CEF and no WebKitGTK are
/// present, and CPU rendering carries both presentations.
void assertCleanEnvironment({
  required bool hostCefPresent,
  required bool webkitGtkPresent,
}) {
  if (hostCefPresent) {
    throw const BrowserRuntimeException(
      BrowserRuntimeErrorCode.invalidCommand,
      'native Linux cells must pass without host CEF',
    );
  }
  if (webkitGtkPresent) {
    throw const BrowserRuntimeException(
      BrowserRuntimeErrorCode.invalidCommand,
      'native Linux cells must pass without WebKitGTK',
    );
  }
  if (!linuxNativeWorksWithoutGpu) {
    throw const BrowserRuntimeException(
      BrowserRuntimeErrorCode.invalidCommand,
      'native Linux cells must pass without GPU availability',
    );
  }
}

/// Linux official video routes through CEF when the build bundles it.
bool get linuxOfficialVideoUsesCef => true;

/// Proves Linux official video plays through the bundled CEF host.
void assertLinuxVideoUsesCef({required bool usesCef}) {
  if (!usesCef) {
    throw const BrowserRuntimeException(
      BrowserRuntimeErrorCode.invalidCommand,
      'Linux official video plays through the bundled CEF host',
    );
  }
}
