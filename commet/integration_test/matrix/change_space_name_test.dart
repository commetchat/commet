import 'package:commet/ui/atoms/space_header.dart';
import 'package:commet/ui/atoms/space_icon.dart';
import 'package:commet/ui/organisms/space_summary/space_summary_view.dart';
import 'package:commet/ui/pages/chat/chat_page.dart';
import 'package:commet/ui/pages/settings/desktop_settings_page.dart';
import 'package:commet/utils/rng.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
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

    await _selectSpace(tester);
    ChatPageState chatPage = tester.state(find.byType(ChatPage));

    String newName = "New Space Name ${RandomUtils.getRandomString(10)}";
    var space = chatPage.selectedSpace!;
    String name = space.displayName;

    expect(name, isNot(newName));

    await _openSpaceSettings(tester);
    await _openSpaceAppearanceSettings(tester);

    await tester.tap(find.widgetWithIcon(tiamat.IconButton, Icons.edit));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), newName);

    await tester.tap(find.widgetWithIcon(tiamat.IconButton, Icons.check));

    await tester.tap(find.byKey(DesktopSettingsPageState.backButtonKey));

    await tester.pumpAndSettle();

    expect(space.displayName, equals(newName));

    expect(find.widgetWithText(SpaceHeader, newName).evaluate().isNotEmpty,
        isTrue);
  });
}

Future<void> _selectSpace(WidgetTester tester) async {
  await tester.tap(find.byType(SpaceIcon).first);
  await tester.pumpAndSettle();
}

Future<void> _openSpaceSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(SpaceSummaryViewState.spaceSettingsButtonKey));
  await tester.pumpAndSettle();
}

Future<void> _openSpaceAppearanceSettings(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(
      tiamat.TextButton, T.current.labelSpaceAppearanceSettings));
  await tester.pumpAndSettle();
}
