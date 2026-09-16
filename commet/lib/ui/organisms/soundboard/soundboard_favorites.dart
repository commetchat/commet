// Favorite sounds: a local-only list of sound ids, never sent to others.
import 'package:commet/config/preferences/string_list_preference.dart';
import 'package:flutter/foundation.dart';

class SoundboardFavorites extends ChangeNotifier {
  final List<String> Function() _load;
  final Future<void> Function(List<String> ids) _save;

  SoundboardFavorites(this._load, this._save);

  factory SoundboardFavorites.preference(StringListPreference preference) =>
      SoundboardFavorites(() => preference.value, preference.set);

  factory SoundboardFavorites.inMemory([List<String>? initial]) {
    var ids = List<String>.of(initial ?? []);
    return SoundboardFavorites(() => ids, (v) async => ids = v);
  }

  /// Favorite ids, oldest first.
  List<String> get ids => _load();

  bool contains(String soundId) => ids.contains(soundId);

  Future<void> toggle(String soundId) async {
    final next = List<String>.of(ids);
    if (!next.remove(soundId)) next.add(soundId);
    await _save(next);
    notifyListeners();
  }
}
