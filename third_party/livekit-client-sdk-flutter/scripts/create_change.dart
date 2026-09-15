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

/// Creates a new change entry in the .changes directory.
///
/// Usage:
///   dart scripts/create_change.dart
///   dart scripts/create_change.dart --level patch --type fixed --name my-fix --description "Fix something"
///
/// Interactive mode (no args) will prompt for each field with arrow-key selection.
/// CLI mode allows passing all fields as arguments.
///
/// Change file format:
///   level type="kind" "description"
///
/// Examples:
///   patch type="fixed" "Fix audio frame generation when publishing"
///   minor type="added" "Add support for custom audio processing"
///   major type="changed" "Breaking: Rename Room.connect() to Room.join()"

// ANSI escape codes
const _esc = '\x1B[';
const _reset = '\x1B[0m';
const _bold = '\x1B[1m';
const _dim = '\x1B[2m';
const _green = '\x1B[32m';
const _cyan = '\x1B[36m';
const _hideCursor = '\x1B[?25l';
const _showCursor = '\x1B[?25h';

const levels = ['patch', 'minor', 'major'];
const levelDescriptions = {
  'patch': 'Bug fixes, no API changes',
  'minor': 'New features, backwards compatible',
  'major': 'Breaking changes',
};

const types = [
  'added',
  'changed',
  'fixed',
  'refactor',
  'performance',
  'security',
  'deprecated',
  'removed',
  'docs',
];

/// Read a single raw keypress (handles arrow keys as 3-byte escape sequences).
List<int> readKey() {
  stdin.echoMode = false;
  stdin.lineMode = false;
  try {
    final first = stdin.readByteSync();
    if (first == 27) {
      // Escape sequence
      final second = stdin.readByteSync();
      if (second == 91) {
        final third = stdin.readByteSync();
        return [27, 91, third];
      }
      return [27, second];
    }
    return [first];
  } finally {
    stdin.lineMode = true;
    stdin.echoMode = true;
  }
}

/// Interactive picker with arrow keys. Returns selected index.
String pick(String label, List<String> options, {Map<String, String>? descriptions}) {
  var selected = 0;

  void render() {
    stdout.write(_hideCursor);
    for (var i = 0; i < options.length; i++) {
      stdout.write('${_esc}2K'); // Clear entire line
      if (i == selected) {
        final desc = descriptions?[options[i]];
        final suffix = desc != null ? ' $_dim- $desc$_reset' : '';
        stdout.writeln('  $_cyan>$_reset $_bold${options[i]}$_reset$suffix');
      } else {
        stdout.writeln('   ${options[i]}');
      }
    }
  }

  stdout.writeln('$_bold$_green?$_reset $_bold$label$_reset ${_dim}(arrow keys, enter to confirm)$_reset');
  render();

  while (true) {
    final key = readKey();

    if (key.length == 3 && key[0] == 27 && key[1] == 91) {
      if (key[2] == 65) {
        // Up arrow
        selected = (selected - 1) % options.length;
        if (selected < 0) selected = options.length - 1;
      } else if (key[2] == 66) {
        // Down arrow
        selected = (selected + 1) % options.length;
      }
    } else if (key.length == 1 && (key[0] == 10 || key[0] == 13)) {
      // Enter
      stdout.write(_showCursor);
      // Clear the list and show selection
      stdout.write('${_esc}${options.length}A'); // Move up
      stdout.write('${_esc}0J'); // Clear from cursor down
      stdout.writeln('  $_green>${_reset} $_bold${options[selected]}$_reset');
      return options[selected];
    } else if (key.length == 1 && (key[0] == 3 || key[0] == 27)) {
      // Ctrl+C or Escape
      stdout.write(_showCursor);
      exit(0);
    }

    // Redraw
    stdout.write('${_esc}${options.length}A'); // Move up to start of list
    render();
  }
}

/// Interactive text input with prompt.
String input(String label) {
  stdout.write('$_bold$_green?$_reset $_bold$label$_reset ');
  final value = stdin.readLineSync()?.trim() ?? '';
  if (value.isEmpty) {
    stderr.writeln('Input required.');
    exit(1);
  }
  return value;
}

String slugify(String text) {
  return text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
}

void main(List<String> args) {
  final changesDir = Directory('.changes');
  if (!changesDir.existsSync()) {
    changesDir.createSync();
  }

  String? level;
  String? type;
  String? name;
  String? description;

  // Parse CLI args
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--level':
      case '-l':
        level = args[++i];
      case '--type':
      case '-t':
        type = args[++i];
      case '--name':
      case '-n':
        name = args[++i];
      case '--description':
      case '-d':
        description = args[++i];
      case '--help':
      case '-h':
        stdout.writeln('Usage: dart scripts/create_change.dart [options]');
        stdout.writeln();
        stdout.writeln('Options:');
        stdout.writeln('  -l, --level        Version bump level (${levels.join(', ')})');
        stdout.writeln('  -t, --type         Change type (${types.join(', ')})');
        stdout.writeln('  -n, --name         File name slug (e.g. fix-svc-dynacast)');
        stdout.writeln('  -d, --description  Change description');
        stdout.writeln('  -h, --help         Show this help');
        exit(0);
    }
  }

  // Interactive prompts for missing fields
  level ??= pick('Level:', levels, descriptions: levelDescriptions);
  type ??= pick('Type:', types);
  name ??= slugify(input('Name (slug):'));
  description ??= input('Description:');

  // Validate
  if (!levels.contains(level)) {
    stderr.writeln('Invalid level: $level');
    exit(1);
  }
  if (!types.contains(type)) {
    stderr.writeln('Invalid type: $type');
    exit(1);
  }

  final content = '$level type="$type" "$description"\n';
  final file = File('.changes/$name');

  if (file.existsSync()) {
    stderr.writeln('Change file already exists: .changes/$name');
    exit(1);
  }

  file.writeAsStringSync(content);
  stdout.writeln();
  stdout.writeln('$_green\u2713$_reset Created $_bold.changes/$name$_reset');
  stdout.writeln('  ${_dim}${content.trim()}$_reset');
}
