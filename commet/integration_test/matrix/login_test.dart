import 'package:commet/ui/pages/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../extensions/wait_for.dart';
import '../extensions/common_flows.dart';
import '../generated/l10n.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test Matrix Login Success', (WidgetTester tester) async {
    await tester.clearUserData();
    // Build our app and trigger a frame.

    var app = await tester.setupApp();
    await tester.pumpWidget(app);

    await tester.login(app);

    await tester.waitFor(() => app.clientManager.isLoggedIn(),
        timeout: const Duration(seconds: 5), skipPumpAndSettle: true);
    expect(app.clientManager.isLoggedIn(), equals(true));

    await app.clientManager.close();
    await tester.clean();
  });

  testWidgets('Test Matrix Login Invalid', (WidgetTester tester) async {
    var hs =
        const String.fromEnvironment('HOMESERVER', defaultValue: "localhost");
    var username = "invalidUser";
    var password = "InvalidPassword!";

    // Build our app and trigger a frame.
    var app = await tester.setupApp();
    await tester.pumpWidget(app);

    await tester.waitFor(() => find.byType(LoginPage).evaluate().isNotEmpty);

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
    await tester.waitFor(
        () =>
            find.text(T.current.loginResultFailedMessage).evaluate().isNotEmpty,
        skipPumpAndSettle: false,
        timeout: const Duration(seconds: 5));
    await tester.pumpFrames(app, const Duration(seconds: 1));
    expect(app.clientManager.isLoggedIn(), equals(false));

    await app.clientManager.close();
    await tester.clean();
  });
}
