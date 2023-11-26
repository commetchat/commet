// ignore_for_file: constant_identifier_names

import 'package:flutter/foundation.dart';

class BuildConfig {
  static const String _buildMode =
      String.fromEnvironment('BUILD_MODE', defaultValue: _Constants.release);

  static const String PLATFORM =
      String.fromEnvironment('PLATFORM', defaultValue: _Constants._desktop);

  static const String GIT_HASH =
      String.fromEnvironment('GIT_HASH', defaultValue: "unknown");

  static const String VERSION_TAG =
      String.fromEnvironment('VERSION_TAG', defaultValue: "development");

  // Details about build, like "flatpak", "fdroid"
  static const String BUILD_DETAIL =
      String.fromEnvironment('BUILD_DETAIL', defaultValue: "default");

  static const bool ENABLE_GOOGLE_SERVICES = false;

  static const bool DEBUG = _buildMode == _Constants._debug;

  static const bool RELEASE = _buildMode == _Constants.release;

  static const bool DESKTOP = PLATFORM == _Constants._desktop ||
      PLATFORM == _Constants._linux ||
      PLATFORM == _Constants._windows ||
      PLATFORM == _Constants._macos;

  static const bool WEB = PLATFORM == _Constants._web || kIsWeb;

  static const bool MOBILE = PLATFORM == _Constants._mobile ||
      PLATFORM == _Constants._android ||
      PLATFORM == _Constants._ios;

  static const bool ANDROID = PLATFORM == _Constants._android;

  static const bool WINDOWS = PLATFORM == _Constants._windows;

  static const bool LINUX = PLATFORM == _Constants._linux;

  static const bool MAC = PLATFORM == _Constants._macos;

  static const bool IOS = PLATFORM == _Constants._ios;

  static const bool SUPPORTS_CACHE = !WEB;

  static const String app = "Commet";

  // IM SO SORRY
  static const String appName = MOBILE
      ? (ANDROID
          ? "$app for Android"
          : (IOS ? "$app for iOS" : "$app for Mobile"))
      : (DESKTOP
          ? (WINDOWS
              ? "$app for Windows"
              : LINUX
                  ? "$app for Linux"
                  : MAC
                      ? "$app for MacOS"
                      : "$app for Desktop")
          : WEB
              ? "$app for Web"
              : app);
}

class _Constants {
  static const String _debug = "debug";

  static const String release = "release";

  static const String _desktop = "desktop";

  static const String _linux = "linux";

  static const String _windows = "windows";

  static const String _macos = "macos";

  static const String _ios = "ios";

  static const String _android = "android";

  static const String _mobile = "mobile";

  static const String _web = "web";
}
