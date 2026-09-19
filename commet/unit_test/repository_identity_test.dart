import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

const _distributionIdentity =
    'Distribution identity: changing this would break upgrades, registered '
    'deep links, shortcuts, or the installed executable name.';
const _buildArtifact =
    'Build-artifact filename: this is an internal package, target, crate, or '
    'binary name rather than display text.';
const _thirdPartyProject =
    'Real third-party project id: roscord still consumes this upstream fork.';
const _upstreamCopyright =
    'Upstream copyright attribution: this names the original copyright holder.';
final _commetToken = RegExp(
  r'[A-Za-z0-9_./:@${}()\-]*commet[A-Za-z0-9_./:@${}()\-]*',
  caseSensitive: false,
);

const _metadataPaths = <String>[
  'android/app/src/main/AndroidManifest.xml',
  'android/app/src/main/res/values/strings.xml',
  'android/app/src/debug/AndroidManifest.xml',
  'android/app/src/debug/res/values/strings.xml',
  'android/app/src/profile/AndroidManifest.xml',
  'ios/Runner/Info.plist',
  'macos/Runner/Info.plist',
  'macos/Runner/Configs/AppInfo.xcconfig',
  'macos/Runner.xcodeproj/project.pbxproj',
  'windows/runner/Runner.rc',
  'windows/CMakeLists.txt',
  'linux/my_application.cc',
  'linux/CMakeLists.txt',
  'linux/flatpak/chat.commet.commetapp.desktop',
  'linux/debian/usr/share/applications/chat.commet.commetapp.desktop',
  'linux/flatpak/chat.commet.commetapp.metainfo.xml',
  'linux/flatpak/chat.commet.commetapp.yaml',
  'linux/debian/DEBIAN/control-ubuntu-22.04',
  'linux/debian/DEBIAN/control-ubuntu-24.04',
  'web/manifest.json',
  'web/index.html',
  // The Windows MSIX display name and package identity live here.
  'pubspec.yaml',
];

/// The complete inventory of legacy identity on intentionally inspected
/// surfaces. Each allowance is counted: adding or removing an occurrence
/// requires updating this decision log rather than silently passing the test.
final _legacyIdentityAllowlist = <_Allowance>[
  _Allowance(
    path: r'android/app/src/(?:main|debug|profile)/AndroidManifest\.xml',
    token: r'chat\.commet(?:\.commetapp)?',
    count: 4,
    reason: _distributionIdentity,
  ),
  _Allowance(
    path: r'assets/l10n/intl_[^/]+\.arb',
    token: r':?https://github\.com/commetchat/encrypted_url_preview',
    count: 13,
    reason: _thirdPartyProject,
  ),
  _Allowance(
    path: r'assets/l10n/intl_[^/]+\.arb',
    token: r'Commets|Commeti|Commeten|Commet\.?',
    count: 12,
    reason: _thirdPartyProject,
  ),
  _Allowance(
    path: r'macos/Runner/Configs/AppInfo\.xcconfig',
    token: r'chat\.commet\.commetapp',
    count: 1,
    reason: _distributionIdentity,
  ),
  _Allowance(
    path: r'macos/Runner/Configs/AppInfo\.xcconfig',
    token: r'commet\.chat\.',
    count: 1,
    reason: _upstreamCopyright,
  ),
  _Allowance(
    path: r'macos/Runner\.xcodeproj/project\.pbxproj',
    token: r'chat\.commet\.commetapp(?:\.macos)?',
    count: 3,
    reason: _distributionIdentity,
  ),
  _Allowance(
    path: r'windows/runner/Runner\.rc',
    token: r'commet\.chat\.',
    count: 1,
    reason: _upstreamCopyright,
  ),
  _Allowance(
    path: r'windows/runner/Runner\.rc',
    token: r'COMMET:|commet\.exe',
    count: 3,
    reason: _buildArtifact,
  ),
  _Allowance(
    path: r'windows/CMakeLists\.txt',
    token: r'project\(commet|commet',
    count: 2,
    reason: _buildArtifact,
  ),
  _Allowance(
    path: r'linux/CMakeLists\.txt',
    token: r'\(\$ENV\{COMMET_PROD\}|chat\.commet\.commetapp(?:\.develop)?',
    count: 3,
    reason: _distributionIdentity,
  ),
  _Allowance(
    path: r'linux/CMakeLists\.txt',
    token: r'commet',
    count: 1,
    reason: _buildArtifact,
  ),
  _Allowance(
    path:
        r'linux/(?:flatpak|debian/usr/share/applications)/chat\.commet\.commetapp\.desktop',
    token: r'.*commet.*',
    count: 9,
    reason: _distributionIdentity,
  ),
  _Allowance(
    path: r'linux/flatpak/chat\.commet\.commetapp\.metainfo\.xml',
    token: r'chat\.commet\.commetapp(?:\.desktop)?',
    count: 2,
    reason: _distributionIdentity,
  ),
  _Allowance(
    path: r'linux/flatpak/chat\.commet\.commetapp\.yaml',
    token: r'.*commet.*',
    count: 18,
    reason: _distributionIdentity,
  ),
  _Allowance(
    path: r'linux/debian/DEBIAN/control-ubuntu-(?:22|24)\.04',
    token: r'commet',
    count: 2,
    reason: _distributionIdentity,
  ),
  _Allowance(
    path: r'pubspec\.yaml',
    token: r'chat\.commet\.app\.windows-a33bc9ba',
    count: 1,
    reason: _distributionIdentity,
  ),
  _Allowance(
    path: r'pubspec\.yaml',
    token: r'commet|commet_calendar_widget:|rust_lib_commet:',
    count: 3,
    reason: _buildArtifact,
  ),
  _Allowance(
    path: r'pubspec\.yaml',
    token: r'https://github\.com/commetchat/[^\s]+',
    count: 9,
    reason: _thirdPartyProject,
  ),
];

