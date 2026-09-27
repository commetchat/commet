// Turns a pasted link into queue entries on the DJ's desktop client, by
// asking the source extension that takes the link (docs/dj-extensions.md).
import 'dart:math';

import 'package:commet/client/components/dj/dj_engine.dart';
import 'package:commet/client/components/dj/dj_links.dart';
import 'package:commet/client/components/dj/dj_models.dart';
import 'package:commet/client/matrix/components/dj/native/dj_extensions.dart';

class DjExtensionResolver implements DjResolver {
  DjExtensionResolver(this.extensions) {
    extensions.load();
  }

  final DjExtensions extensions;

  static final Random _random = Random();
  static String _newId() =>
      List.generate(3, (_) => _random.nextInt(1 << 30).toRadixString(36))
          .join();

  /// Longest source an extension may give: it travels in every state, as
  /// `ext:<id>:<source>` within [DjTrack.maxUrl].
  static const maxSource = 900;

  @override
  String? sourceFor(DjLink link) => extensions.forHost(link.host)?.manifest.name;

  @override
  String? get hint {
    final installed = extensions.extensions.value;
    if (installed.length != 1) return null;
    return installed.single.manifest.hint;
  }

  @override
  Future<List<DjTrack>> resolve(DjLink link, {required String addedBy}) async {
    await extensions.load();
    final extension = extensions.forHost(link.host);
    if (extension == null) {
      throw StateError('no installed source plays links from ${link.host}');
    }
    final answer = await DjExtensions.resolve(extension, link.url);
    final tracks = tracksFrom(answer,
        extensionId: extension.id, addedBy: addedBy, newId: _newId);
    if (tracks.isEmpty) throw StateError('Nothing playable in that link');
    return tracks;
  }

  /// Queue entries from a `resolve` answer's tracks, leaving out what is
  /// not a track.
  static List<DjTrack> tracksFrom(List<Map<String, Object?>> answer,
      {required String extensionId,
      required String addedBy,
      required String Function() newId}) {
    final tracks = <DjTrack>[];
    for (final entry in answer) {
      final source = _text(entry['source'], maxSource);
      final title = _text(entry['title'], DjTrack.maxText);
      if (source == null || title == null) continue;
      final duration = entry['durationMs'];
      tracks.add(DjTrack(
        id: newId(),
        source: '${DjTrack.extensionPrefix}$extensionId:$source',
        link: _web(entry['link']),
        kind: _text(entry['label'], DjTrack.maxKind) ?? DjTrack.linkKind,
        title: title,
        artist: _text(entry['artist'], DjTrack.maxText),
        durationMs: duration is num && duration.isFinite && duration > 0
            ? duration.round()
            : null,
        thumbnail: _web(entry['thumbnail'], httpsOnly: true),
        addedBy: addedBy,
      ));
    }
    return tracks;
  }

  static String? _text(Object? value, int max) {
    if (value is! String || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    return trimmed.length > max ? trimmed.substring(0, max) : trimmed;
  }

  static String? _web(Object? value, {bool httpsOnly = false}) {
    final text = _text(value, DjTrack.maxUrl);
    final uri = text == null ? null : Uri.tryParse(text);
    if (uri == null || uri.host.isEmpty) return null;
    return uri.scheme == 'https' || (!httpsOnly && uri.scheme == 'http')
        ? text
        : null;
  }
}
