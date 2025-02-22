import 'dart:convert';

import 'package:commet/debug/log.dart';
import 'package:flutter/services.dart';

class GlobalConfig {
  static late Map<String, dynamic> data;

  static String get defaultHomeserver {
    return data["default_homeserver"] ?? "matrix.org";
  }

  static Future<void> init() async {
    try {
      String jsonData = await rootBundle
          .loadString('assets/config/global_config.json', cache: false);

      data = const JsonDecoder().convert(jsonData);
      Log.i(jsonData);
    } catch (_) {
      Log.e("Failed to load global config");
    }
  }
}
