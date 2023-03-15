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
import '../extensions/wait_for.dart';
import '../extensions/common_flows.dart';

void main() {
  testWidgets('Test emoji verification started from another device', (WidgetTester tester) async {
    var hs = const String.fromEnvironment('HOMESERVER');
    var username = const String.fromEnvironment('USER1_NAME');
    var password = const String.fromEnvironment('USER1_PW');

    // Adding a bunch of delays to not trigger M_LIMIT_EXCEEDED: Too Many Requests
    // Also helps avoid some errors with lock files when cleaning user data;
    await Future.delayed(const Duration(seconds: 1));
    await tester.clearUserData();

    var app = App();

    await tester.pumpAndSettle();

    await tester.login(app);

    await tester.pumpAndSettle();

    final dir = await getApplicationSupportDirectory();
    var path = p.join(dir.path, "matrix") + p.separator;

    var otherClient = Client(
      'Commet Test',
      verificationMethods: {KeyVerificationMethod.emoji},
      supportedLoginTypes: {AuthenticationTypes.password},
      logLevel: Level.verbose,
      databaseBuilder: (_) async {
        final db = HiveCollectionsDatabase('test.commet.app', path);
        await db.open();
        return db;
      },
    );

    var uri = Uri.http(hs);
    await otherClient.checkHomeserver(uri);
    await otherClient.init();
    var result = await otherClient.login(LoginType.mLoginPassword,
        password: password, identifier: AuthenticationUserIdentifier(user: username));

    expect(result.accessToken, isNotNull);

    var matrixClient = (app.clientManager.getClients()[0] as MatrixClient);
    var currentDeviceId = matrixClient.getMatrixClient().deviceID!;
    var devices = await otherClient.getDevices();

    var device = devices!.where((element) => (element.deviceId == currentDeviceId)).first;
    var verification = otherClient.userDeviceKeys[otherClient.userID]!.deviceKeys[device.deviceId]!.startVerification();

    verification.onUpdate = () {};

    await tester.waitFor(() => find.byType(MatrixVerificationPage).evaluate().isNotEmpty);

    await tester.pumpAndSettle();

    var button = find.widgetWithText(ElevatedButton, T.current.genericAcceptButton);
    await tester.tap(button);

    await tester.waitFor(
        () => find.widgetWithText(ElevatedButton, T.current.sasEmojiVerificationMatches).evaluate().isNotEmpty);

    await tester.pumpAndSettle();

    button = find.widgetWithText(ElevatedButton, T.current.sasEmojiVerificationMatches);

    await tester.tap(button);

    await verification.acceptSas();

    await tester
        .waitFor(() => find.widgetWithText(ElevatedButton, T.current.sasVerificationDone).evaluate().isNotEmpty);

    await tester.pumpAndSettle();

    expect(verification.isDone, equals(true));
    expect(verification.state, equals(KeyVerificationState.done));

    var client = matrixClient.getMatrixClient();

    expect(client.userDeviceKeys[client.userID]!.deviceKeys[otherClient.deviceID!]!.verified, equals(true));
    expect(otherClient.userDeviceKeys[otherClient.userID]!.deviceKeys[client.deviceID!]!.verified, equals(true));

    await otherClient.logout();
    await otherClient.clear();
  });

  testWidgets('Test Rejecting emoji verification started from another device', (WidgetTester tester) async {
    var hs = const String.fromEnvironment('HOMESERVER');
    var username = const String.fromEnvironment('USER1_NAME');
    var password = const String.fromEnvironment('USER1_PW');

    // Adding a bunch of delays to not trigger M_LIMIT_EXCEEDED: Too Many Requests
    // Also helps avoid some errors with lock files when cleaning user data;
    await Future.delayed(const Duration(seconds: 1));
    await tester.clearUserData();

    var app = App();

    await tester.pumpAndSettle();

    await tester.login(app);

    await tester.pumpAndSettle();

    final dir = await getApplicationSupportDirectory();
    var path = p.join(dir.path, "matrix") + p.separator;

    var otherClient = Client(
      'Commet Test',
      verificationMethods: {KeyVerificationMethod.emoji},
      supportedLoginTypes: {AuthenticationTypes.password},
      logLevel: Level.verbose,
      databaseBuilder: (_) async {
        final db = HiveCollectionsDatabase('test.commet.app', path);
        await db.open();
        return db;
      },
    );

    var uri = Uri.http(hs);
    await otherClient.checkHomeserver(uri);
    await otherClient.init();
    var result = await otherClient.login(LoginType.mLoginPassword,
        password: password, identifier: AuthenticationUserIdentifier(user: username));

    expect(result.accessToken, isNotNull);

    var matrixClient = (app.clientManager.getClients()[0] as MatrixClient);
    var currentDeviceId = matrixClient.getMatrixClient().deviceID!;
    var devices = await otherClient.getDevices();

    var device = devices!.where((element) => (element.deviceId == currentDeviceId)).first;
    var verification = otherClient.userDeviceKeys[otherClient.userID]!.deviceKeys[device.deviceId]!.startVerification();

    verification.onUpdate = () {};

    await tester.waitFor(() => find.byType(MatrixVerificationPage).evaluate().isNotEmpty);

    await tester.pumpAndSettle();

    var button = find.widgetWithText(ElevatedButton, T.current.genericRejectButton);
    await tester.tap(button);
    await tester.waitFor(() => verification.state == KeyVerificationState.error);

    expect(verification.canceled, equals(true));
    expect(verification.state, equals(KeyVerificationState.error));

    var client = matrixClient.getMatrixClient();

    expect(client.userDeviceKeys[client.userID]!.deviceKeys[otherClient.deviceID!]!.verified, equals(false));
    expect(otherClient.userDeviceKeys[otherClient.userID]!.deviceKeys[client.deviceID!]!.verified, equals(false));

    await otherClient.logout();
    await otherClient.clear();
  });

  testWidgets('Test emoji dont match started from another device', (WidgetTester tester) async {
    var hs = const String.fromEnvironment('HOMESERVER');
    var username = const String.fromEnvironment('USER1_NAME');
    var password = const String.fromEnvironment('USER1_PW');

    // Adding a bunch of delays to not trigger M_LIMIT_EXCEEDED: Too Many Requests
    // Also helps avoid some errors with lock files when cleaning user data;
    await Future.delayed(const Duration(seconds: 1));
    await tester.clearUserData();

    var app = App();

    await tester.pumpAndSettle();

    await tester.login(app);

    await tester.pumpAndSettle();

    final dir = await getApplicationSupportDirectory();
    var path = p.join(dir.path, "matrix") + p.separator;

    var otherClient = Client(
      'Commet Test',
      verificationMethods: {KeyVerificationMethod.emoji},
      supportedLoginTypes: {AuthenticationTypes.password},
      logLevel: Level.verbose,
      databaseBuilder: (_) async {
        final db = HiveCollectionsDatabase('test.commet.app', path);
        await db.open();
        return db;
      },
    );

    var uri = Uri.http(hs);
    await otherClient.checkHomeserver(uri);
    await otherClient.init();
    var result = await otherClient.login(LoginType.mLoginPassword,
        password: password, identifier: AuthenticationUserIdentifier(user: username));

    expect(result.accessToken, isNotNull);

    var matrixClient = (app.clientManager.getClients()[0] as MatrixClient);
    var currentDeviceId = matrixClient.getMatrixClient().deviceID!;
    var devices = await otherClient.getDevices();

    var device = devices!.where((element) => (element.deviceId == currentDeviceId)).first;
    var verification = otherClient.userDeviceKeys[otherClient.userID]!.deviceKeys[device.deviceId]!.startVerification();

    verification.onUpdate = () {};

    await tester.waitFor(() => find.byType(MatrixVerificationPage).evaluate().isNotEmpty);

    await tester.pumpAndSettle();

    var button = find.widgetWithText(ElevatedButton, T.current.genericAcceptButton);
    await tester.tap(button);

    await tester.waitFor(
        () => find.widgetWithText(ElevatedButton, T.current.sasEmojiVerificationDoesntMatch).evaluate().isNotEmpty);

    await tester.pumpAndSettle();

    button = find.widgetWithText(ElevatedButton, T.current.sasEmojiVerificationDoesntMatch);

    await tester.tap(button);

    await tester.waitFor(() => verification.state == KeyVerificationState.error);

    expect(verification.isDone, equals(true));
    expect(verification.state, equals(KeyVerificationState.error));

    var client = matrixClient.getMatrixClient();

    expect(client.userDeviceKeys[client.userID]!.deviceKeys[otherClient.deviceID!]!.verified, equals(false));
    expect(otherClient.userDeviceKeys[otherClient.userID]!.deviceKeys[client.deviceID!]!.verified, equals(false));

    await otherClient.logout();
    await otherClient.clear();
  });
}
