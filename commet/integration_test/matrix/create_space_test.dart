import 'package:commet/client/client.dart';
import 'package:commet/ui/molecules/space_selector.dart';
import 'package:commet/ui/pages/get_or_create_room/room_creator.dart';
import 'package:commet/utils/rng.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:commet/main.dart';
import 'package:integration_test/integration_test.dart';

import '../extensions/common_flows.dart';
import '../extensions/wait_for.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import 'package:commet/generated/l10n.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Create Private Space', (WidgetTester tester) async {
    await tester.clearUserData();

    var app = await tester.setupApp();
    await _openMenu(tester, app);
    await _setPrivate(tester);

    String spaceName = "Private Space ${RandomUtils.getRandomString(8)}";
    await _setSpaceName(tester, spaceName);

    var client = app.clientManager.clients.first;
    await _confirmCreateSpace(tester, client, spaceName);

    expect(client.spaces.any((element) => element.displayName == spaceName),
        isTrue);
    expect(
        client.spaces
            .firstWhere((element) => element.displayName == spaceName)
            .visibility,
        equals(RoomVisibilityPrivate()));

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

    var client = app.clientManager.clients.first;
    await _confirmCreateSpace(tester, client, spaceName);

    expect(client.spaces.any((element) => element.displayName == spaceName),
        isTrue);
    expect(
        client.spaces
            .firstWhere((element) => element.displayName == spaceName)
            .visibility,
        equals(RoomVisibilityPublic()));

    await app.clientManager.close();
    await tester.clean();
  });
}

// The space creation flow is the generic "get or create room" dialog: the
// sidebar's add button opens it with only the Space creator, "Next" opens the
// form (name, topic, visibility), "Create Room!" creates the space.

Future<void> _confirmCreateSpace(
    WidgetTester tester, Client client, String spaceName) async {
  await tester.tap(find
      .widgetWithText(tiamat.Button, T.current.promptConfirmRoomCreation)
      .first);

  // Creating the space is a server round trip followed by a sync; waiting on
  // the space itself is the only reliable signal that the flow is done.
  await tester.waitFor(
      () => client.spaces.any((space) => space.displayName == spaceName),
      timeout: const Duration(seconds: 30));

  await tester.pumpAndSettle();
}

Future<void> _setSpaceName(WidgetTester tester, String spaceName) async {
  // The name field is the first text field of the form, the topic the second.
  // Scoped to the form, since the page behind the dialog has its own fields.
  await tester.enterText(
      find
          .descendant(
              of: find.byType(RoomCreatorWidget),
              matching: find.byType(TextField))
          .first,
      spaceName);
  await tester.pumpAndSettle();
}

Future<void> _setPrivate(WidgetTester tester) async {
  await tester.tap(find.byType(tiamat.DropdownSelector<RoomVisibility?>));

  await tester.pumpAndSettle();

  await tester.tap(find
      .widgetWithText(tiamat.Text, T.current.roomVisibilityPrivateExplanation)
      .last);

  await tester.pumpAndSettle();
}

Future<void> _setPublic(WidgetTester tester) async {
  await tester.tap(find.byType(tiamat.DropdownSelector<RoomVisibility?>));

  await tester.pumpAndSettle();

  await tester.tap(find
      .widgetWithText(tiamat.Text, T.current.roomVisibilityPublicExplanation)
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

  // The dialog opens on "Join Room"; pick the Space creator from the list,
  // then Next opens its form.
  await tester.tap(find
      .widgetWithText(tiamat.TextButton, T.current.labelRoomTypeSpace)
      .first);

  await tester.pumpAndSettle();

  await tester
      .tap(find.widgetWithText(tiamat.Button, T.current.promptNext).first);

  await tester.pumpAndSettle();
}
