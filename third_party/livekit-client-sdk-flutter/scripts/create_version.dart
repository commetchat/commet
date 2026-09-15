#!/usr/bin/env dart
/*
 * Copyright 2025 LiveKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:io';

/// Change file format:
/// Each line in a change file should follow the format:
/// `level type="kind" "description"`
///
/// Where:
/// - level: One of [patch, minor, major] indicating the version bump level
/// - kind: One of [added, changed, fixed, refactor, performance, security, deprecated, removed, docs, chore]
/// - description: A detailed description of the change
///
/// Examples:
/// ```
/// patch type="fixed" "Fix audio frame generation when publishing"
/// minor type="added" "Add support for custom audio processing"
/// major type="changed" "Breaking: Rename Room.connect() to Room.join()"
/// ```
///
/// The script will:
/// 1. Parse all change files in the .changes directory
/// 2. Determine the highest level change (major > minor > patch)
/// 3. Bump the version accordingly
/// 4. Generate a changelog entry
/// 5. Update version numbers in all relevant files
/// 6. Clean up the change files

class _Path {
  static const changes = '.changes';
  static const version = '.version';
  static const changelog = 'CHANGELOG.md';
  static const pubspec = 'pubspec.yaml';
  static const readme = 'README.md';
  static const livekitVersion = 'lib/src/livekit.dart';
  static const iosPodspec = 'ios/livekit_client.podspec';
  static const macosPodspec = 'macos/livekit_client.podspec';
}

// ANSI color codes
class _Color {
  static const reset = '\x1B[0m';
  static const green = '\x1B[32m';
  static const bold = '\x1B[1m';
}

enum ChangeKind {
  added,
  changed,
  fixed,
  refactor,
  performance,
  security,
  deprecated,
  removed,
  docs;

  static ChangeKind? fromString(String value) {
    return ChangeKind.values.where((e) => e.name == value).firstOrNull;
  }
}

enum ChangeLevel implements Comparable<ChangeLevel> {
  patch(0),
  minor(1),
  major(2);

  final int priority;
  const ChangeLevel(this.priority);

  static ChangeLevel? fromString(String value) {
    return ChangeLevel.values.where((e) => e.name == value).firstOrNull;
  }

  @override
  int compareTo(ChangeLevel other) => priority.compareTo(other.priority);
}

class Change {
  final ChangeLevel level;
  final ChangeKind kind;
  final String description;

  Change({
    required this.level,
    required this.kind,
    required this.description,
  });
}

class SemanticVersion {
  final int major;
  final int minor;
  final int patch;

  SemanticVersion({
    required this.major,
    required this.minor,
    required this.patch,
  });

  factory SemanticVersion.parse(String versionString) {
    final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)(?:[+-].*)?$').firstMatch(versionString);
    if (match == null) {
      throw FormatException('Invalid version format: $versionString');
    }

    return SemanticVersion(
      major: int.parse(match.group(1)!),
      minor: int.parse(match.group(2)!),
      patch: int.parse(match.group(3)!),
    );
  }

  SemanticVersion bumpMajor() => SemanticVersion(major: major + 1, minor: 0, patch: 0);

  SemanticVersion bumpMinor() => SemanticVersion(major: major, minor: minor + 1, patch: 0);

  SemanticVersion bumpPatch() => SemanticVersion(major: major, minor: minor, patch: patch + 1);

  @override
  String toString() => '$major.$minor.$patch';
}

SemanticVersion getCurrentVersion() {
  try {
    final content = File(_Path.version).readAsStringSync();
    final versionString = content.trim();
    return SemanticVersion.parse(versionString);
  } catch (e) {
    throw Exception('Failed to read ${_Path.version}: $e');
  }
}

List<Change> parseChanges() {
  final changesDir = Directory(_Path.changes);
  if (!changesDir.existsSync()) {
    throw Exception('Changes directory not found: ${_Path.changes}');
  }

  final changes = <Change>[];
  final files = changesDir.listSync().whereType<File>().where((f) => !f.path.split('/').last.startsWith('.'));

  for (final file in files) {
    final content = file.readAsStringSync();
    final lines = content.split('\n');

    for (final line in lines) {
      // Skip empty lines
      if (line.trim().isEmpty) continue;

      // Parse format: level type="kind" "description"
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 3) continue;

      // Extract level
      final level = ChangeLevel.fromString(parts[0]);
      if (level == null) continue;

      // Extract type from type="kind" format
      final typeMatch = RegExp(r'type="(\w+)"').firstMatch(parts[1]);
      if (typeMatch == null) continue;
      final kind = ChangeKind.fromString(typeMatch.group(1)!);
      if (kind == null) continue;

      // Extract description from the last quoted string
      final descMatch = RegExp(r'"([^"]+)"$').firstMatch(line);
      if (descMatch == null) continue;
      final description = descMatch.group(1)!;

      changes.add(Change(level: level, kind: kind, description: description));
    }
  }

  if (changes.isEmpty) {
    throw Exception('No changes found in ${_Path.changes}');
  }

  return changes;
}

SemanticVersion calculateNewVersion(SemanticVersion currentVersion, List<Change> changes) {
  final highestLevel = changes.map((c) => c.level).reduce((a, b) => a.compareTo(b) > 0 ? a : b);

  return switch (highestLevel) {
    ChangeLevel.major => currentVersion.bumpMajor(),
    ChangeLevel.minor => currentVersion.bumpMinor(),
    ChangeLevel.patch => currentVersion.bumpPatch(),
  };
}

String generateChangelogEntry(SemanticVersion version, List<Change> changes) {
  final buffer = StringBuffer();
  buffer.writeln('## $version');
  buffer.writeln();

  String prefixFor(ChangeKind kind) => switch (kind) {
        ChangeKind.added => 'Added',
        ChangeKind.changed => 'Changed',
        ChangeKind.fixed => 'Fixed',
        ChangeKind.refactor => 'Refactor',
        ChangeKind.performance => 'Performance',
        ChangeKind.security => 'Security',
        ChangeKind.deprecated => 'Deprecated',
        ChangeKind.removed => 'Removed',
        ChangeKind.docs => 'Docs',
      };

  for (final kind in ChangeKind.values) {
    for (final change in changes.where((c) => c.kind == kind)) {
      buffer.writeln('* ${prefixFor(change.kind)}: ${change.description}');
    }
  }

  buffer.writeln();

  return buffer.toString();
}

void appendToChangelog(String entry) {
  final file = File(_Path.changelog);
  final content = file.readAsStringSync();

  // Find the position after the header
  final headerMatch = RegExp(r'^# CHANGELOG\s*\n\s*\n', multiLine: true).firstMatch(content);
  if (headerMatch == null) {
    throw Exception('Could not find CHANGELOG header');
  }

  // Create new content with the entry inserted after the header
  final newContent = content.substring(0, headerMatch.end) + entry + content.substring(headerMatch.end);

  file.writeAsStringSync(newContent);
}

void replaceVersionInFile(String filePath, Pattern pattern, String replacement) {
  final file = File(filePath);
  final content = file.readAsStringSync();
  final newContent = content.replaceAll(pattern, replacement);
  file.writeAsStringSync(newContent);
}

void updateVersionFiles(SemanticVersion version) {
  // Update .version
  File(_Path.version).writeAsStringSync('$version\n');

  // Update pubspec.yaml
  replaceVersionInFile(
    _Path.pubspec,
    RegExp(r'^version:\s+[\d.]+', multiLine: true),
    'version: $version',
  );

  // Update lib/src/livekit.dart
  replaceVersionInFile(
    _Path.livekitVersion,
    RegExp(r"static const version = '[^']*'"),
    "static const version = '$version'",
  );

  // Update iOS podspec
  replaceVersionInFile(
    _Path.iosPodspec,
    RegExp(r"s\.version\s*=\s*'[^']*'"),
    "s.version             = '$version'",
  );

  // Update macOS podspec
  replaceVersionInFile(
    _Path.macosPodspec,
    RegExp(r"s\.version\s*=\s*'[^']*'"),
    "s.version             = '$version'",
  );

  // Update README.md installation snippet
  replaceVersionInFile(
    _Path.readme,
    RegExp(r'^\s*livekit_client:\s+.*$', multiLine: true),
    '  livekit_client: ^$version',
  );
}

void cleanupChangesDirectory() {
  final changesDir = Directory(_Path.changes);
  if (!changesDir.existsSync()) return;

  final files = changesDir.listSync().whereType<File>().where((f) => !f.path.split('/').last.startsWith('.'));

  for (final file in files) {
    file.deleteSync();
  }
}

void main() {
  try {
    final currentVersion = getCurrentVersion();
    final changes = parseChanges();
    final newVersion = calculateNewVersion(currentVersion, changes);

    print('Current version: $currentVersion');
    print('Changes detected:');
    for (final change in changes) {
      print('- [${change.kind.name}] ${change.description}');
    }

    print('New version: ${_Color.bold}${_Color.green}$newVersion${_Color.reset} 🎉');

    final changelogEntry = generateChangelogEntry(newVersion, changes);
    appendToChangelog(changelogEntry);
    print('Changelog entry added 📝');

    updateVersionFiles(newVersion);
    print('Version files updated 📦');

    cleanupChangesDirectory();
    print('Changes directory cleaned up 🧹');
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
