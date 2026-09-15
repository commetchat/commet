// Copyright 2024 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';

class _TTLEntry<V> {
  final V value;
  final DateTime expiry;

  _TTLEntry(this.value, this.expiry);

  bool get isExpired => DateTime.timestamp().isAfter(expiry);
}

class TTLMap<K, V> {
  final int ttlMs;
  final Map<K, _TTLEntry<V>> _map = {};
  Timer? _cleanupTimer;

  Iterable<K> get keys => _map.keys;
  int get size => _map.length;

  TTLMap(this.ttlMs) {
    _startCleanupTimer();
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      Duration(milliseconds: ttlMs ~/ 2),
      (_) => _cleanup(),
    );
  }

  void _cleanup() {
    final now = DateTime.timestamp();
    _map.removeWhere((key, entry) => now.isAfter(entry.expiry));
  }

  V? get(K key) {
    final entry = _map[key];
    if (entry == null || entry.isExpired) {
      _map.remove(key);
      return null;
    }
    return entry.value;
  }

  void set(K key, V value) {
    final expiry = DateTime.timestamp().add(Duration(milliseconds: ttlMs));
    _map[key] = _TTLEntry(value, expiry);
  }

  bool has(K key) {
    final entry = _map[key];
    if (entry == null || entry.isExpired) {
      _map.remove(key);
      return false;
    }
    return true;
  }

  void delete(K key) {
    _map.remove(key);
  }

  void clear() {
    _map.clear();
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _map.clear();
  }
}