void main() {
  test('legacy Commet identity is completely enumerated', () {
    final findings = _scanRepository(Directory.current);
    final unmatched = _unmatchedFindings(findings);

    expect(
      unmatched,
      isEmpty,
      reason: 'Every legacy identity must be removed or added to the reasoned '
          'allowlist in repository_identity_test.dart.',
    );

    for (final allowance in _legacyIdentityAllowlist) {
      expect(allowance.reason.trim(), isNotEmpty);
      expect(
        findings.where(allowance.matches).length,
        allowance.count,
        reason: 'The legacy-identity decision changed for $allowance. Remove '
            'or update its explicit allowance with the production change.',
      );
    }
  });

  test('macOS product identity comes from AppInfo.xcconfig', () {
    final appInfo = File(
      'macos/Runner/Configs/AppInfo.xcconfig',
    ).readAsStringSync();
    final project = File(
      'macos/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final infoPlist = File('macos/Runner/Info.plist').readAsStringSync();

    expect(
      RegExp(r'^PRODUCT_NAME = roscord$', multiLine: true).allMatches(appInfo),
      hasLength(1),
    );
    expect(project, contains('path = roscord.app;'));
    expect(project, isNot(contains('INFOPLIST_KEY_CFBundleDisplayName')));
    expect(
      RegExp(r'^\s*PRODUCT_NAME = roscord;$', multiLine: true)
          .hasMatch(project),
      isFalse,
      reason: 'Runner target settings must not override AppInfo.xcconfig.',
    );
    expect(
      RegExp(
        r'<key>CFBundleName</key>\r?\n\s*<string>\$\(PRODUCT_NAME\)</string>',
      ).hasMatch(infoPlist),
      isTrue,
    );
  });

  test('web install and window identity is roscord', () {
    final manifest = jsonDecode(File('web/manifest.json').readAsStringSync())
        as Map<String, dynamic>;
    final index = File('web/index.html').readAsStringSync();

    expect(manifest['name'], 'roscord');
    expect(manifest['short_name'], 'roscord');
    expect(
      index,
      contains('name="apple-mobile-web-app-title" content="roscord"'),
    );
    expect(index, contains('<title>roscord</title>'));
  });

  test('a temporary user-visible violation is detected', () {
    final fixture = Directory.systemTemp.createTempSync('roscord-identity-');
    addTearDown(() => fixture.deleteSync(recursive: true));

    final page = File('${fixture.path}/web/index.html')
      ..createSync(recursive: true)
      ..writeAsStringSync('<title>Commet</title>');

    final findings = _scanFiles(fixture, ['web/index.html']);
    expect(findings, hasLength(1));
    expect(_unmatchedFindings(findings), equals(findings));
    expect(page.existsSync(), isTrue);
  });

  test('Dart is the sole owner of the Linux window title', () {
    final nativeRunner = File('linux/my_application.cc').readAsStringSync();
    final windowManagement = File(
      'lib/utils/window_management.dart',
    ).readAsStringSync();

    expect(nativeRunner, isNot(contains('gtk_window_set_title')));
    expect(
      RegExp(r'windowManager\.setTitle\(').allMatches(windowManagement),
      hasLength(1),
    );
    expect(windowManagement, contains('await _updateTitle();'));
    expect(windowManagement, contains('"roscord",'));
  });

  test(
    'Linux launchers show roscord and match the runtime application class',
    () {
      final cmake = File('linux/CMakeLists.txt').readAsStringSync();
      final nativeRunner = File('linux/my_application.cc').readAsStringSync();
      final flatpak = File(
        'linux/flatpak/chat.commet.commetapp.desktop',
      ).readAsStringSync();
      final debian = File(
        'linux/debian/usr/share/applications/chat.commet.commetapp.desktop',
      ).readAsStringSync();
      final flatpakLines = flatpak.split(RegExp(r'\r?\n'));
      final debianLines = debian.split(RegExp(r'\r?\n'));

      expect(cmake, contains('set(APPLICATION_ID "chat.commet.commetapp")'));
      expect(nativeRunner, contains('g_set_prgname(APPLICATION_ID)'));
      expect(nativeRunner, contains('"application-id", APPLICATION_ID'));

      expect(flatpakLines, contains('Name=roscord'));
      expect(flatpakLines, contains('Icon=chat.commet.commetapp'));
      expect(flatpakLines, contains('Exec=commet'));
      expect(flatpakLines, contains('StartupWMClass=chat.commet.commetapp'));

      expect(debianLines, contains('Name=roscord'));
      expect(debianLines, contains('Icon=commet-desktop'));
      expect(
        debianLines,
        contains('Exec=/usr/lib/chat.commet.commetapp/commet %U'),
      );
      expect(debianLines, contains('StartupWMClass=chat.commet.commetapp'));
    },
  );

  test('ticket 2 display metadata names roscord', () {
    expect(
      File('android/app/src/debug/res/values/strings.xml').readAsStringSync(),
      contains('<string name="app_name">roscord</string>'),
    );

    final metainfo = File(
      'linux/flatpak/chat.commet.commetapp.metainfo.xml',
    ).readAsStringSync();
    expect(metainfo, contains('<name>roscord</name>'));
    expect(metainfo, contains('<p>roscord is a client for Matrix'));

    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      RegExp(
        r'^\s+display_name: roscord$',
        multiLine: true,
      ).allMatches(pubspec),
      hasLength(2),
    );
  });
}

