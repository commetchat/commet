import 'package:commet/config/build_config.dart';
import 'package:commet/main.dart';
import 'package:window_manager/window_manager.dart';

class WindowManagement {
  static Future<void> init() async {
    if (!BuildConfig.DESKTOP) return;

    await windowManager.ensureInitialized();
    _WindowListener listener = _WindowListener();

    windowManager.setPreventClose(preferences.minimizeOnClose);
    windowManager.addListener(listener);
  }
}

class _WindowListener extends WindowListener {
  @override
  void onWindowClose() {
    super.onWindowClose();

    if (preferences.minimizeOnClose) {
      windowManager.minimize();
    }
  }
}
