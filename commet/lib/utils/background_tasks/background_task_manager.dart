import 'dart:async';

import 'package:commet/utils/notifying_list.dart';
import 'package:flutter/foundation.dart';

class BackgroundTaskManager {
  NotifyingList<BackgroundTask> tasks = NotifyingList.empty(growable: true);

  Stream<int> get onTaskAdded => tasks.onAdd;

  Stream<int> get onTaskRemoved => tasks.onRemove;

  Stream get onListUpdate => tasks.onListUpdated;

  void addTask(BackgroundTask task) {
    tasks.add(task);
    task.completed.listen((_) => onTaskCompleted(task));
  }

  void onTaskCompleted(BackgroundTask task) {
    if (kDebugMode) {
      print("Task was completed!: $task");
    }
    Timer(const Duration(seconds: 5), () {
      tasks.remove(task);
    });
  }
}

abstract class BackgroundTask {
  bool get isComplete;
  String get label;
  Stream<void> get completed;
}

abstract class BackgroundTaskWithProgress extends BackgroundTask {
  int get total;
  int get current;

  Stream<int> get onProgress;
}

class AsyncTask implements BackgroundTask {
  StreamController stream = StreamController.broadcast();

  @override
  Stream<void> get completed => stream.stream;

  @override
  String label;

  @override
  bool isComplete = false;

  AsyncTask(Future future, this.label) {
    future.then((value) => onFutureComplete());
  }

  void onFutureComplete() {
    isComplete = true;
    stream.add(null);
  }
}