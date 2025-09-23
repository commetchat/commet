import 'dart:async';

import 'package:commet/cache/file_provider.dart';
import 'package:commet/client/attachment.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/background_tasks/background_task_manager.dart';
import 'package:commet/utils/file_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class DownloadFileTask implements BackgroundTaskWithOptionalProgress {
  FileProvider file;
  late String filename;

  String? destinationPath;

  @override
  void Function()? action;

  @override
  bool get canCallAction => destinationPath != null && PlatformUtils.isLinux;

  @override
  void dispose() {
    sub?.cancel();
  }

  @override
  late String label;

  @override
  double? progress = 0;

  @override
  bool shouldRemoveTask = false;

  StreamSubscription? sub;

  @override
  BackgroundTaskStatus status = BackgroundTaskStatus.running;

  StreamController controller = StreamController.broadcast();
  @override
  Stream<void> get statusChanged => controller.stream;

  DownloadFileTask(this.file, String? fileName) {
    filename = fileName ?? "unnamed";

    this.label = "Downloading '$filename'...";

    action = navigateToFile;
  }

  void navigateToFile() {
    if (destinationPath != null) {
      FileUtils.navigateToFile(destinationPath!);
    }
  }

  Future<void> run() async {
    try {
      var result = await _doDownload();
      status = switch (result) {
        true => BackgroundTaskStatus.completed,
        false => BackgroundTaskStatus.failed,
      };
    } catch (exception, trace) {
      Log.onError(exception, trace);
      status = BackgroundTaskStatus.failed;
    }

    controller.add(());

    Timer(const Duration(seconds: 5), () {
      shouldRemoveTask = true;
      controller.add(null);
    });
  }

  Future<bool> _doDownload() async {
    sub = file.onProgressChanged?.listen((downloadProgress) {
      final amount = downloadProgress.downloaded.toDouble() /
          downloadProgress.total.toDouble();
      progress = amount;

      controller.add(());
    });

    if (PlatformUtils.isAndroid || kIsWeb) {
      final bytes = await file.getFileData();
      if (bytes != null) {
        destinationPath = await FilePicker.platform.saveFile(
            fileName: filename,
            initialDirectory: preferences.lastDownloadLocation,
            bytes: bytes);

        return destinationPath != null;
      } else {
        return false;
      }
    }

    destinationPath = await FilePicker.platform.saveFile(
        fileName: filename, initialDirectory: preferences.lastDownloadLocation);

    if (destinationPath != null) {
      await file.save(destinationPath!);
      return true;
    } else {
      return false;
    }
  }
}

class DownloadUtils {
  static Future<void> downloadAttachment(Attachment attachment) async {
    FileProvider? file;
    String name = "untitled";

    if (attachment is FileAttachment) {
      file = attachment.file;
      name = attachment.name;
    } else {
      return;
    }

    final task = DownloadFileTask(file, name);
    backgroundTaskManager.addTask(task);
    await task.run();
  }
}
