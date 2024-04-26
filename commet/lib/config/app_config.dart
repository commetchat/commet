library config;

import 'package:commet/config/build_config.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class AppConfig {
  static Future<String> getDatabasePath() async {
    if (BuildConfig.WEB) {
      return "commet";
    }
    final dir = await getApplicationSupportDirectory();
    return join(dir.path, "db");
  }

  static Future<String> getIsarDatabasePath() async {
    if (BuildConfig.WEB) {
      return "commet";
    }
    final dir = await getApplicationSupportDirectory();
    return join(dir.path, "isar");
  }

  static Future<String> getHiveDatabasePath() async {
    if (BuildConfig.WEB) {
      return "commet";
    }
    final dir = await getApplicationSupportDirectory();
    return join(dir.path, "hive");
  }
}
