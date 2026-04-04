import 'dart:io';

import 'package:commet/config/build_config.dart';
import 'package:commet/config/platform_utils.dart';

class SystemProcessesUtils {
  static Future<List<ProcessInfo>> getProcessList() async {
    if (PlatformUtils.isWeb) {
      return [];
    }

    if (BuildConfig.IS_FLATPAK) {
      var result = await Process.run(
          "flatpak-spawn", ["--host", "ps", "-e", "-o", "pid,command"]);
      return parseLinuxPS(result.stdout);
    }

    if (BuildConfig.LINUX) {
      var result = await Process.run("ps", ["-e", "-o", "pid,command"]);
      return parseLinuxPS(result.stdout);
    }

    return [];
  }

  static List<ProcessInfo> parseLinuxPS(String output) {
    // Skip first line
    var lines = output.trim().split("\n").sublist(1);

    var result = List<ProcessInfo>.empty(growable: true);

    for (var line in lines) {
      var split = line.trim().split(" ");
      if (split.isEmpty) continue;

      print(split);
      var pid = int.parse(split[0]);
      var command = split[1];

      if (command.startsWith("[")) command = command.substring(1);

      if (command.endsWith("]"))
        command = command.substring(0, command.length - 1);

      List<String> args = [];
      if (split.length > 2) {
        args = split.sublist(2);
      }

      result.add(ProcessInfo(processId: pid, command: command, args: args));
    }

    return result;
  }
}

class ProcessInfo {
  final int processId;
  final String command;
  final List<String> args;

  ProcessInfo(
      {required this.processId, required this.command, this.args = const []});
}
