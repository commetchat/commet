import 'dart:async';

class NotifyingSet<T> implements Set<T> {
  late final Set<T> _internalSet;

  late final StreamController<T> _onAdd;

  late final StreamController<T> _onRemove;
  
  // This stream is called after an item is added to the list
  Stream<T> get onAdd => _onAdd.stream;

  // This stream is called just before an item is removed from the list, the item will still be accessible at this index until the stream is completed
  Stream<T> get onRemove => _onRemove.stream;


  NotifyingSet({bool sync = true}) {
    _internalSet = Set();
    _onAdd = StreamController.broadcast(sync: sync);
    _onRemove = StreamController.broadcast(sync: sync);
  }

  @override
  bool add(T value) {
    if (_internalSet.add(value)){
      _onAdd.add(value);
      return true;
    };
    return false;
  }
  
  @override
  void addAll(Iterable<T> elements) {
    for (final e in elements) {
      add(e);
    };
  }
  
  @override
  bool any(bool Function(T element) test) {
    return _internalSet.any(test);
  }
  
  @override
  Set<R> cast<R>() {
    return _internalSet.cast();
  }
  
  @override
  void clear() {
    Set<T> oldset = _internalSet;
    this._internalSet = Set();
    for (final entry in oldset) {
      _onRemove.add(entry);
    }
  }
  
  @override
  bool contains(Object? value) {
    return _internalSet.contains(value);
  }
  
  @override
  bool containsAll(Iterable<Object?> other) {
    return _internalSet.containsAll(other);
  }
  
  @override
  Set<T> difference(Set<Object?> other) {
    return _internalSet.difference(other);
  }
  
  @override
  T elementAt(int index) {
    return _internalSet.elementAt(index);
  }
  
  @override
  bool every(bool Function(T element) test) {
    return _internalSet.every(test);
  }
  
  @override
  Iterable<T2> expand<T2>(Iterable<T2> Function(T element) toElements) {
    return _internalSet.expand(toElements);
  }
  
  @override
  T get first => _internalSet.first;
  
  @override
  T firstWhere(bool Function(T element) test, {T Function()? orElse}) {
    return _internalSet.firstWhere(test, orElse: orElse);
  }
  
  @override
  T2 fold<T2>(T2 initialValue, T2 Function(T2 previousValue, T element) combine) {
    return _internalSet.fold(initialValue, combine);
  }
  
  @override
  Iterable<T> followedBy(Iterable<T> other) {
    return _internalSet.followedBy(other);
  }
  
  @override
  void forEach(void Function(T element) action) {
    return _internalSet.forEach(action);
  }
  
  @override
  Set<T> intersection(Set<Object?> other) {
    return _internalSet.intersection(other);
  }
  
  @override
  bool get isEmpty => _internalSet.isEmpty;
  
  @override
  bool get isNotEmpty => _internalSet.isNotEmpty;
  
  @override
  Iterator<T> get iterator => _internalSet.iterator;
  
  @override
  String join([String separator = ""]) {
    return _internalSet.join(separator);
  }
  
  @override
  T get last => _internalSet.last;
  
  @override
  T lastWhere(bool Function(T element) test, {T Function()? orElse}) {
    return _internalSet.lastWhere(test, orElse: orElse);
  }
  
  @override
  int get length => _internalSet.length;
  
  @override
  T? lookup(Object? object) {
    return _internalSet.lookup(object);
  }
  
  @override
  Iterable<T2> map<T2>(T2 Function(T e) toElement) {
    return _internalSet.map(toElement);
  }
  
  @override
  T reduce(T Function(T value, T element) combine) {
    return _internalSet.reduce(combine);
  }
  
  @override
  bool remove(Object? value) {
    if (_internalSet.remove(value)) {
      _onRemove.add(value as T);
      return true;
    };
    return false;
  }
  
  @override
  void removeAll(Iterable<Object?> elements) {
    for (final e in elements){
      remove(e);
    }
  }
  
  @override
  void removeWhere(bool Function(T element) test) {
    List<T> removed = List.empty(growable: true);
    _internalSet.removeWhere((element) {if (test(element)) {removed.add(element);return true;}; return false;});
    for (final entry in removed) {
      _onRemove.add(entry);
    }
  }
  
  @override
  void retainAll(Iterable<Object?> elements) {
    var diff = _internalSet.difference(Set.from(elements));
    removeAll(diff);
  }
  
  @override
  void retainWhere(bool Function(T element) test) {
    removeWhere((element) => !test(element));
  }
  
  @override
  T get single => _internalSet.single;
  
  @override
  T singleWhere(bool Function(T element) test, {T Function()? orElse}) {
    return _internalSet.singleWhere(test, orElse: orElse);
  }
  
  @override
  Iterable<T> skip(int count) {
    return _internalSet.skip(count);
  }
  
  @override
  Iterable<T> skipWhile(bool Function(T value) test) {
    return _internalSet.skipWhile(test);
  }
  
  @override
  Iterable<T> take(int count) {
    return _internalSet.take(count);
  }
  
  @override
  Iterable<T> takeWhile(bool Function(T value) test) {
    return _internalSet.takeWhile(test);
  }
  
  @override
  List<T> toList({bool growable = true}) {
    return _internalSet.toList();
  }
  
  @override
  Set<T> toSet() {
    return _internalSet.toSet();
  }
  
  @override
  Set<T> union(Set<T> other) {
    return _internalSet.union(other);
  }
  
  @override
  Iterable<T> where(bool Function(T element) test) {
    return _internalSet.where(test);
  }
  
  @override
  Iterable<T2> whereType<T2>() {
    return _internalSet.whereType<T2>();
  }

}
