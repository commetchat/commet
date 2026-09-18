import 'package:commet/main.dart';
import 'package:commet/ui/atoms/space_header.dart';
import 'package:commet/ui/atoms/space_icon.dart';
import 'package:commet/ui/molecules/editable_label.dart';
import 'package:commet/ui/organisms/space_summary/space_summary_view.dart';
import 'package:commet/ui/pages/main/main_page.dart';
import 'package:commet/ui/pages/settings/desktop_settings_page.dart';
import 'package:commet/utils/rng.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import '../extensions/common_flows.dart';
import '../extensions/wait_for.dart';
import 'package:commet/generated/l10n.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Change Space Name', (WidgetTester tester) async {
    await tester.clearUserData();
    // Build our app and trigger a frame.
    var app = await tester.setupApp();
    await tester.pumpWidget(app);
    await tester.login(app);

    await _selectSpace(tester, app);

    MainPageState chatPage = tester.state(find.byType(MainPage));
    await tester.waitFor(() => chatPage.currentSpace != null);

    String newName = "New Space Name ${RandomUtils.getRandomString(10)}";
    var space = chatPage.currentSpace!;
    String name = space.displayName;

    expect(name, isNot(newName));

    await _openSpaceSettings(tester);
    await _openSpaceAppearanceSettings(tester);

    await tester.tap(find.widgetWithIcon(tiamat.IconButton, Icons.edit));
    await tester.pumpAndSettle();

    // Scoped to the label being edited: the settings page holds other text
    // fields, and an unscoped finder would match more than one.
    await tester.enterText(
        find.descendant(
            of: find.byType(EditableLabel), matching: find.byType(TextField)),
        newName);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithIcon(tiamat.IconButton, Icons.check));

    await tester.waitFor(() => space.displayName == newName,
        timeout: const Duration(seconds: 30));

    await tester.tap(find.byKey(DesktopSettingsPageState.backButtonKey));

    await tester.pumpAndSettle();

    expect(space.displayName, equals(newName));

    // The header redraws off the space's update stream rather than on the
    // frame after the rename, so give it frames to catch up.
    await tester.waitFor(
        () => find.widgetWithText(SpaceHeader, newName).evaluate().isNotEmpty,
        timeout: const Duration(seconds: 30));

    expect(find.widgetWithText(SpaceHeader, newName), findsWidgets);

    await app.clientManager.close();
    await tester.clean();
  });
}

/// Spaces reach the sidebar over sync, so there is nothing to tap until the
/// first one arrives. Direct messages are drawn with the same widget as spaces,
/// so the icon has to be matched on the space id rather than simply taking the
/// first [SpaceIcon] in the tree.
Future<void> _selectSpace(WidgetTester tester, App app) async {
  await tester.waitFor(() => app.clientManager.spaces.isNotEmpty,
      timeout: const Duration(seconds: 30));

  var space = app.clientManager.spaces.first;

  var icon = find.byWidgetPredicate(
      (widget) => widget is SpaceIcon && widget.spaceId == space.identifier);

  await tester.waitFor(() => icon.evaluate().isNotEmpty);
  await tester.pumpAndSettle();

  await tester.tap(icon.first);
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
