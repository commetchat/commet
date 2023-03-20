import 'dart:convert';
import 'dart:io';

import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/generated/l10n.dart';
import 'package:commet/ui/pages/matrix/verification/matrix_verification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:commet/main.dart';
import 'package:matrix/encryption/utils/key_verification.dart';
import 'package:matrix/matrix.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../extensions/subprocess.dart';
import '../extensions/wait_for.dart';
import '../extensions/common_flows.dart';

void main() {
  testWidgets('Test emoji verification started from another device', (WidgetTester tester) async {
    var hs = const String.fromEnvironment('HOMESERVER', defaultValue: "localhost");
    var username = const String.fromEnvironment('USER1_NAME', defaultValue: "alice");
    var password = const String.fromEnvironment('USER1_PW', defaultValue: "AliceInWonderland");

    // Adding a bunch of delays to not trigger M_LIMIT_EXCEEDED: Too Many Requests
    // Also helps avoid some errors with lock files when cleaning user data;
    await tester.clearUserData();

    var app = App();
    await tester.pumpWidget(app);
    await tester.login(app);

    var matrixClient = (app.clientManager.getClients()[0] as MatrixClient);

    var proc = await IntegrationTestSubprocess.verifyMeWithEmoji(matrixClient.getMatrixClient().deviceID!);

    await Future.delayed(const Duration(seconds: 1));

    await tester.waitFor(() => find.byType(MatrixVerificationPage).evaluate().isNotEmpty);

    await tester.pumpAndSettle();

    var button = find.widgetWithText(ElevatedButton, T.current.genericAcceptButton);
    await tester.tap(button);

    await tester.waitFor(
        () => find.widgetWithText(ElevatedButton, T.current.sasEmojiVerificationMatches).evaluate().isNotEmpty);

    await tester.pumpAndSettle();

    button = find.widgetWithText(ElevatedButton, T.current.sasEmojiVerificationMatches);

    await tester.tap(button);

    await tester
        .waitFor(() => find.widgetWithText(ElevatedButton, T.current.sasVerificationDone).evaluate().isNotEmpty);

    await tester.pumpAndSettle();

    var client = matrixClient.getMatrixClient();

    proc.kill();
    await tester.clean();
  });
}
