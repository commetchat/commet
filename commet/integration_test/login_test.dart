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

void main() {
  testWidgets('Test Matrix Login', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    var app = App();
    await tester.pumpWidget(app);

    var inputs = find.byType(TextField);
    expect(inputs, findsWidgets);

    var hs = String.fromEnvironment(
      'HOME_SERVER',
      defaultValue: 'localhost',
    );

    var username = String.fromEnvironment(
      'USER_NAME',
      defaultValue: 'alice',
    );

    var password = String.fromEnvironment(
      'USER_PW',
      defaultValue: 'AliceInWonderland',
    );

    await tester.enterText(inputs.at(0), hs);
    await tester.enterText(inputs.at(1), username);
    await tester.enterText(inputs.at(2), password);

    var button = find.widgetWithText(ElevatedButton, "Login");

    await tester.tap(button);

    await Future.delayed(const Duration(seconds: 5));

    expect(app.clientManager.isLoggedIn(), equals(true));
  });
}
