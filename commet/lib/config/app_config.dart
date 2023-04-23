library config;

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

@Deprecated("No longer in use")
ValueNotifier<double> uiScale = ValueNotifier<double>(1);

@Deprecated("No longer in use")
double s(double value) {
  return value * uiScale.value;
}

@Deprecated("No longer in use")
void setUiScale(double value) {
  uiScale.value = value;
}

@Deprecated("No longer in use")
double getUiScale() {
  return uiScale.value;
}

class AppConfig {
  static Future<String> getDatabasePath() async {
    final dir = await getApplicationSupportDirectory();
    return join(dir.path, "hive");
  }
}
