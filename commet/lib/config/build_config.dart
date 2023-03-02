class BuildConfig {
  static const bool DEBUG = String.fromEnvironment('BUILD_MODE', defaultValue: "debug") == "debug";

  static const bool RELEASE = String.fromEnvironment('BUILD_MODE', defaultValue: "debug") == "release";
}
