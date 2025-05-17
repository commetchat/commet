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

  static String get displayServer {
    if (kIsWeb) return "unknown";

    final env = Platform.environment;

    if (env.containsKey("XDG_SESSION_TYPE")) {
      return env["XDG_SESSION_TYPE"]!;
    }

    return "unknown";
  }
}
