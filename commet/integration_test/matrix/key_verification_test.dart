import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/generated/l10n.dart';
import 'package:commet/ui/pages/matrix/verification/matrix_verification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:commet/main.dart';
import 'package:matrix/encryption/utils/key_verification.dart';
import '../extensions/wait_for.dart';
import '../extensions/common_flows.dart';

void main() {
  testWidgets('Test emoji verification started from another device',
      (WidgetTester tester) async {
    var app = await tester.setupApp();
    await tester.pumpWidget(app);
    await tester.login(app);

    var matrixClient = (app.clientManager.clients[0] as MatrixClient);

    var otherClient = await tester.createTestClient();

    var client = matrixClient.getMatrixClient();

    var devices = await otherClient.getDevices();
    var device =
        devices!.firstWhere((element) => element.deviceId == client.deviceID);
    expect(device, isNotNull);

    var verification = otherClient
        .userDeviceKeys[otherClient.userID]!.deviceKeys[device.deviceId]!
        .startVerification();
    verification.onUpdate = () {};

    await tester.waitFor(
        () => find.byType(MatrixVerificationPage).evaluate().isNotEmpty);

    await tester.pumpAndSettle();

    var button =
        find.widgetWithText(ElevatedButton, T.current.genericAcceptButton);
    await tester.tap(button);

    await tester.waitFor(() => find
        .widgetWithText(ElevatedButton, T.current.sasEmojiVerificationMatches)
        .evaluate()
        .isNotEmpty);

    await tester.pumpAndSettle();

    button = find.widgetWithText(
        ElevatedButton, T.current.sasEmojiVerificationMatches);

    await tester.tap(button);

    await verification.acceptSas();

    await tester.waitFor(() => find
        .widgetWithText(ElevatedButton, T.current.sasVerificationDone)
        .evaluate()
        .isNotEmpty);

    await tester.pumpAndSettle();

    expect(verification.isDone, equals(true));
    expect(verification.state, equals(KeyVerificationState.done));

    expect(
        client.userDeviceKeys[client.userID]!.deviceKeys[otherClient.deviceID!],
        isNotNull);
    expect(
        otherClient
            .userDeviceKeys[otherClient.userID]!.deviceKeys[client.deviceID!],
        isNotNull);

    await app.clientManager.close();
    await otherClient.dispose();
    await tester.clean();
  });
}
