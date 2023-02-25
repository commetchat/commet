// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:commet/main.dart';

import 'extensions/wait_for.dart';

void main() {
  testWidgets('Test Matrix Login Succeeds', (WidgetTester tester) async {
    const hs = String.fromEnvironment('HOMESERVER');

    const username = String.fromEnvironment('USER1_NAME');

    const password = String.fromEnvironment('USER1_PW');
    // Build our app and trigger a frame.
    var app = App();
    await tester.pumpWidget(app);

    var inputs = find.byType(TextField);
    expect(inputs, findsWidgets);

    await tester.enterText(inputs.at(0), hs);
    await tester.pumpAndSettle();
    await tester.enterText(inputs.at(1), username);
    await tester.pumpAndSettle();
    await tester.enterText(inputs.at(2), password);
    await tester.pumpAndSettle();

    var button = find.widgetWithText(ElevatedButton, "Login");
    await tester.tap(button);

    print("LOIWQEUOIQWUEO");
    await tester.pumpAndSettle();

    print("ASDASDASDASD");

    await tester.waitFor(() => app.clientManager.isLoggedIn(), timeout: Duration(seconds: 5), skipPumpAndSettle: true);
    expect(app.clientManager.isLoggedIn(), equals(true));
  });

  testWidgets('Test Matrix Login Fails', (WidgetTester tester) async {
    const hs = String.fromEnvironment('HOMESERVER');

    const username = "invalidUser";
    const password = "InvalidPassword!";
    // Build our app and trigger a frame.
    var app = App();
    await tester.pumpWidget(app);

    var inputs = find.byType(TextField);
    expect(inputs, findsWidgets);

    await tester.enterText(inputs.at(0), hs);
    await tester.pumpAndSettle();
    await tester.enterText(inputs.at(1), username);
    await tester.pumpAndSettle();
    await tester.enterText(inputs.at(2), password);
    await tester.pumpAndSettle();

    var button = find.widgetWithText(ElevatedButton, "Login");

    await tester.tap(button);
    await tester.pumpAndSettle();

    await tester.waitFor(() => find.text("Login Failed").evaluate().isNotEmpty, timeout: Duration(seconds: 5));

    expect(app.clientManager.isLoggedIn(), equals(false));
  });
}
