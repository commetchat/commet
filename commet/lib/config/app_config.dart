library;

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

  static Future<String> getDriftDatabasePath() async {
    if (BuildConfig.WEB) {
      return "commet";
    }
    final dir = await getDatabasePath();
    return join(dir, "account", "drift");
  }
}
