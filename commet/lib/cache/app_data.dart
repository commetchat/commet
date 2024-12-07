import 'package:commet/cache/error_log.dart';
import 'package:commet/cache/file_cache.dart';

import 'app_data_stub.dart' if (dart.library.io) "app_data_io.dart";

class AppData {
  FileCache? fileCache;
  ErrorLog? errorLog;
  bool isInit = false;
  static final AppData instance = AppData._();

  AppData._();

  Future<void> init() async {
    if (isInit) {
      return;
    }

    await initAppData(this);

    isInit = true;
  }

  Future<void> close() async {
    await closeAppData(this);
  }
}
