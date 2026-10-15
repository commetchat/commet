import 'dart:async';
import 'dart:math';

import 'package:commet/debug/log.dart';
import 'package:commet/utils/notifying_list.dart';

class NotifyingListFilter<T> implements INotifyingList<T> {
  late INotifyingList<T> _baseList;

  late NotifyingList<T> _internalList;
  late bool Function(T item) whereFunction;

  late List<StreamSubscription> subs;

  NotifyingListFilter(INotifyingList<T> base,
      {required bool Function(T item) where,
      List<Stream>? onFilterParamsChanged}) {
    this._baseList = base;

    this.whereFunction = where;

    this._internalList =
        NotifyingList.from(base.where(whereFunction), growable: true);

    subs = [
      _baseList.onRemove.listen(_onBaseItemRemoved),
      _baseList.onAdd.listen(_onBaseItemAdded),
      if (onFilterParamsChanged != null)
        for (var stream in onFilterParamsChanged)
          stream.listen(onFilterChanged),
    ];
  }

  @override
  void unsubscribe() {
    for (var sub in subs) {
      sub.cancel();
    }
  }

  @override
  T get first => _internalList.first;

  @override
  T get last => _internalList.last;

  @override
  int get length => _internalList.length;

  @override
  set length(int newLength) {
    throw UnimplementedError();
  }

  @override
  List<T> operator +(List<T> other) {
    return _internalList + other.where(whereFunction).toList();
  }

  @override
  operator [](int index) {
    return _internalList[index];
  }

  @override
  void operator []=(int index, value) {
    throw Exception("Cannot write to filtered list");
  }

  @override
  void add(value) {
    throw Exception("Cannot write to filtered list");
  }

  @override
  void addAll(Iterable<T> iterable) {
    throw Exception("Cannot write to filtered list");
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
    throw Exception("Cannot write to filtered list");
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
    throw Exception("Cannot write to filtered list");
  }

  @override
  void fillRange(int start, int end, [T? fillValue]) {
    throw Exception("Cannot write to filtered list");
  }

  @override
  set first(T value) {
    throw Exception("Cannot write to filtered list");
  }

  @override
  T firstWhere(bool Function(T element) test, {T Function()? orElse}) {
    return _internalList.firstWhere(test, orElse: orElse);
  }

  @override
  R fold<R>(R initialValue, R Function(R previousValue, T element) combine) {
    throw UnimplementedError();
  }

  @override
  Iterable<T> followedBy(Iterable<T> other) {
    // TODO: implement followedBy
    throw UnimplementedError();
  }

  @override
  void forEach(void Function(T element) action) {
    return _internalList.forEach(action);
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
    throw Exception("Cannot write to filtered list");
  }

  @override
  void insertAll(int index, Iterable<T> iterable) {
    throw Exception("Cannot write to filtered list");
  }

  @override
  bool get isEmpty => _internalList.isEmpty;

  @override
  bool get isNotEmpty => _internalList.isNotEmpty;

  @override
  // TODO: implement iterator
  Iterator<T> get iterator => _internalList.iterator;

  @override
  String join([String separator = ""]) {
    return _internalList.join(separator);
  }

  @override
  set last(T value) {
    throw Exception("Cannot write to filtered list");
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
  Stream<T> get onAdd => _internalList.onAdd;

  @override
  Stream<T> get onItemUpdated => _internalList.onItemUpdated;

  @override
  Stream<dynamic> get onListUpdated => _internalList.onListUpdated;

  @override
  Stream<T> get onRemove => _internalList.onRemove;

  @override
  T reduce(T Function(T value, T element) combine) {
    throw UnimplementedError();
  }

  @override
  bool remove(Object? value) {
    throw UnimplementedError();
  }

  @override
  T removeAt(int index) {
    throw UnimplementedError();
  }

  @override
  T removeLast() {
    throw UnimplementedError();
  }

  @override
  void removeRange(int start, int end) {}

  @override
  void removeWhere(bool Function(T element) test) {}

  @override
  void replaceRange(int start, int end, Iterable<T> replacements) {}

  @override
  void retainWhere(bool Function(T element) test) {}

  @override
  Iterable<T> get reversed => _internalList.reversed;

  @override
  void setAll(int index, Iterable<T> iterable) {
    // TODO: implement setAll
  }

  @override
  void setRange(int start, int end, Iterable<T> iterable, [int skipCount = 0]) {
    // TODO: implement setRange
  }

  @override
  void shuffle([Random? random]) {
    // TODO: implement shuffle
  }

  @override
  // TODO: implement single
  T get single => throw UnimplementedError();

  @override
  T singleWhere(bool Function(T element) test, {T Function()? orElse}) {
    // TODO: implement singleWhere
    throw UnimplementedError();
  }

  @override
  Iterable<T> skip(int count) {
    // TODO: implement skip
    throw UnimplementedError();
  }

  @override
  Iterable<T> skipWhile(bool Function(T value) test) {
    // TODO: implement skipWhile
    throw UnimplementedError();
  }

  @override
  void sort([int Function(T a, T b)? compare]) {
    // TODO: implement sort
  }

  @override
  List<T> sublist(int start, [int? end]) {
    return _internalList.sublist(start, end);
  }

  @override
  Iterable<T> take(int count) {
    // TODO: implement take
    throw UnimplementedError();
  }

  @override
  Iterable<T> takeWhile(bool Function(T value) test) {
    // TODO: implement takeWhile
    throw UnimplementedError();
  }

  @override
  List<T> toList({bool growable = true}) {
    return _internalList.toList();
  }

  @override
  Set<T> toSet() {
    // TODO: implement toSet
    throw UnimplementedError();
  }

  @override
  Iterable<T> where(bool Function(T element) test) {
    return _internalList.where(test);
  }

  @override
  Iterable<T> whereType<T>() {
    // TODO: implement whereType
    throw UnimplementedError();
  }

  void _onBaseItemRemoved(T event) {
    _internalList.remove(event);
  }

  void _onBaseItemAdded(T event) {
    if (whereFunction(event)) {
      _internalList.add(event);
      Log.i("Adding item to filtered list: $event");
    }
  }

  void onFilterChanged(event) {
    var items = _internalList.toList();

    Log.i("Received filter change event!");

    for (var item in items) {
      if (whereFunction(item) == false) {
        _internalList.remove(item);
      }
    }

    for (var item in _baseList) {
      if (whereFunction(item) && _internalList.contains(item) == false) {
        _internalList.add(item);
      }
    }
  }
}
