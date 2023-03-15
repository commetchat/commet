import 'dart:io';

import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/ui/pages/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:commet/main.dart';
import 'package:path_provider/path_provider.dart';

import 'wait_for.dart';

import 'package:path/path.dart' as p;

extension CommonFlows on WidgetTester {
  Future<void> clearUserData() async {
    var dir = Directory(await MatrixClient.getDBPath());
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    dir = await getApplicationSupportDirectory();
    var path = p.join(dir.path, "matrix") + p.separator;
    dir = Directory(path);
    print("Clearning" + dir.path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> login(App app) async {
    await pumpWidget(app);

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
}
