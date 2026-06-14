import 'package:commet/config/platform_utils.dart';
import 'package:commet/main.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

class Layout {
  static WebBrowserInfo? browserInfo;
  static bool? _isWebDesktopCache;

  static bool _isWebDesktop() {
    if (_isWebDesktopCache != null) {
      return _isWebDesktopCache!;
    }

    if (browserInfo == null) {
      return true;
    }

    var userAgent = browserInfo!.userAgent ?? "";
    userAgent = userAgent.toLowerCase();

    if (userAgent.contains("android")) {
      return false;
    }

    if (userAgent.contains("iphone")) {
      return false;
    }

    if (userAgent.contains("mobile")) {
      return false;
    }

    if (userAgent.contains("macintosh")) {
      return true;
    }

    if (userAgent.contains("windows")) {
      return true;
    }

    if (userAgent.contains("linux")) {
      return true;
    }

    // assume desktop otherwise
    return true;
  }
}

enum LayoutType {
  mobile,
  desktop;
}

extension LayoutQueryData on MediaQueryData {
  LayoutType get layout {
    if (preferences.layoutOverride.value == "mobile") {
      return LayoutType.mobile;
    }

    if (preferences.layoutOverride.value == "desktop") {
      return LayoutType.desktop;
    }

    if (PlatformUtils.isWeb && Layout._isWebDesktop()) {
      return LayoutType.desktop;
    }

    if (PlatformUtils.isAndroid || PlatformUtils.isWeb) {
      final bool useMobileLayout =
          (size.shortestSide * preferences.appScale.value) < 600;
      if (useMobileLayout) {
        return LayoutType.mobile;
      }
    }

    return LayoutType.desktop;
  }

  bool get mobile {
    return layout == LayoutType.mobile;
  }

  bool get desktop {
    return layout == LayoutType.desktop;
  }
}
