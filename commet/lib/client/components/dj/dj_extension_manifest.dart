// `roscord-extension.json`, the manifest of a DJ source extension (see
// docs/dj-extensions.md). Plain parsing and checking, so it has no platform
// dependency and is unit tested.
import 'dart:convert';

import 'package:commet/client/components/dj/dj_links.dart';

/// A manifest that can't be used, and why, in words for the user.
class DjExtensionManifestException implements Exception {
  final String message;

  const DjExtensionManifestException(this.message);

  @override
  String toString() => message;
}

/// One program an extension needs, as fetched on one platform.
class DjExtensionFile {
  final String url;

  /// The file to take out of a `.zip` download; null when the download is
  /// the program.
  final String? unzip;

  /// Lowercase hex, checked when given.
  final String? sha256;

  const DjExtensionFile({required this.url, this.unzip, this.sha256});
}

/// A program an extension has the booth download when it is installed.
class DjExtensionDownload {
  final String id;
  final String name;

  /// Rough size for the install prompt (`45 MB`), when the manifest says.
  final String? size;

  /// By platform: `windows-x64`, `linux-x64`, `linux-arm64`.
  final Map<String, DjExtensionFile> files;

  const DjExtensionDownload(
      {required this.id, required this.name, this.size, required this.files});
}

class DjExtensionManifest {
  static const fileName = 'roscord-extension.json';
  static const protocol = 1;

  final String id;
  final String name;
  final String version;
  final String? description;
  final String? homepage;

  /// Hosts whose links it takes; `*` for any link no other extension takes.
  final List<String> hosts;

  /// The add bar's placeholder while it is installed.
  final String? hint;
  final List<DjExtensionDownload> downloads;
  final String command;
  final List<String> args;

  const DjExtensionManifest({
    required this.id,
    required this.name,
    required this.version,
    this.description,
    this.homepage,
    required this.hosts,
    this.hint,
    required this.downloads,
    required this.command,
    required this.args,
  });

  static final RegExp _id = RegExp(r'^[a-z0-9._-]{3,64}$');
  static final RegExp _sha256 = RegExp(r'^[0-9a-f]{64}$');
  static final RegExp _placeholder = RegExp(r'\{(dir|dep:([a-z0-9._-]+))\}');

  /// Whether it takes links from [host], by name rather than as a catch-all.
  bool takesHost(String host) =>
      hosts.any((h) => h != '*' && DjLinks.hostMatches(host, h));

  bool get takesAnyLink => hosts.contains('*');

  /// The files to download on [platform], in order; null when one of the
  /// downloads has nothing for it.
  List<(DjExtensionDownload, DjExtensionFile)>? filesFor(String platform) {
    final files = <(DjExtensionDownload, DjExtensionFile)>[];
    for (final download in downloads) {
      final file = download.files[platform];
      if (file == null) return null;
      files.add((download, file));
    }
    return files;
  }

  /// `command` and `args` with `{dir}` and `{dep:<id>}` filled in.
  List<String> commandLine(
      {required String dir, required String Function(String id) dep}) {
    String fill(String value) => value.replaceAllMapped(
        _placeholder, (m) => m[2] != null ? dep(m[2]!) : dir);
    return [fill(command), ...args.map(fill)];
  }

  static DjExtensionManifest parse(String text) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      throw const DjExtensionManifestException(
          "Its ${DjExtensionManifest.fileName} isn't valid JSON");
    }
    if (json is! Map) {
      throw const DjExtensionManifestException(
          "Its ${DjExtensionManifest.fileName} isn't a JSON object");
    }
    Never bad(String what) => throw DjExtensionManifestException(
        'Its ${DjExtensionManifest.fileName} $what');

    String field(Map map, String key, {int max = 200, bool required = true}) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        final trimmed = value.trim();
        if (trimmed.length > max) bad('has a "$key" that is too long');
        return trimmed;
      }
      if (required) bad('has no "$key"');
      return '';
    }

    String? optional(Map map, String key, {int max = 200}) {
      final value = field(map, key, max: max, required: false);
      return value.isEmpty ? null : value;
    }

    List<String> strings(Object? value, String key) {
      if (value == null) return const [];
      if (value is! List || value.any((v) => v is! String)) {
        bad('has a "$key" that is not a list of strings');
      }
      return value.cast<String>();
    }

    if (json['protocol'] != protocol) {
      bad('is for another version of the booth (protocol '
          '${json['protocol']}, this one speaks $protocol)');
    }
    final id = field(json, 'id', max: 64);
    if (!_id.hasMatch(id)) {
      bad('has an "id" other than 3 to 64 of a-z, 0-9, ".", "_" and "-"');
    }

    final homepage = optional(json, 'homepage', max: 500);
    if (homepage != null && Uri.tryParse(homepage)?.scheme != 'https') {
      bad('has a "homepage" that is not an https link');
    }

    final hosts = [
      for (final h in strings(json['hosts'], 'hosts'))
        if (h.trim().isNotEmpty) h.trim().toLowerCase()
    ];

    final downloads = <DjExtensionDownload>[];
    final seen = <String>{};
    final rawDownloads = json['downloads'] ?? const [];
    if (rawDownloads is! List) bad('has a "downloads" that is not a list');
    for (final raw in rawDownloads) {
      if (raw is! Map) bad('has a download that is not an object');
      final downloadId = field(raw, 'id', max: 64);
      if (!_id.hasMatch(downloadId) || !seen.add(downloadId)) {
        bad('has a download with a bad or repeated "id"');
      }
      final rawFiles = raw['files'];
      if (rawFiles is! Map || rawFiles.isEmpty) {
        bad('has a download without "files"');
      }
      final files = <String, DjExtensionFile>{};
      for (final MapEntry(:key, :value) in rawFiles.entries) {
        if (key is! String || value is! Map) {
          bad('has a download with a bad "files" entry');
        }
        final url = field(value, 'url', max: 1000);
        if (Uri.tryParse(url)?.scheme != 'https') {
          bad('downloads from a link that is not https');
        }
        final unzip = optional(value, 'unzip', max: 200);
        if (unzip != null &&
            (unzip.contains('..') ||
                unzip.startsWith('/') ||
                unzip.startsWith('\\'))) {
          bad('takes a file from outside its download');
        }
        final sha256 = optional(value, 'sha256', max: 64)?.toLowerCase();
        if (sha256 != null && !_sha256.hasMatch(sha256)) {
          bad('has a "sha256" that is not 64 hex digits');
        }
        files[key] = DjExtensionFile(url: url, unzip: unzip, sha256: sha256);
      }
      downloads.add(DjExtensionDownload(
        id: downloadId,
        name: field(raw, 'name', max: 64),
        size: optional(raw, 'size', max: 32),
        files: files,
      ));
    }

    final run = json['run'];
    if (run is! Map) bad('says nothing about how to run it ("run")');
    final command = field(run, 'command', max: 500);
    final args = strings(run['args'], 'args');
    for (final value in [command, ...args]) {
      for (final match in _placeholder.allMatches(value)) {
        final dep = match[2];
        if (dep != null && !seen.contains(dep)) {
          bad('runs a download it does not have ("$dep")');
        }
      }
    }

    return DjExtensionManifest(
      id: id,
      name: field(json, 'name', max: 64),
      version: field(json, 'version', max: 32),
      description: optional(json, 'description', max: 300),
      homepage: homepage,
      hosts: hosts,
      hint: optional(json, 'hint', max: 80),
      downloads: downloads,
      command: command,
      args: args,
    );
  }
}
