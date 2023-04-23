import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

class IntegrationTestSubprocess {
  static Future<Process> spawn(String currentDeviceId, String testCase) async {
    var hs =
        const String.fromEnvironment('HOMESERVER', defaultValue: "localhost");
    var username =
        const String.fromEnvironment('USER1_NAME', defaultValue: "alice");
    var password = const String.fromEnvironment('USER1_PW',
        defaultValue: "AliceInWonderland");

    var proc = await Process.start("ts-node", [
      'integration_test/subprocess/src/main.ts',
      '--homeserver',
      'http://$hs',
      '--username',
      username,
      '--password',
      password,
      '--test_case',
      testCase,
      '--device_id',
      currentDeviceId
    ]);

    proc.stdout.transform(utf8.decoder).forEach((out) {
      print("Node] $out");
    });

    return proc;
  }

  static Future<Process> verifyMeWithEmoji(String currentDeviceId) async {
    return await spawn(currentDeviceId, "verify_me_with_emoji");
  }
}
