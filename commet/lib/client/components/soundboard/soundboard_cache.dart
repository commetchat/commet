// Bounded session LRU for preloaded sounds. Pure Dart.
import 'dart:collection';

/// Tracks which soundIds are preloaded/decoded in this session so the call
/// view can preload on join without unbounded RAM. Eviction is advisory —
/// callers unload the evicted id (close AudioBuffer/file handle).
class SoundboardSessionCache {
  final int maxEntries;
  final LinkedHashMap<String, int> _order = LinkedHashMap();
  final void Function(String evicted)? onEvict;

  SoundboardSessionCache(
      {this.maxEntries = 20, this.onEvict});

  void markLoaded(String soundId, int nowMs) {
    _order.remove(soundId);
    _order[soundId] = nowMs;
    while (_order.length > maxEntries) {
      final evicted = _order.keys.first;
      _order.remove(evicted);
      onEvict?.call(evicted);
    }
  }

  void markUnloaded(String soundId) => _order.remove(soundId);

  bool isLoaded(String soundId) => _order.containsKey(soundId);

  List<String> get loaded => List.unmodifiable(_order.keys);

  void clear() => _order.clear();
}
