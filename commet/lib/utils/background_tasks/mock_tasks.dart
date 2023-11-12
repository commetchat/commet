import 'dart:async';

import 'package:commet/utils/background_tasks/background_task_manager.dart';

class FakeBackgroundTask implements BackgroundTask {
  StreamController stream = StreamController.broadcast();
  @override
  Stream<void> get completed => stream.stream;

  @override
  bool isComplete = false;

  @override
  String get label => "Fake background task";

  FakeBackgroundTask() {
    Timer(const Duration(seconds: 5), () {
      isComplete = true;
      stream.add(null);
    });
  }

  @override
  void Function()? action;

  @override
  bool get canCallAction => isComplete;
}

class FakeBackgroundTaskWithProgress implements BackgroundTaskWithProgress {
  StreamController stream = StreamController.broadcast();
  StreamController<int> progressStream = StreamController.broadcast();

  @override
  Stream<void> get completed => stream.stream;

  @override
  String get label => "Fake background task with progress ($current/$total)";

  @override
  bool isComplete = false;

  @override
  int current = 0;

  @override
  Stream<int> get onProgress => progressStream.stream;

  @override
  int get total => 20;

  FakeBackgroundTaskWithProgress() {
    progress();
    action = doAction;
  }

  void progress() {
    Timer(const Duration(seconds: 1), () {
      doProgress();

      progress();
    });
  }

  @override
  void Function()? action;

  void doProgress() {
    current += 1;
    progressStream.add(current);

    if (current >= total) {
      isComplete = true;
      stream.add(null);
      return;
    }
  }

  void doAction() {
    doProgress();
  }

  @override
  bool get canCallAction => true;
}
