// ignore_for_file: constant_identifier_names

class BuildConfig {
  static const bool DEBUG = String.fromEnvironment('BUILD_MODE', defaultValue: "debug") == "debug";

  static const bool RELEASE = String.fromEnvironment('BUILD_MODE', defaultValue: "debug") == "release";

  static const bool DESKTOP = String.fromEnvironment('PLATFORM', defaultValue: "desktop") == "desktop";

  static const bool WEB = String.fromEnvironment('PLATFORM', defaultValue: "desktop") == "web";

  static const bool MOBILE = String.fromEnvironment('PLATFORM', defaultValue: "desktop") == "mobile";
}
