import 'dart:async';
import 'dart:io';
import 'package:commet/client/client_manager.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/matrix/verification/matrix_verification_page.dart';
import 'package:flutter/foundation.dart';

import 'package:path/path.dart' as p;

import 'package:crypto/crypto.dart';
import 'dart:convert'; // for the utf8.encode method

import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/utils/rng.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:matrix/encryption.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tiamat/tiamat.dart';

import 'matrix_room.dart';
import 'matrix_space.dart';

class MatrixClient extends Client {
  late matrix.Client _matrixClient;

  MatrixClient({String? databasePath}) : super(RandomUtils.getRandomString(20)) {
    if (databasePath != null) {
      _matrixClient = _createMatrixClient(databasePath);
    }
  }

  static Future<String> getDBPath() async {
    final dir = await getApplicationSupportDirectory();
    var path = p.join(dir.path, "matrix") + p.separator;
    return path;
  }

  static Future<String> getDBPathWithName(String userName) async {
    final dir = await getDBPath();
    var path = p.join(dir, userName, "data");
    path += p.separator;
    return path;
  }

  static Future<void> loadFromDB(ClientManager manager) async {
    var dir = Directory(await getDBPath());

    if (!await dir.exists()) return;

    var subdirs = await dir.list().toList();

    for (var subdir in subdirs) {
      var databasePath = await getDBPathWithName(p.basename(subdir.absolute.path));
      var client = MatrixClient(databasePath: databasePath);
      manager.addClient(client);
      await client.init();
    }
  }

  static matrix.NativeImplementations get nativeImplementations =>
      BuildConfig.WEB ? const matrix.NativeImplementationsDummy() : matrix.NativeImplementationsIsolate(compute);

  @override
  Future<void> init() async {
    if (!_matrixClient.isLogged()) {
      await _matrixClient.init();
      if (_matrixClient.userID != null) user = MatrixPeer(_matrixClient, _matrixClient.userID!);
    }

    _matrixClient.onSync.stream.listen((event) => {onSync.add(null), _updateRoomslist(), _updateSpacesList()});

    _updateRoomslist();
    _updateSpacesList();

    _matrixClient.onKeyVerificationRequest.stream.listen((event) {
      PopupDialog.show(navigator.currentContext!,
          content: MatrixVerificationPage(
            request: event,
            client: _matrixClient,
          ),
          title: "Verification Request");
    });
  }

  @override
  bool isLoggedIn() => _matrixClient.isLogged();

  matrix.Client _createMatrixClient(String databasePath) {
    return matrix.Client(
      'Commet',
      verificationMethods: {KeyVerificationMethod.emoji, KeyVerificationMethod.numbers},
      supportedLoginTypes: {matrix.AuthenticationTypes.password},
      nativeImplementations: nativeImplementations,
      logLevel: BuildConfig.RELEASE ? matrix.Level.warning : matrix.Level.verbose,
      databaseBuilder: (_) async {
        final db = matrix.HiveCollectionsDatabase('chat.commet.app', databasePath);
        await db.open();
        return db;
      },
    );
  }

  matrix.Client getMatrixClient() {
    return _matrixClient;
  }

  @override
  Future<LoginResult> login(LoginType type, String userIdentifier, String server,
      {String? password, String? token}) async {
    LoginResult loginResult = LoginResult.error;

    switch (type) {
      case LoginType.loginPassword:
        var uri = Uri.https(server);
        if (server == "localhost") uri = Uri.http(server);

        var name = 'matrix_$userIdentifier@$server';
        var bytes = utf8.encode(name);
        var hash = sha256.convert(bytes);
        name = hash.toString();
        final dir = await getDBPathWithName(name);

        _matrixClient = _createMatrixClient(dir);

        await _matrixClient.checkHomeserver(uri);

        try {
          var result = await _matrixClient.login(matrix.LoginType.mLoginPassword,
              initialDeviceDisplayName: BuildConfig.appName,
              password: password,
              identifier: matrix.AuthenticationUserIdentifier(user: userIdentifier));
          if (result.accessToken != null) {
            loginResult = LoginResult.success;
          } else {
            loginResult = LoginResult.failed;
          }
        } catch (_) {
          loginResult = LoginResult.failed;
        }

        break;
      case LoginType.token:
        break;
    }

    if (loginResult == LoginResult.success) {
      _postLoginSuccess();
    } else {
      _matrixClient.clearArchivesFromCache();
      _matrixClient.clear();
      _matrixClient.database?.close();
      _matrixClient.database?.clear();
    }

    return loginResult;
  }

  @override
  Future<void> logout() {
    return _matrixClient.logout();
  }

  void _postLoginSuccess() {
    if (_matrixClient.userID != null) user = MatrixPeer(_matrixClient, _matrixClient.userID!);
  }

  void _updateRoomslist() {
    var allRooms = _matrixClient.rooms.where((element) => !element.isSpace);

    for (var room in allRooms) {
      if (roomExists(room.id)) continue;

      addRoom(MatrixRoom(this, room, _matrixClient));
    }
  }

  void _updateSpacesList() {
    var allSpaces = _matrixClient.rooms.where((element) => element.isSpace);

    for (var space in allSpaces) {
      if (spaceExists(space.id)) continue;

      addSpace(MatrixSpace(this, space, _matrixClient));
    }
  }
}
