import 'package:commet/config/build_config.dart';
import 'package:commet/debug/log.dart';
import 'package:flutter/widgets.dart';

class Layout {
  static bool get desktop {
    if (BuildConfig.DESKTOP) {
      return true;
    }

    return !_isPortrait();
  }

  static bool get mobile {
    if (BuildConfig.MOBILE) {
      return true;
    }

    return _isPortrait();
  }

  static bool _isPortrait() {
    var view = WidgetsBinding.instance.platformDispatcher.views.first;
    var size = view.physicalSize;

    return size.height > size.width;
  }
}
