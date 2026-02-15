import 'dart:async';

class NotifyingMap<K, V> implements Map<K, V> {
  late final Map<K, V> _internalMap;

  late final StreamController<MapEntry<K, V>> _onAdd;

  late final StreamController<MapEntry<K, V>> _onRemove;
  
  // This stream is called after an item is added to the list
  Stream<MapEntry<K, V>> get onAdd => _onAdd.stream;

  // This stream is called just before an item is removed from the list, the item will still be accessible at this index until the stream is completed
  Stream<MapEntry<K, V>> get onRemove => _onRemove.stream;
  
  NotifyingMap({bool sync = false}) {
    _internalMap = Map();
    _onAdd = StreamController.broadcast(sync: sync);
    _onRemove = StreamController.broadcast(sync: sync);
  }

  @override
  V? operator [](Object? key) {
    return _internalMap[key];
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
    return _internalMap.cast<RK, RV>();
  }

  @override
  void clear() {
    Map<K,V> oldmap = this._internalMap;
    this._internalMap = Map();
    for (final entry in oldmap.entries) {
      _onRemove.add(entry);
    }
  }

  @override
  bool containsKey(Object? key) {
    return this._internalMap.containsKey(key);
  }

  @override
  bool containsValue(Object? value) {
    return this._internalMap.containsValue(value);
  }

  @override
  Iterable<MapEntry<K, V>> get entries => this._internalMap.entries;

  @override
  void forEach(void Function(K key, V value) action) {
    this._internalMap.forEach(action);
  }

  @override
  bool get isEmpty => this._internalMap.isEmpty;

  @override
  bool get isNotEmpty => this._internalMap.isNotEmpty;

  @override
  Iterable<K> get keys => this._internalMap.keys;

  @override
  int get length => this._internalMap.length;

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(K key, V value) convert) {
    return this._internalMap.map(convert);
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    return update(key, (v) => v, ifAbsent: ifAbsent);
  }

  @override
  V? remove(Object? key) {
    if (containsKey(key)) {
      V value = _internalMap.remove(key)!;
      _onRemove.add(MapEntry(key as K, value));
      return value;
    }
    return null;
  }

  @override
  void removeWhere(bool Function(K key, V value) test) {
    List<MapEntry<K,V>> removed = List.empty(growable: true);
    _internalMap.removeWhere((key, value) {if (test(key, value)) {removed.add(MapEntry(key,value)) ;return true;}; return false;});
    for (final entry in removed) {
      _onRemove.add(entry);
    }
  }

  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) {
    if (ifAbsent == null){
      return _internalMap.update(key, update);
    }
    bool absent = false;
    V? old_value = null;
    V value = _internalMap.update(key, (V value) {absent = false; old_value = value; return update(value);}, ifAbsent: ifAbsent);
    if (absent) {
      _onAdd.add(MapEntry(key, value));
    } else {
      _onRemove.add(MapEntry(key, old_value!));
      _onAdd.add(MapEntry(key, value));
    }
    return value;
  }

  @override
  void updateAll(V Function(K key, V value) update) {
    _internalMap.updateAll(update);
  }

  @override
  Iterable<V> get values => _internalMap.values;
}
