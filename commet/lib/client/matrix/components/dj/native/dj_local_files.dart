// Audio files the DJ queued from their own disk. The queue travels to
// everyone in the call, so a file is queued as `file:<id>` and its path stays
// here, in <app support>/dj-local-files.json; only its name (the title) is
// seen by the room.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:commet/client/components/dj/dj_models.dart';
import 'package:commet/debug/log.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DjLocalFiles {
  DjLocalFiles._();
  static final DjLocalFiles instance = DjLocalFiles._();

  /// Most files remembered, oldest forgotten first.
  static const maxRemembered = 5000;

  Map<String, String>? _paths;
  Future<void> _saving = Future.value();

  Future<File> get _file async => File(p.join(
      (await getApplicationSupportDirectory()).path, 'dj-local-files.json'));

  Future<Map<String, String>> _load() async {
    if (_paths != null) return _paths!;
    final paths = <String, String>{};
    try {
      final file = await _file;
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString());
        if (json is Map) {
          for (final MapEntry(:key, :value) in json.entries) {
            if (key is String && value is String) paths[key] = value;
          }
        }
      }
    } catch (e, s) {
      Log.onError(e, s, content: 'DJ booth: could not read the local files');
    }
    return _paths ??= paths;
  }

  /// The same file gets the same id, so queuing it twice fetches nothing
  /// new.
  static String idOf(String path) =>
      sha1.convert(utf8.encode(p.normalize(path))).toString().substring(0, 20);

  /// A queue entry for the file at [path].
  Future<DjTrack> track(String path,
      {required String id, required String addedBy}) async {
    final absolute = p.normalize(p.absolute(path));
    final fileId = idOf(absolute);
    final paths = await _load();
    paths.remove(fileId);
    paths[fileId] = absolute;
    while (paths.length > maxRemembered) {
      paths.remove(paths.keys.first);
    }
    _save(paths);
    final title = p.basenameWithoutExtension(absolute).trim();
    return DjTrack(
      id: id,
      source: '${DjTrack.filePrefix}$fileId',
      kind: DjTrack.fileKind,
      title: title.isEmpty
          ? p.basename(absolute)
          : (title.length > DjTrack.maxText
              ? title.substring(0, DjTrack.maxText)
              : title),
      addedBy: addedBy,
    );
  }

  /// Where the file queued as `file:<id>` is, when this computer has it.
  Future<String?> pathOf(String source) async {
    if (!source.startsWith(DjTrack.filePrefix)) return null;
    return (await _load())[source.substring(DjTrack.filePrefix.length)];
  }

  void _save(Map<String, String> paths) {
    final copy = Map.of(paths);
    _saving = _saving.then((_) async {
      try {
        await (await _file).writeAsString(jsonEncode(copy));
      } catch (e, s) {
        Log.onError(e, s, content: 'DJ booth: could not save the local files');
      }
    });
  }
}
