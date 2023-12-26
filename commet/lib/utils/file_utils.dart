import 'dart:io';

import 'package:commet/config/platform_utils.dart';
import 'package:commet/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileUtils {
  static String getFreeFilePath(String desiredFilePath) {
    var dir = p.dirname(desiredFilePath);
    var file = p.basenameWithoutExtension(desiredFilePath);
    var extension = p.extension(desiredFilePath);

    var path = desiredFilePath;
    int attempts = 0;
    while (File(path).existsSync()) {
      path = p.join(dir, "${file}_($attempts)$extension");
      attempts += 1;

      //surely this wont happen
      if (attempts > 1000) {
        break;
      }
    }

    return path;
  }

  static Future<String?> getSaveFilePath({String? fileName}) async {
    try {
      var path = await FilePicker.platform.saveFile(
          fileName: fileName,
          initialDirectory: preferences.lastDownloadLocation);

      return path;
    } catch (_) {
      var dir = await getDownloadsDirectory();
      if (PlatformUtils.isAndroid) {
        dir = Directory("/storage/emulated/0/Download");
      }

      if (dir == null) {
        return null;
      }

      var path = p.join(dir.path, fileName);
      path = FileUtils.getFreeFilePath(path);
      return path;
    }
  }

  static Future<String?> getSaveDirectory() async {
    try {
      var path = await FilePicker.platform
          .getDirectoryPath(initialDirectory: preferences.lastDownloadLocation);

      return path;
    } catch (_) {
      var dir = await getDownloadsDirectory();
      if (PlatformUtils.isAndroid) {
        dir = Directory("/storage/emulated/0/Download");
      }

      if (dir == null) {
        return null;
      }

      return dir.path;
    }
  }
}
