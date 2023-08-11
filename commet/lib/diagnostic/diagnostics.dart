import 'package:commet/main.dart';
import 'package:flutter/foundation.dart';

class TimerResult {
  final String name;
  final Duration time;

  const TimerResult(this.name, this.time);
}

class Diagnostics {
  List<TimerResult> results = List.empty(growable: true);

  void addResult(String name, Duration time) {
    results.add(TimerResult(name, time));

    if (kDebugMode) {
      print("Diagnostics: $name took ${time.inMilliseconds}ms");
    }
  }

  Future<T> timeAsync<T>(String name, Future<T> Function() func) async {
    if (!preferences.developerMode) return func();

    Stopwatch s = Stopwatch();
    s.start();

    var result = await func();

    s.stop();

    addResult(name, s.elapsed);
    return result;
  }

  T time<T>(String name, T Function() func) {
    if (!preferences.developerMode) return func();
    Stopwatch s = Stopwatch();

    s.start();

    var result = func();

    s.stop();

    addResult(name, s.elapsed);
    return result;
  }
}
