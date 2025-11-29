import 'dart:collection';

import 'package:commet/debug/log.dart';

abstract class TaskScheduler {
  enqueue(Future<void> Function() callback);
}

class OneAtATimeScheduler implements TaskScheduler {
  Queue<Future<void> Function()> remainingTasks = Queue();

  Future<void>? currentFuture;

  enqueue(Future<void> Function() callback) {
    remainingTasks.add(callback);

    if (currentFuture == null) {
      currentFuture = runQueue();
    }
  }

  Future<void> runQueue() async {
    while (remainingTasks.isNotEmpty) {
      await Future.delayed(Duration(milliseconds: 10));
      var task = remainingTasks.removeFirst();
      ;

      try {
        await task();
      } catch (err, trace) {
        Log.onError(err, trace);
      }
    }

    currentFuture = null;
  }
}
