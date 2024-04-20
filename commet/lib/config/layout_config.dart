import 'package:commet/config/build_config.dart';
import 'package:device_info_plus/device_info_plus.dart';

class Layout {
  static WebBrowserInfo? browserInfo;
  static bool? _isWebDesktopCache;

  static bool get desktop {
    if (BuildConfig.DESKTOP) {
      return true;
    }

    if (BuildConfig.MOBILE) {
      return false;
    }

    _isWebDesktopCache = _isWebDesktop();
    return _isWebDesktopCache!;
  }

  static bool get mobile {
    if (BuildConfig.MOBILE) {
      return true;
    }

    if (BuildConfig.DESKTOP) {
      return false;
    }

    _isWebDesktopCache = _isWebDesktop();
    return !_isWebDesktopCache!;
  }

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
