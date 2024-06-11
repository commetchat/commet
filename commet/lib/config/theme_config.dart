import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ThemeConfig {
  static Future<Directory> getCustomThemesDir() async {
    var dir = await getApplicationSupportDirectory();
    var p = dir.path;

    var directory = Directory(path.join(p, "theme", "custom"));
    var exists = await directory.exists();
    if (!exists) {
      directory.create();
    }

    return directory;
  }

  static Future<List<Directory>> getCustomThemes() async {
    var dir = await getCustomThemesDir();

    var directories = await dir.list().where((e) => e is Directory).toList();
    return List<Directory>.from(directories);
  }

  static Future<File> getFileFromThemeDir(Directory dir) async {
    var file = File(path.join(dir.path, "theme.json"));
    return file;
  }
}
