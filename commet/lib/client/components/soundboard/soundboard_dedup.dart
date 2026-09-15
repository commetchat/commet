// Bounded dedup for soundboard triggers. Pure Dart.
import 'dart:collection';

import 'soundboard_constraints.dart';

/// Remembers recent eventIds so `# one trigger -> one playback` holds even
/// if the transport redelivers. Bounded LRU: no unbounded memory growth.
class SoundboardDedup {
  final int maxEntries;
  final LinkedHashMap<String, int> _seen = LinkedHashMap();

  SoundboardDedup({this.maxEntries = SoundboardConstraints.maxDedupEntries});

  /// Returns true if this eventId was already seen (duplicate).
  /// Otherwise records it and returns false.
  bool checkAndRemember(String eventId, int nowMs) {
    if (_seen.containsKey(eventId)) return true;
    _seen[eventId] = nowMs;
    while (_seen.length > maxEntries) {
      _seen.remove(_seen.keys.first);
    }
    return false;
  }

  /// Opportunistic expiry of entries older than [ttlMs] (by insertion time).
  void expireOlderThan(int nowMs, int ttlMs) {
    final cutoff = nowMs - ttlMs - 5000;
    _seen.removeWhere((_, ts) => ts < cutoff);
  }

  int get size => _seen.length;
}
