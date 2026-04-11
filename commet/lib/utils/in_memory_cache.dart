import 'dart:async';

class InMemoryCache<T> {
  InMemoryCache({
    this.limit = 50,
    this.maxRetention = const Duration(minutes: 10),
    this.pollFrequency = const Duration(minutes: 2),
  }) {
    _timer = Timer(pollFrequency, clean);
  }

  // ignore: unused_field
  late Timer _timer;
  final int limit;
  final Duration maxRetention;
  final Duration pollFrequency;

  StreamController<String> _controller = StreamController.broadcast();

  Stream<String> get onRemove => _controller.stream;

  Map<String, (T, DateTime)> _cache = {};

  void put(String key, T value) {
    _cache[key] = (value, DateTime.now());
  }

  T? get(String key) {
    return _cache[key]?.$1;
  }

  Future<void> clean() async {
    var keys = _cache.keys.toList();

    for (var key in keys) {
      var ts = _cache[key]?.$2;
      if (ts == null) continue;

      var diff = DateTime.now().difference(ts).inSeconds;
      if (diff > maxRetention.inSeconds) {
        _controller.add(key);
        _cache.remove(key);
      }

      await Future.delayed(Duration(milliseconds: 200));
    }

    _timer = Timer(pollFrequency, clean);
  }
}
