import 'package:commet/cache/file_provider.dart';
import 'package:commet/client/attachment.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/background_tasks/background_task_manager.dart';
import 'package:commet/utils/file_utils.dart';

class DownloadUtils {
  static Future<void> downloadAttachment(Attachment attachment) async {
    FileProvider? file;
    String name = "untitled";

    if (attachment is FileAttachment) {
      file = attachment.file;
      name = attachment.name;
    }

    backgroundTaskManager.addTask(AsyncTask(() async {
      if (file == null) {
        return BackgroundTaskStatus.failed;
      }

      var path = await FileUtils.getSaveFilePath(fileName: name);
      if (path != null) {
        file.save(path);
      }

      return BackgroundTaskStatus.completed;
    }, "Downloading: $name"));
  }
}
