import 'package:commet/config/build_config.dart';
import 'package:flutter/widgets.dart';

class OrientationUtils {
  static Orientation getCurrentOrientation(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var ratio = screenSize.width / screenSize.height;

    if (ratio > 1) return Orientation.landscape;
    return Orientation.portrait;
  }
}
