import 'package:commet/config/build_config.dart';
import 'package:flutter/widgets.dart';

class Layout {
  static bool get desktop {
    if (BuildConfig.DESKTOP) {
      return true;
    }

    if (BuildConfig.MOBILE) {
      return false;
    }

    return !_isPortrait();
  }

  static bool get mobile {
    if (BuildConfig.MOBILE) {
      return true;
    }

    if (BuildConfig.DESKTOP) {
      return false;
    }

    return _isPortrait();
  }

  static bool _isPortrait() {
    var view = WidgetsBinding.instance.platformDispatcher.views.first;
    var size = view.physicalSize;

    return size.height > size.width;
  }
}
