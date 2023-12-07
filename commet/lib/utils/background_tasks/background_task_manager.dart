import 'dart:async';

import 'package:commet/debug/log.dart';
import 'package:commet/utils/notifying_list.dart';

class BackgroundTaskManager {
  NotifyingList<BackgroundTask> tasks = NotifyingList.empty(growable: true);

  Stream<int> get onTaskAdded => tasks.onAdd;

  Stream<int> get onTaskRemoved => tasks.onRemove;

  Stream get onListUpdate => tasks.onListUpdated;

  Map<BackgroundTask, StreamSubscription> subscriptions = {};

  void addTask(BackgroundTask task) {
    tasks.add(task);
    subscriptions[task] = task.completed.listen((_) => onTaskCompleted(task));
  }

  void onTaskCompleted(BackgroundTask task) {
    Log.i("Background Task was completed!: $task");

    Timer(const Duration(seconds: 5), () {
      tasks.remove(task);
      subscriptions[task]?.cancel();
    });
  }
}

enum BackgroundTaskStatus { running, failed, completed }

abstract class BackgroundTask {
  BackgroundTaskStatus get status;
  String get label;
  Stream<void> get completed;

  bool get canCallAction;
  void Function()? action;
  void dispose();
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
  BackgroundTaskStatus status = BackgroundTaskStatus.running;

  AsyncTask(Future<BackgroundTaskStatus> Function() func, this.label,
      {this.action, this.isActionReady}) {
    doAsyncFunc(func);
  }

  void doAsyncFunc(Future<BackgroundTaskStatus> Function() func) async {
    try {
      var result = await func.call();
      onFutureComplete(result);
    } catch (exception, stack) {
      Log.onError(exception, stack);
      onFutureComplete(BackgroundTaskStatus.failed);
    }
  }

  void onFutureComplete(BackgroundTaskStatus result) {
    status = result;
    stream.add(null);
  }

  @override
  void Function()? action;

  bool Function()? isActionReady;

  @override
  bool get canCallAction => isActionReady?.call() ?? false;

  @override
  void dispose() {
    stream.close();
  }
}
