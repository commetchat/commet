import 'package:commet/ui/pages/settings/categories/account/account_management/account_management_tab.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../extensions/wait_for.dart';
import '../extensions/common_flows.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../generated/l10n.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Add New Account', (WidgetTester tester) async {
    await tester.clearUserData();
    // Build our app and trigger a frame.
    var app = await tester.setupApp();
    await tester.pumpWidget(app);
    await tester.login(app);

    await tester.waitFor(() => app.clientManager.isLoggedIn(),
        timeout: const Duration(seconds: 5), skipPumpAndSettle: true);

    await tester.openSettings(app);

    await tester.waitFor(() => find
        .widgetWithText(
            tiamat.TextButton, T.current.labelSettingsTabManageAccounts)
        .evaluate()
        .isNotEmpty);

    await tester.tap(find.widgetWithText(
        tiamat.TextButton, T.current.labelSettingsTabManageAccounts));

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
    var app = await tester.setupApp();
    await tester.pumpWidget(app);
    await tester.login(app);

    await tester.waitFor(() => app.clientManager.isLoggedIn(),
        timeout: const Duration(seconds: 5), skipPumpAndSettle: true);

    await tester.openSettings(app);

    await tester.waitFor(() => find
        .widgetWithText(
            tiamat.TextButton, T.current.labelSettingsTabManageAccounts)
        .evaluate()
        .isNotEmpty);

    await tester.tap(find.widgetWithText(
        tiamat.TextButton, T.current.labelSettingsTabManageAccounts));

    await tester.waitFor(() => find
        .byKey(AccountManagementSettingsTab.addAccountKey)
        .evaluate()
        .isNotEmpty);

    await tester.tap(find.byKey(AccountManagementSettingsTab.addAccountKey));

    await tester.login(app);

    await tester.waitFor(() =>
        find.text(T.current.messageAlreadyLoggedIn).evaluate().isNotEmpty);

    expect(app.clientManager.clients.length, equals(1));

    await app.clientManager.close();
    await tester.clean();
  });
}
