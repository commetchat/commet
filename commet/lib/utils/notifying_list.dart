import 'dart:async';
import 'dart:math';

class NotifyingList<T> implements List<T> {
  List<T> _internalList;

  late StreamController<T> _onAdd = StreamController.broadcast();

  late StreamController<T> _onRemove = StreamController.broadcast();

  late StreamController _onListUpdated = StreamController.broadcast();

  late StreamController<T> _onItemUpdated = StreamController.broadcast();

  // This stream is called after an item is added to the list
  Stream<T> get onAdd => _onAdd.stream;

  // This stream is called just before an item is removed from the list, the item will still be accessible at this index until the stream is completed
  Stream<T> get onRemove => _onRemove.stream;

  // This stream is called whenever the items in the list are changed
  Stream get onListUpdated => _onListUpdated.stream;

  Stream<T> get onItemUpdated => _onItemUpdated.stream;

  @override
  T get first => _internalList.first;

  @override
  T get last => _internalList.last;

  @override
  int get length => _internalList.length;

  void close() {
    _onAdd.close();
    _onRemove.close();
    _onListUpdated.close();
    _onItemUpdated.close();
  }

  @override
  set first(T value) {
    _internalList.first = value;
    _onItemUpdated.add(value);
  }

  @override
  set last(T value) {
    _internalList.last = value;
    _onItemUpdated.add(value);
  }

  @override
  set length(int newLength) {
    _internalList.length = newLength;
  }

  NotifyingList._internal(this._internalList, bool sync) {
    _onAdd = StreamController.broadcast(sync: sync);
    _onRemove = StreamController.broadcast(sync: sync);
    _onListUpdated = StreamController.broadcast(sync: sync);
    _onItemUpdated = StreamController.broadcast(sync: sync);

    onAdd.listen(_onAnyUpdate);
    onItemUpdated.listen(_onAnyUpdate);
    onRemove.listen(_onAnyUpdate);
  }

  void _onAnyUpdate(dynamic value) {
    _onListUpdated.add(null);
  }

  factory NotifyingList.empty({bool growable = false, bool sync = true}) {
    List<T> internalList = List.empty(growable: growable);
    return NotifyingList._internal(internalList, sync);
  }

  @override
  List<T> operator +(List<T> other) {
    return _internalList + other;
  }

  @override
  T operator [](int index) {
    return _internalList[index];
  }

  @override
  void operator []=(int index, T value) {
    _internalList[index] = value;
    _onItemUpdated.add(value);
  }

  @override
  void add(T value) {
    _internalList.add(value);
    _onAdd.add(value);
  }

  @override
  void addAll(Iterable<T> iterable) {
    for (final e in iterable) {
      add(e);
    }
  }

  @override
  bool any(bool Function(T element) test) {
    return _internalList.any(test);
  }

  @override
  Map<int, T> asMap() {
    return _internalList.asMap();
  }

  @override
  List<R> cast<R>() {
    return _internalList.cast<R>();
  }

  @override
  void clear() {
    List<T> oldList = _internalList;
    this._internalList = List.empty(growable: true);
    for (final entry in oldList) {
      _onRemove.add(entry);
    }
  }

  @override
  bool contains(Object? element) {
    return _internalList.contains(element);
  }

  @override
  T elementAt(int index) {
    return _internalList.elementAt(index);
  }

  @override
  bool every(bool Function(T element) test) {
    return _internalList.every(test);
  }

  @override
  Iterable<R> expand<R>(Iterable<R> Function(T element) toElements) {
    return _internalList.expand<R>(toElements);
  }

  @override
  void fillRange(int start, int end, [T? fillValue]) {
    _internalList.fillRange(start, end, fillValue);
  }

  @override
  T firstWhere(bool Function(T element) test, {T Function()? orElse}) {
    return _internalList.firstWhere(test, orElse: orElse);
  }

  @override
  R fold<R>(R initialValue, R Function(R previousValue, T element) combine) {
    return _internalList.fold<R>(initialValue, combine);
  }

  @override
  Iterable<T> followedBy(Iterable<T> other) {
    return _internalList.followedBy(other);
  }

  @override
  void forEach(void Function(T element) action) {
    _internalList.forEach(action);
  }

  @override
  Iterable<T> getRange(int start, int end) {
    return _internalList.getRange(start, end);
  }

  @override
  int indexOf(T element, [int start = 0]) {
    return _internalList.indexOf(element, start);
  }

  @override
  int indexWhere(bool Function(T element) test, [int start = 0]) {
    return _internalList.indexWhere(test, start);
  }

