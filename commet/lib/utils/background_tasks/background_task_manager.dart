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
    subscriptions[task] =
        task.statusChanged.listen((_) => onStatusChanged(task));
  }

  void onStatusChanged(BackgroundTask task) {
    if (task.shouldRemoveTask) {
      subscriptions[task]?.cancel();
      tasks.remove(task);
      task.dispose();
    }
  }
}

enum BackgroundTaskStatus { running, failed, completed }

abstract class BackgroundTask {
  BackgroundTaskStatus get status;
  String get label;
  Stream<void> get statusChanged;

  // Should the task be automatically removed from task manager when either completed or errored
  bool get shouldRemoveTask;

  bool get canCallAction;
  void Function()? action;
  void dispose();
}

abstract class BackgroundTaskWithOptionalProgress extends BackgroundTask {
  double? get progress;
}

abstract class BackgroundTaskWithIntegerProgress extends BackgroundTask {
  int get total;
  int get current;

  Stream<int> get onProgress;
}

class AsyncTask implements BackgroundTask {
  StreamController stream = StreamController.broadcast();

  @override
  Stream<void> get statusChanged => stream.stream;

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
    Timer(const Duration(seconds: 5), () {
      shouldRemoveTask = true;
      stream.add(null);
    });
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

  @override
  bool shouldRemoveTask = false;
}
