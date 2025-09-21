// ignore_for_file: avoid_print

import 'dart:io';

String? getArg(List<String> args, String name) {
  int index = args.indexOf(name);
  if (index == -1) return null;

  return args[index + 1];
}

String getVersionTag(List<String> args) {
  var tag = getArg(args, "--version_tag");
  if (tag != null) {
    return tag;
  }

  return "v0.0.0";
}

String getPlatform(List<String> args) {
  return getArg(args, "--platform")!;
}

String getHash(List<String> args) {
  return getArg(args, "--git_hash") ?? "unknown";
}

String getEnableGoogleServices(List<String> args) {
  return getArg(args, "--enable_google_services") ?? "false";
}

String getBuildVersion(String versionTag) {
  var regex = RegExp(r"\d+(\.\d+)+");
  var match = regex.firstMatch(versionTag);
  return match![0]!;
}

String getFlutterPlatformName(String platform) {
  if (platform == "android") {
    return "apk";
  }

  return platform;
}

Future<void> main(List<String> args) async {
  String version = getVersionTag(args);
  String platform = getPlatform(args);
  String hash = getHash(args);
  String enableGoogleServices = getEnableGoogleServices(args);
  String buildVersion = getBuildVersion(version);
  String flutterPlatform = getFlutterPlatformName(platform);
  String? buildDetail = getArg(args, "--build_detail");
  print("Building release:");
  print("Version:\t'$version'");
  print("Build Version:\t'$buildVersion'");
  print("Platform:\t'$platform' / '$flutterPlatform' ");
  print("Hash:\t\t'$hash'");

  if (buildDetail != null) {
    print("Detail:\t\t'$buildDetail'");
  }

  var process = Process.runSync(
    "flutter",
    [
      "build",
      flutterPlatform,
      "--build-name=$buildVersion",
      "--release",
      "--dart-define",
      "BUILD_MODE=release",
      "--dart-define",
      "PLATFORM=$platform",
      "--dart-define",
      "GIT_HASH=$hash",
      "--dart-define",
      "VERSION_TAG=$version",
      "--dart-define",
      "ENABLE_GOOGLE_SERVICES=$enableGoogleServices",
      if (buildDetail != null) "--dart-define",
      if (buildDetail != null) "BUILD_DETAIL=$buildDetail",
      if (platform == "web") "--dart-define",
      if (platform == "web") "FLUTTER_WEB_CANVASKIT_URL=canvaskit/",
      if (platform == "web") "--source-maps"
    ],
    runInShell: true,
  );

  print(process.stdout);
  print(process.stderr);
  exit(process.exitCode);
}
