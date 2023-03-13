// ignore_for_file: constant_identifier_names

class BuildConfig {
  static const String _buildMode = String.fromEnvironment('BUILD_MODE', defaultValue: "debug");

  static const String _platform = String.fromEnvironment('PLATFORM', defaultValue: "desktop");

  static const bool DEBUG = _buildMode == _Constants._debug;

  static const bool RELEASE = _buildMode == _Constants.release;

  static const bool DESKTOP = _platform == _Constants._desktop ||
      _platform == _Constants._linux ||
      _platform == _Constants._windows ||
      _platform == _Constants._macos;

  static const bool WEB = _platform == _Constants._web;

  static const bool MOBILE =
      _platform == _Constants._mobile || _platform == _Constants._android || _platform == _Constants._ios;

  static const bool ANDROID = _platform == _Constants._android;

  static const bool WINDOWS = _platform == _Constants._windows;

  static const bool LINUX = _platform == _Constants._linux;

  static const bool MAC = _platform == _Constants._macos;

  static const bool IOS = _platform == _Constants._ios;

  static const String app = "Commet";

  // IM SO SORRY
  static const String appName = MOBILE
      ? (ANDROID ? "$app for Android" : (IOS ? "$app for iOS" : "$app for Mobile"))
      : (DESKTOP
          ? (WINDOWS
              ? "$app for Windows"
              : LINUX
                  ? "$app for Linux"
                  : MAC
                      ? "$app for MacOS"
                      : "$app for Desktop")
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
