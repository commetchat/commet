import 'dart:async';

import 'package:flutter/foundation.dart';

class Measure {
  static Future<T> timeAsync<T>(Future<T> Function() call,
      {String? name}) async {
    if (kDebugMode) {
      Stopwatch s = Stopwatch();
      s.start();

      var result = await call();

      s.stop();

      print(
          "Measured call time: $name -> ${s.elapsedMilliseconds}ms  (${s.elapsedMicroseconds}μs)");

      return result;
    }

    return call();
  }
}
