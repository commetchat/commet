import 'dart:io';

import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/config/app_config.dart';
import 'package:commet/ui/organisms/side_navigation_bar.dart';
import 'package:commet/ui/pages/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:commet/main.dart';
import 'package:hive/hive.dart';
import 'package:matrix/encryption/utils/key_verification.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';

import 'wait_for.dart';

extension CommonFlows on WidgetTester {
  String get homeserver =>
      const String.fromEnvironment('HOMESERVER', defaultValue: "localhost");
  String get username =>
      const String.fromEnvironment('USER1_NAME', defaultValue: "alice");
  String get password => const String.fromEnvironment('USER1_PW',
      defaultValue: "AliceInWonderland");

  String get userTwoName =>
      const String.fromEnvironment('USER2_NAME', defaultValue: "bob");
  String get userTwoPassword =>
      const String.fromEnvironment('USER2_PW', defaultValue: "CanWeFixIt");

  Future<void> clearUserData() async {
    var dir = Directory(await AppConfig.getDatabasePath());
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    dir = await getApplicationSupportDirectory();

    if (!await dir.exists()) return;

    var files = await dir.list(recursive: true).toList();
    for (var file in files) {
      try {
        if (!await file.exists()) continue;

        await file.delete();
      } catch (exception) {
        // ignore: avoid_print
        print("Could not delete file: ${file.uri.toString()}");
      }
    }
  }

  Future<void> clean() async {
    await Hive.close();
    await preferences.clear();
    await clearUserData();
  }

  Future<App> setupApp() async {
    await clearUserData();
    ensureBindingInit();
    await initNecessary();
    await initGuiRequirements();
    return App(clientManager: clientManager!);
  }

  Future<void> login(App app) async {
    await waitFor(() => find.byType(LoginPage).evaluate().isNotEmpty);

    var button = find.widgetWithText(ElevatedButton, "Login");

    var inputs = find.byType(TextField);
    expect(inputs, findsWidgets);

    // Build our app and trigger a frame.

    await enterText(inputs.at(0), homeserver);
    await pumpAndSettle();
    await enterText(inputs.at(1), username);
    await pumpAndSettle();
    await enterText(inputs.at(2), password);
    await pumpAndSettle();

    await tap(button);

    await pumpAndSettle();

    await waitFor(() => app.clientManager.isLoggedIn(),
        timeout: const Duration(seconds: 5), skipPumpAndSettle: true);
    expect(app.clientManager.isLoggedIn(), equals(true));
  }

  Future<void> loginUser2(App app) async {
    await waitFor(() => find.byType(LoginPage).evaluate().isNotEmpty);
    var button = find.widgetWithText(ElevatedButton, "Login");

    var inputs = find.byType(TextField);
    expect(inputs, findsWidgets);

    await enterText(inputs.at(0), homeserver);
    await pumpAndSettle();
    await enterText(inputs.at(1), userTwoName);
    await pumpAndSettle();
    await enterText(inputs.at(2), userTwoPassword);
    await pumpAndSettle();

    await tap(button);

    await pumpAndSettle();

    await waitFor(() => app.clientManager.isLoggedIn(),
        timeout: const Duration(seconds: 5), skipPumpAndSettle: true);
    expect(app.clientManager.isLoggedIn(), equals(true));
  }

  Future<Client> createTestClient() async {
    var otherClient = Client(
      "Commet Integration Tester",
      verificationMethods: {
        KeyVerificationMethod.emoji,
        KeyVerificationMethod.numbers
      },
      nativeImplementations: MatrixClient.nativeImplementations,
      logLevel: Level.verbose,
      databaseBuilder: (client) async {
        final db = HiveCollectionsDatabase(
            client.clientName, await AppConfig.getDatabasePath());
        await db.open();
        return db;
      },
    );

    await otherClient.checkHomeserver(Uri.http(homeserver));

    await otherClient.login(LoginType.mLoginPassword,
        identifier: AuthenticationUserIdentifier(user: username),
        password: password);

    return otherClient;
  }

  Future<void> openSettings(App app) async {
    await dragUntilVisible(find.byKey(SideNavigationBar.settingsKey),
        find.byType(SideNavigationBar), const Offset(0, 20));

    await tap(find.byKey(SideNavigationBar.settingsKey));

    await pumpAndSettle();
  }
}
