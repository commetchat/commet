import 'package:commet/generated/l10n.dart';
import 'package:commet/ui/pages/login/login_page.dart';
import 'package:commet/ui/pages/settings/categories/account/account_management_tab.dart';
import 'package:commet/ui/pages/settings/categories/account/settings_category_account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:commet/main.dart';
import 'package:hive/hive.dart';
import 'package:integration_test/integration_test.dart';

import '../extensions/wait_for.dart';
import '../extensions/common_flows.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Add New Account', (WidgetTester tester) async {
    await tester.clearUserData();
    // Build our app and trigger a frame.
    var app = App();
    await tester.pumpWidget(app);
    await tester.login(app);

    await tester.waitFor(() => app.clientManager.isLoggedIn(),
        timeout: const Duration(seconds: 5), skipPumpAndSettle: true);

    await tester.openSettings(app);

    await tester.waitFor(() => find
        .widgetWithText(tiamat.TextButton, T.current.settingsTabManageAccounts)
        .evaluate()
        .isNotEmpty);

    await tester.tap(find.widgetWithText(
        tiamat.TextButton, T.current.settingsTabManageAccounts));

    await tester.waitFor(() => find
        .byKey(AccountManagementSettingsTab.addAccountKey)
        .evaluate()
        .isNotEmpty);

    await tester.tap(find.byKey(AccountManagementSettingsTab.addAccountKey));

    await tester.loginUser2(app);

    await tester.pumpAndSettle();

    expect(app.clientManager.clients.length, equals(2));
    expect(
        app.clientManager.clients
            .where((client) =>
                client.user!.identifier.contains(tester.userTwoName))
            .isNotEmpty,
        isTrue);

    await app.clientManager.close();
    await tester.clean();
  });

  testWidgets('Try Add Same Account Twice', (WidgetTester tester) async {
    await tester.clearUserData();
    // Build our app and trigger a frame.
    var app = App();
    await tester.pumpWidget(app);
    await tester.login(app);

    await tester.waitFor(() => app.clientManager.isLoggedIn(),
        timeout: const Duration(seconds: 5), skipPumpAndSettle: true);

    await tester.openSettings(app);

    await tester.waitFor(() => find
        .widgetWithText(tiamat.TextButton, T.current.settingsTabManageAccounts)
        .evaluate()
        .isNotEmpty);

    await tester.tap(find.widgetWithText(
        tiamat.TextButton, T.current.settingsTabManageAccounts));

    await tester.waitFor(() => find
        .byKey(AccountManagementSettingsTab.addAccountKey)
        .evaluate()
        .isNotEmpty);

    await tester.tap(find.byKey(AccountManagementSettingsTab.addAccountKey));

    await tester.login(app);

    await tester.waitFor(() => find
        .text(T.current.loginResultAlreadyLoggedInMessage)
        .evaluate()
        .isNotEmpty);

    expect(app.clientManager.clients.length, equals(1));

    await app.clientManager.close();
    await tester.clean();
  });
}