  @override
  void insert(int index, T element) {
    _internalList.insert(index, element);
    _onAdd.add(element);
  }

  @override
  void insertAll(int index, Iterable<T> iterable) {
    int oldLength = iterable.length;
    _internalList.insertAll(index, iterable);
    for (int i = 0; i < oldLength; i++) {
      _onAdd.add(_internalList[oldLength + i]);
    }
  }

  @override
  bool get isEmpty => _internalList.isEmpty;

  @override
  bool get isNotEmpty => _internalList.isNotEmpty;

  @override
  Iterator<T> get iterator => _internalList.iterator;

  @override
  String join([String separator = ""]) {
    return _internalList.join(separator);
  }

  @override
  int lastIndexOf(T element, [int? start]) {
    return _internalList.lastIndexOf(element, start);
  }

  @override
  int lastIndexWhere(bool Function(T element) test, [int? start]) {
    return _internalList.lastIndexWhere(test, start);
  }

  @override
  T lastWhere(bool Function(T element) test, {T Function()? orElse}) {
    return _internalList.lastWhere(test, orElse: orElse);
  }

  @override
  Iterable<R> map<R>(R Function(T e) toElement) {
    return _internalList.map(toElement);
  }

  @override
  T reduce(T Function(T value, T element) combine) {
    return _internalList.reduce(combine);
  }

  @override
  bool remove(Object? value) {
    if (_internalList.remove(value)) {
      _onRemove.add(value as T);
      return true;
    }

    return false;
  }

  @override
  T removeAt(int index) {
    T value = _internalList.removeAt(index);
    _onRemove.add(value);
    return value;
  }

  @override
  T removeLast() {
    T value = _internalList.removeLast();
    _onRemove.add(value);
    return value;
  }

  @override
  void removeRange(int start, int end) {
    List removed = List.empty(growable: true);
    for (int i = start; i < end; i++) {
      removed.add(i);
    }
    _internalList.removeRange(start, end);
    for (final e in removed) {
      _onRemove.add(e);
    }
  }

  @override
  void removeWhere(bool Function(T element) test) {
    List<T> removed = List.empty(growable: true);
    _internalList.removeWhere((element) {if (test(element)) {removed.add(element);return true;}; return false;});
    for (final entry in removed) {
      _onRemove.add(entry);
    }
  }

  @override
  void replaceRange(int start, int end, Iterable<T> replacements) {
    _internalList.replaceRange(start, end, replacements);

    for (int i = start; i < end; i++) {
      _onItemUpdated.add(_internalList[i]);
    }
  }

  @override
  void retainWhere(bool Function(T element) test) {
    removeWhere((element) => !test(element));
  }

  @override
  Iterable<T> get reversed => _internalList.reversed;

  @override
  void setAll(int index, Iterable<T> iterable) {
    _internalList.setAll(index, iterable);
    for (int i = 0; i < iterable.length; i++) {
      _onItemUpdated.add(_internalList[index + i]);
    }
  }

  @override
  void setRange(int start, int end, Iterable<T> iterable, [int skipCount = 0]) {
    _internalList.setRange(start, end, iterable);
    for (int i = start; i < end; i++) {
      _onItemUpdated.add(_internalList[i]);
    }
  }

  @override
  void shuffle([Random? random]) {
    return _internalList.shuffle(random);
  }

  @override
  T get single => _internalList.single;

  @override
  T singleWhere(bool Function(T element) test, {T Function()? orElse}) {
    return _internalList.singleWhere(test, orElse: orElse);
  }

  @override
  Iterable<T> skip(int count) {
    return _internalList.skip(count);
  }

  @override
  Iterable<T> skipWhile(bool Function(T value) test) {
    return _internalList.skipWhile(test);
  }

  @override
  void sort([int Function(T a, T b)? compare]) {
    return _internalList.sort(compare);
  }

  @override
  List<T> sublist(int start, [int? end]) {
    return _internalList.sublist(start, end);
  }

  @override
  Iterable<T> take(int count) {
    return _internalList.take(count);
  }

  @override
  Iterable<T> takeWhile(bool Function(T value) test) {
    return _internalList.takeWhile(test);
  }

  @override
  List<T> toList({bool growable = true}) {
    return _internalList.toList(growable: growable);
  }

  @override
  Set<T> toSet() {
    return _internalList.toSet();
  }

  @override
  Iterable<T> where(bool Function(T element) test) {
    return _internalList.where(test);
  }

  @override
  Iterable<R> whereType<R>() {
    return _internalList.whereType<R>();
  }
}
