import 'dart:async';
import 'dart:math';

import 'package:commet/debug/log.dart';
import 'package:commet/utils/notifying_list.dart';

class NotifyingListMapped<T, R> implements INotifyingList<T> {
  late NotifyingList<R> _baseList;

  late NotifyingList<T> _internalList = NotifyingList.empty(growable: true);

  late List<T> Function(R value) mapFunction;

  late List<StreamSubscription> subs;

  NotifyingListMapped(
      {required NotifyingList<R> baseList,
      required List<T> Function(R value) map}) {
    this.mapFunction = map;
    this._baseList = baseList;

    subs = [
      _baseList.onRemove.listen(_onBaseItemRemoved),
      _baseList.onAdd.listen(_onBaseItemAdded),
    ];

    for (var entry in _baseList) {
      _onBaseItemAdded(entry);
    }
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
    return _internalList + other;
  }

  @override
  operator [](int index) {
    return _internalList[index];
  }

  @override
  void operator []=(int index, value) {
    throw Exception("Cannot write to combined list");
  }

  @override
  void add(value) {
    throw Exception("Cannot write to combined list");
  }

  @override
  void addAll(Iterable<T> iterable) {
    throw Exception("Cannot write to combined list");
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
    throw Exception("Cannot write to combined list");
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
    throw Exception("Cannot write to combined list");
  }

  @override
  void fillRange(int start, int end, [T? fillValue]) {
    throw Exception("Cannot write to combined list");
  }

  @override
  set first(T value) {
    throw Exception("Cannot write to combined list");
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
    throw Exception("Cannot write to combined list");
  }

  @override
  void insertAll(int index, Iterable<T> iterable) {
    throw Exception("Cannot write to combined list");
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
  set last(T value) {
    // TODO: implement last
    throw UnimplementedError();
  }

  @override
  int lastIndexOf(T element, [int? start]) {
    // TODO: implement lastIndexOf
    throw UnimplementedError();
  }

  @override
  int lastIndexWhere(bool Function(T element) test, [int? start]) {
    // TODO: implement lastIndexWhere
    throw UnimplementedError();
  }

  @override
  T lastWhere(bool Function(T element) test, {T Function()? orElse}) {
    // TODO: implement lastWhere
    throw UnimplementedError();
  }

  @override
  Iterable<R> map<R>(R Function(T e) toElement) {
    // TODO: implement map
    throw UnimplementedError();
  }

  @override
  // TODO: implement onAdd
  Stream<T> get onAdd => _internalList.onAdd;

  @override
  // TODO: implement onItemUpdated
  Stream<T> get onItemUpdated => _internalList.onItemUpdated;

  @override
  // TODO: implement onListUpdated
  Stream<dynamic> get onListUpdated => _internalList.onListUpdated;

  @override
  // TODO: implement onRemove
  Stream<T> get onRemove => _internalList.onRemove;

  @override
  T reduce(T Function(T value, T element) combine) {
    // TODO: implement reduce
    throw UnimplementedError();
  }

  @override
  bool remove(Object? value) {
    // TODO: implement remove
    throw UnimplementedError();
  }

  @override
  T removeAt(int index) {
    // TODO: implement removeAt
    throw UnimplementedError();
  }

  @override
  T removeLast() {
    // TODO: implement removeLast
    throw UnimplementedError();
  }

  @override
  void removeRange(int start, int end) {
    // TODO: implement removeRange
  }

  @override
  void removeWhere(bool Function(T element) test) {
    // TODO: implement removeWhere
  }

  @override
  void replaceRange(int start, int end, Iterable<T> replacements) {
    // TODO: implement replaceRange
  }

  @override
  void retainWhere(bool Function(T element) test) {
    // TODO: implement retainWhere
  }

  @override
  // TODO: implement reversed
  Iterable<T> get reversed => throw UnimplementedError();

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
    // TODO: implement sublist
    throw UnimplementedError();
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

  void _onBaseItemRemoved(R event) {
    for (var item in mapFunction(event)) {
      _internalList.remove(item);
    }
  }

  void _onBaseItemAdded(R event) {
    final mapped = mapFunction(event);

    if (mapped case INotifyingList n) {
      subs.add(n.onAdd.listen((d) {
        _internalList.add(d);
      }));

      subs.add(n.onRemove.listen((d) {
        _internalList.remove(d);
      }));
    }

    _internalList.addAll(mapped);
  }
}