List<_Finding> _scanRepository(Directory root) {
  final findings = _scanFiles(root, _metadataPaths, requireFiles: true);

  final l10n = Directory('${root.path}/assets/l10n');
  expect(l10n.existsSync(), isTrue, reason: 'The localization corpus moved.');
  final arbPaths = l10n
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.arb'))
      .map((file) => _relativePath(root, file));
  findings.addAll(_scanFiles(root, arbPaths));

  // This is the only Commet awards host that the running app can contact.
  // Scan source rather than one hard-coded file so moving it cannot evade the
  // guard. Other commet.chat hosts are separate, documented infrastructure.
  final lib = Directory('${root.path}/lib');
  for (final file in lib.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    final content = file.readAsStringSync();
    if (!content.contains('stripe-rewards.commet.chat')) continue;
    findings.add(
      _Finding(_relativePath(root, file), 'stripe-rewards.commet.chat'),
    );
  }

  return findings;
}

List<_Finding> _scanFiles(
  Directory root,
  Iterable<String> paths, {
  bool requireFiles = false,
}) {
  final findings = <_Finding>[];
  for (final path in paths) {
    final file = File('${root.path}/$path');
    if (requireFiles) {
      expect(
        file.existsSync(),
        isTrue,
        reason: 'Identity surface moved: $path',
      );
    }
    if (!file.existsSync()) continue;

    for (final match in _commetToken.allMatches(file.readAsStringSync())) {
      findings.add(_Finding(path, match.group(0)!));
    }
  }
  return findings;
}

List<_Finding> _unmatchedFindings(List<_Finding> findings) => findings
    .where(
      (finding) => !_legacyIdentityAllowlist.any(
        (allowance) => allowance.matches(finding),
      ),
    )
    .toList();

String _relativePath(Directory root, File file) => file.path
    .substring(root.path.length + 1)
    .replaceAll(Platform.pathSeparator, '/');

class _Finding {
  const _Finding(this.path, this.token);

  final String path;
  final String token;

  @override
  bool operator ==(Object other) =>
      other is _Finding && path == other.path && token == other.token;

  @override
  int get hashCode => Object.hash(path, token);

  @override
  String toString() => '$path: $token';
}

class _Allowance {
  _Allowance({
    required String path,
    required String token,
    required this.count,
    required this.reason,
  })  : _path = RegExp('^(?:$path)\$'),
        _token = RegExp('^(?:$token)\$');

  final RegExp _path;
  final RegExp _token;
  final int count;
  final String reason;

  bool matches(_Finding finding) =>
      _path.hasMatch(finding.path) && _token.hasMatch(finding.token);

  @override
  String toString() => '${_path.pattern} / ${_token.pattern}: $reason';
}
