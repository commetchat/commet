import 'package:commet/browser_runtime.dart';
import 'package:commet/client/components/video_embed/media_embed_adapter.dart';
import 'package:test/test.dart';

const List<String> _releasedPackageIds = [
  'debian-12',
  'ubuntu-22.04',
  'ubuntu-24.04',
  'portable',
  'portable-x64',
];

const List<LinuxNativePackage> _releasedPackages = [
  LinuxNativePackage.debian12,
  LinuxNativePackage.ubuntu2204,
  LinuxNativePackage.ubuntu2404,
  LinuxNativePackage.portable,
];

const List<LinuxNativeCompositor> _compositors = [
  LinuxNativeCompositor.x11,
  LinuxNativeCompositor.wayland,
];

void main() {
  group('staged resources, locales, helpers, graphics, and sandbox route', () {
    test('released packages parse exactly and ship the bundled payload', () {
      for (final id in _releasedPackageIds) {
        final package = parseLinuxNativePackage(id);
        expect(linuxPackageShipsBundledCef(package), isTrue);
      }
      expect(linuxNativeUsesBundledCef, isTrue);
      for (final unknown in [
        null,
        '',
        'debian-11',
        'ubuntu-20.04',
        'Debian-12',
        'flatpak',
        'windows',
      ]) {
        expect(
          () => parseLinuxNativePackage(unknown),
          throwsA(isA<BrowserRuntimeException>()),
          reason: '$unknown',
        );
      }
    });

    test('staged payload covers resources, locales, helpers, and graphics', () {
      for (final required in [
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
      ]) {
        expect(requiredLinuxRuntimeFiles, contains(required), reason: required);
      }
      expect(requiredLinuxLocale, 'en-US');
      for (final graphic in [
        'Release/libEGL.so',
        'Release/libGLESv2.so',
        'Release/libvk_swiftshader.so',
        'Release/libvulkan.so.1',
        'Release/vk_swiftshader_icd.json',
      ]) {
        expect(requiredLinuxGraphicsFiles, contains(graphic), reason: graphic);
      }
      expect(requiredLinuxNoticeFiles,
          containsAll(['LICENSE.txt', 'CREDITS.html']));
    });

    test('sandbox bypass flags are rejected', () {
      for (final flag in sandboxBypassFlags) {
        expect(isSandboxBypassFlag(flag), isTrue, reason: flag);
        expect(
          () => assertNoSandboxBypass(flag),
          throwsA(isA<BrowserRuntimeException>()),
          reason: flag,
        );
      }
      expect(isSandboxBypassFlag('--cef-validation'), isFalse);
      assertNoSandboxBypass('--cef-validation');
    });
  });

  group('Debian sandbox ownership/mode and portable user-namespace behavior',
      () {
    test('sandbox routes are qualified per artifact', () {
      expect(requiredSandboxRoute(LinuxNativePackage.debian12),
          LinuxSandboxRoute.setuidHelper);
      expect(requiredSandboxRoute(LinuxNativePackage.ubuntu2204),
          LinuxSandboxRoute.setuidHelper);
      expect(requiredSandboxRoute(LinuxNativePackage.ubuntu2404),
          LinuxSandboxRoute.setuidHelper);
      expect(requiredSandboxRoute(LinuxNativePackage.portable),
          LinuxSandboxRoute.userNamespace);
    });

    test('Debian sandbox ownership and mode are proven', () {
      expect(debianSandboxUid, 0);
      expect(debianSandboxMode, 0x9ed);
      assertDebianSandboxOwnerMode(uid: 0, mode: 0x9ed);
      // Non-root owners, missing setuid bit, group/other writability, and
      // any non-4755 mode all fail closed.
      for (final bad in [
        (uid: 1000, mode: 0x9ed),
        (uid: 0, mode: 0x1ed),
        (uid: 0, mode: 0x9fd),
        (uid: 0, mode: 0x9ef),
        (uid: 0, mode: 0x9c9),
      ]) {
        expect(
          () => assertDebianSandboxOwnerMode(uid: bad.uid, mode: bad.mode),
          throwsA(isA<BrowserRuntimeException>()),
          reason: 'uid=${bad.uid} mode=${bad.mode.toRadixString(8)}',
        );
      }
    });

    test('portable proves user-namespace instead of assuming setuid', () {
      assertPortableProvesUserNamespace(userNamespaceProbed: true);
      expect(
        () => assertPortableProvesUserNamespace(userNamespaceProbed: false),
        throwsA(isA<BrowserRuntimeException>()),
      );
    });
  });

  group('both Matrix presentations on every package/compositor cell', () {
    test('sixteen cells share one OSR/CPU engine and account policy', () {
      expect(linuxNativeMatrixCells, 16);
      for (final package in _releasedPackages) {
        for (final compositor in _compositors) {
          expect(linuxCellSharesAccountPolicy(package, compositor), isTrue);
          expect(
            linuxNativePresentationPath(
                package, compositor, PresentationMode.embedded),
            'osr-cpu-flutter-texture',
          );
          expect(
            linuxNativePresentationPath(
                package, compositor, PresentationMode.standalone),
            'osr-cpu-owned-window',
          );
        }
      }
    });

    test('unknown compositors fail closed without another cell', () {
      expect(parseLinuxNativeCompositor('x11'), LinuxNativeCompositor.x11);
      expect(
          parseLinuxNativeCompositor('wayland'), LinuxNativeCompositor.wayland);
      for (final unknown in [null, '', 'mir', 'X11', 'WAYLAND']) {
        expect(
          () => parseLinuxNativeCompositor(unknown),
          throwsA(isA<BrowserRuntimeException>()),
          reason: '$unknown',
        );
      }
    });
  });

  group('clean environments without WebKitGTK or host CEF still pass', () {
    test('no host engine backs a native Linux surface', () {
      expect(linuxNativeUsesHostCef, isFalse);
      expect(linuxNativeUsesHostWebKitGtk, isFalse);
      expect(linuxNativeWorksWithoutGpu, isTrue);
      assertCleanEnvironment(hostCefPresent: false, webkitGtkPresent: false);
      expect(
        () => assertCleanEnvironment(
            hostCefPresent: true, webkitGtkPresent: false),
        throwsA(isA<BrowserRuntimeException>()),
      );
      expect(
        () => assertCleanEnvironment(
            hostCefPresent: false, webkitGtkPresent: true),
        throwsA(isA<BrowserRuntimeException>()),
      );
    });

    test('host CEF, WebKitGTK, and fallback backends are rejected', () {
      for (final path in [
        '/usr/lib/chromium/libcef.so',
        '/opt/google/chrome/chrome',
        '/snap/chromium/current/usr/lib/chromium-browser/chrome',
        'host CEF lookup',
        'WebKitGTK',
        'webkit2gtk',
        'wry',
        'system CEF',
        'external Chromium',
      ]) {
        expect(
          () => assertNoHostEngine(path),
          throwsA(isA<BrowserRuntimeException>()),
          reason: path,
        );
      }
      assertNoHostEngine('cef-osr-cpu');
      assertNoHostEngine('cef');
    });
  });

  group('Linux official video plays through the bundled CEF host', () {
    test('video routes through CEF like Windows', () {
      expect(linuxOfficialVideoPath, 'cef-official-embed');
      expect(linuxOfficialVideoFallback, 'deliberate-external');
      expect(linuxOfficialVideoUsesCef, isTrue);
      expect(
        mediaEmbedUsesCef(isWeb: false, isWindows: false, isLinux: true),
        isTrue,
      );
      expect(mediaEmbedUsesCef(isWeb: true, isWindows: false, isLinux: true),
          isFalse);
      assertLinuxVideoUsesCef(usesCef: true);
      expect(
        () => assertLinuxVideoUsesCef(usesCef: false),
        throwsA(isA<BrowserRuntimeException>()),
      );
    });
  });
}
