import 'package:commet/config/platform_utils.dart';
import 'package:commet/utils/system_wide_shortcuts/system_wide_shortcuts_linux.dart';

class SystemWideShortcuts {
  static void init() async {
    if (PlatformUtils.isLinux) {
      SystemWideShortcutsLinux.init();
    }
  }
}
