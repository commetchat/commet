import 'dart:async';

import 'package:commet/main.dart';
import 'package:commet/utils/background_tasks/background_task_manager.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class BackgroundTaskView extends StatefulWidget {
  const BackgroundTaskView(this.manager, {super.key});
  final BackgroundTaskManager manager;

  @override
  State<BackgroundTaskView> createState() => _BackgroundTaskViewState();
}

class _BackgroundTaskViewState extends State<BackgroundTaskView> {
  @override
  void initState() {
    super.initState();
    widget.manager.onListUpdate.listen(onTaskListUpdated);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(blurRadius: 4, color: Theme.of(context).shadowColor)
            ]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            color: Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
            child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.manager.tasks
                      .map((e) => _SingleBackgroundTaskView(
                            e,
                            key: ValueKey("task-display${e.hashCode}"),
                          ))
                      .toList(),
                )),
          ),
        ),
      ),
    );
  }

  void onTaskListUpdated(event) {
    setState(() {});
  }
}

class _SingleBackgroundTaskView extends StatefulWidget {
  const _SingleBackgroundTaskView(this.task, {super.key});
  final BackgroundTask task;

  @override
  State<_SingleBackgroundTaskView> createState() =>
      __SingleBackgroundTaskViewState();
}

class __SingleBackgroundTaskViewState extends State<_SingleBackgroundTaskView> {
  StreamSubscription? progressSubscription;
  StreamSubscription? completeSubscription;
  double? progress;
  bool complete = false;

  @override
  void initState() {
    complete = widget.task.isComplete;
    completeSubscription = widget.task.completed.listen((event) {
      onTaskComplete();
    });
    if (widget.task is BackgroundTaskWithProgress) {
      var progressTask = (widget.task as BackgroundTaskWithProgress);
      progressSubscription = progressTask.onProgress.listen(onTaskProgressed);

      progress = progressTask.current / progressTask.total;
    }
    super.initState();
  }

  @override
  void dispose() {
    progressSubscription?.cancel();
    completeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
            child: SizedBox(
                width: 10,
                height: 10,
                child: complete
                    ? const Icon(
                        Icons.check,
                        color: Colors.greenAccent,
                        size: 10,
                      )
                    : CircularProgressIndicator(
                        strokeWidth: 2,
                        value: progress,
                      )),
          ),
          GestureDetector(
              onTap: () => backgroundTaskManager.addTask(widget.task),
              child: tiamat.Text.tiny(widget.task.label))
        ],
      ),
    );
  }

  void onTaskComplete() {
    setState(() {
      complete = true;
    });
  }

  void onTaskProgressed(int event) {
    setState(() {
      progress = event / (widget.task as BackgroundTaskWithProgress).total;
    });
  }
}
