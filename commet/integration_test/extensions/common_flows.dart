import 'dart:io';

import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/config/app_config.dart';
import 'package:commet/ui/pages/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:commet/main.dart';
import 'package:hive/hive.dart';
import 'package:matrix/encryption/utils/key_verification.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';

import 'wait_for.dart';

import 'package:path/path.dart' as p;

extension CommonFlows on WidgetTester {
  Future<void> clearUserData() async {
    var dir = Directory(await AppConfig.getDatabasePath());
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    dir = await getApplicationSupportDirectory();
    print("Cleaning ${dir.path}");
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> clean() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    await preferences.clear();
  }

  Future<void> login(App app) async {
    await waitFor(() => find.byType(LoginPage).evaluate().isNotEmpty);

    // Test Login Successful
    var hs = const String.fromEnvironment('HOMESERVER', defaultValue: "localhost");

    var username = const String.fromEnvironment('USER1_NAME', defaultValue: "alice");

    var password = const String.fromEnvironment('USER1_PW', defaultValue: "AliceInWonderland");

    var button = find.widgetWithText(ElevatedButton, "Login");

    var inputs = find.byType(TextField);
    expect(inputs, findsWidgets);

    // Build our app and trigger a frame.

    await enterText(inputs.at(0), hs);
    await pumpAndSettle();
    await enterText(inputs.at(1), username);
    await pumpAndSettle();
    await enterText(inputs.at(2), password);
    await pumpAndSettle();

    await tap(button);

    await pumpAndSettle();

    await waitFor(() => app.clientManager.isLoggedIn(), timeout: const Duration(seconds: 5), skipPumpAndSettle: true);
    expect(app.clientManager.isLoggedIn(), equals(true));
  }

  Future<Client> createTestClient() async {
    var hs = const String.fromEnvironment('HOMESERVER', defaultValue: "localhost");

    var username = const String.fromEnvironment('USER1_NAME', defaultValue: "alice");

    var password = const String.fromEnvironment('USER1_PW', defaultValue: "AliceInWonderland");

    var otherClient = Client(
      "Commet Integration Tester",
      verificationMethods: {KeyVerificationMethod.emoji, KeyVerificationMethod.numbers},
      nativeImplementations: MatrixClient.nativeImplementations,
      logLevel: Level.verbose,
      databaseBuilder: (client) async {
        print(await AppConfig.getDatabasePath());
        final db = HiveCollectionsDatabase(client.clientName, await AppConfig.getDatabasePath());
        await db.open();
        return db;
      },
    );

    await otherClient.checkHomeserver(Uri.http(hs));

    await otherClient.login(LoginType.mLoginPassword,
        identifier: AuthenticationUserIdentifier(user: username), password: password);

    return otherClient;
  }
}
