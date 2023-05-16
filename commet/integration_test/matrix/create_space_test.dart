import 'package:commet/client/room.dart';
import 'package:commet/generated/l10n.dart';
import 'package:commet/ui/molecules/space_selector.dart';
import 'package:commet/utils/rng.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:commet/main.dart';
import 'package:integration_test/integration_test.dart';

import '../extensions/common_flows.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Create Private Space', (WidgetTester tester) async {
    await tester.clearUserData();

    var app = await tester.setupApp();
    await _openMenu(tester, app);
    await _setPrivate(tester);

    String spaceName = "Private Space ${RandomUtils.getRandomString(8)}";
    await _setSpaceName(tester, spaceName);
    await _confirmCreateSpace(tester);

    var client = app.clientManager.clients.first;

    expect(client.spaces.any((element) => element.displayName == spaceName),
        isTrue);
    expect(
        client.spaces
            .firstWhere((element) => element.displayName == spaceName)
            .visibility,
        equals(RoomVisibility.invite));

    await app.clientManager.close();
    await tester.clean();
  });

  testWidgets('Create Public Space', (WidgetTester tester) async {
    await tester.clearUserData();

    var app = await tester.setupApp();
    await _openMenu(tester, app);
    await _setPublic(tester);

    String spaceName = "Public Space ${RandomUtils.getRandomString(8)}";
    await _setSpaceName(tester, spaceName);
    await _confirmCreateSpace(tester);

    var client = app.clientManager.clients.first;

    expect(client.spaces.any((element) => element.displayName == spaceName),
        isTrue);
    expect(
        client.spaces
            .firstWhere((element) => element.displayName == spaceName)
            .visibility,
        equals(RoomVisibility.public));

    await app.clientManager.close();
    await tester.clean();
  });
}

Future<void> _confirmCreateSpace(WidgetTester tester) async {
  await tester.tap(find
      .widgetWithText(tiamat.Button, T.current.addSpaceViewCreateSpaceButton)
      .first);

  await tester.pumpAndSettle();
}

Future<void> _setSpaceName(WidgetTester tester, String spaceName) async {
  await tester.enterText(
      find.widgetWithText(
        tiamat.TextInput,
        T.current.spaceNamePrompt,
      ),
      spaceName);
}

Future<void> _setPrivate(WidgetTester tester) async {
  await tester.tap(find.byType(tiamat.DropdownSelector<RoomVisibility>));

  await tester.pumpAndSettle();

  await tester.tap(find
      .widgetWithText(tiamat.Text, T.current.spaceVisibilityPrivateExplanation)
      .last);

  await tester.pumpAndSettle();
}

Future<void> _setPublic(WidgetTester tester) async {
  await tester.tap(find.byType(tiamat.DropdownSelector<RoomVisibility>));

  await tester.pumpAndSettle();

  await tester.tap(find
      .widgetWithText(tiamat.Text, T.current.spaceVisibilityPublicExplanation)
      .last);

  await tester.pumpAndSettle();
}

Future<void> _openMenu(WidgetTester tester, App app) async {
  await tester.pumpWidget(app);

  await tester.login(app);

  await tester.pumpAndSettle();

  await tester.dragUntilVisible(
      find.widgetWithIcon(tiamat.ImageButton, Icons.add),
      find.byType(SpaceSelector),
      const Offset(0, 50));

  await tester.tap(find.widgetWithIcon(tiamat.ImageButton, Icons.add));

  await tester.pumpAndSettle();

  await tester.tap(find.widgetWithText(InkWell, T.current.createNewSpace));

  await tester.pumpAndSettle();
}
