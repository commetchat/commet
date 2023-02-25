import 'package:flutter_test/flutter_test.dart';

/// Workaround for https://github.com/flutter/flutter/issues/88765
extension WaitForExtension on WidgetTester {
  Future<void> waitFor(
    bool Function() finder, {
    Duration timeout = const Duration(seconds: 20),
    bool skipPumpAndSettle = false,
  }) async {
    final end = DateTime.now().add(timeout);

    do {
      if (DateTime.now().isAfter(end)) {
        throw Exception('Timed out waiting for $finder');
      }

      if (!skipPumpAndSettle) {
        await pumpAndSettle();
      }
      await Future.delayed(const Duration(milliseconds: 100));
    } while (finder.call() != true);
  }
}
