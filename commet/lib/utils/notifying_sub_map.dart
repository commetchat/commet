import 'dart:async';
import 'dart:nativewrappers/_internal/vm/lib/ffi_allocation_patch.dart';

import 'package:commet/utils/notifying_map.dart';

class NotifyingSubMap<K, V extends V2, V2> implements NotifyingMap<K, V> {
  final NotifyingMap<K, V2> _parent;

  late final bool Function(V2? element) _condition;

  late int _length;

  NotifyingSubMap(this._parent, bool Function(V2? element)? condition) {
    _condition =
        (V2? element) => (element is V && (condition?.call(element) ?? true));
    _length = entries.length();

    onAdd.listen((e) {
      _length = _length + 1;
    });
    onRemove.listen((e) {
      _length = _length - 1;
    });
  }

  Stream<MapEntry<K, V>> get onAdd => _parent.onAdd
      .where((e) => _condition.call(e.value))
      .map((e) => e as MapEntry<K, V>);

  Stream<MapEntry<K, V>> get onRemove => _parent.onRemove
      .where((e) => _condition.call(e.value))
      .map((e) => e as MapEntry<K, V>);

  @override
  V? operator [](Object? key) {
    V2? value = _parent[key];
    if (_condition.call(value)) {
      return value as V;
    }
    return null;
  }

  @override
  void operator []=(K key, V value) {
    update(key, (v) => value, ifAbsent: () => value);
  }

  @override
  void addAll(Map<K, V> other) {
    addEntries(other.entries);
  }

  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    for (final entry in newEntries) {
      this[entry.key] = entry.value;
    }
  }

  @override
  Map<RK, RV> cast<RK, RV>() {
    return _parent.cast<RK, RV>();
  }

  @override
  void clear() {
    _parent.removeWhere((k, v) => _condition.call(v));
  }

  @override
  bool containsKey(Object? key) {
    return this._parent.containsKey(key) && _condition.call(this._parent[key]);
  }

  @override
  bool containsValue(Object? value) {
    return this._parent.containsValue(value) && _condition.call(value as V2?);
  }

  @override
  Iterable<MapEntry<K, V>> get entries => this
      ._parent
      .entries
      .where((e) => _condition.call(e.value))
      .map((e) => e as MapEntry<K, V>);

  @override
  void forEach(void Function(K key, V value) action) {
    entries.forEach((e) => action(e.key, e.value));
  }

  @override
  bool get isEmpty => _length == 0;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  Iterable<K> get keys => entries.map((e) => e.key);

  @override
  int get length => _length;

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(K key, V value) convert) {
    return Map.fromEntries(entries.map((e) => convert(e.key, e.value)));
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    return update(key, (v) => v, ifAbsent: ifAbsent);
  }

  @override
  V? remove(Object? key) {
    if (containsKey(key)) {
      V value = _parent.remove(key) as V;
      return value;
    }
    return null;
  }

  @override
  void removeWhere(bool Function(K key, V value) test) {
    _parent.removeWhere(
        (key, value) => (_condition.call(value) && test(key, value as V)));
  }

  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) {
    return _parent.update(key, (value) {
      if (_condition.call(value)) {
        return update.call(value as V);
      }
      return ifAbsent.call();
    }, ifAbsent: ifAbsent) as V;
  }

  @override
  void updateAll(V Function(K key, V value) update) {
    _parent.updateAll((k, v) {
      if (_condition.call(v)) {
        return update(k, v as V);
      }
      return v;
    });
  }

  @override
  Iterable<V> get values => entries.map((e) => e.value);
}
