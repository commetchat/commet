import 'dart:io';

import 'package:flutter/foundation.dart';

// This exists as a replacement for `Platform` because currently things like `Platform.isLinux` doesnt work on web...
class PlatformUtils {
  static bool get isLinux {
    if (kIsWeb) return false;
    return Platform.isLinux;
  }

  static bool get isWindows {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  static bool get isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  static bool get isWeb {
    return kIsWeb;
  }

  static bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  static bool get isMacOS {
    if (kIsWeb) return false;
    return Platform.isMacOS;
  }

  static String get appID {
    if (Platform.isIOS) {
      return "chat.commet.commetapp.quirt";
    } else if (Platform.isMacOS) {
      return "chat.commet.commetapp.macos";
    } else if (Platform.isAndroid) {
      return "chat.commet.commetapp.android";
    }
    return "chat.commet.commetapp";
  }
}
