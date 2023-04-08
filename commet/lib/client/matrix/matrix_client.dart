import 'dart:async';
import 'dart:io';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/matrix/matrix_room_preview.dart';
import 'package:commet/client/preview_data.dart';
import 'package:commet/config/app_config.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/loading/loading_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

import '../../ui/pages/matrix/verification/matrix_verification_page.dart';
import 'matrix_room.dart';
import 'matrix_space.dart';

class MatrixClient extends Client {
  late matrix.Client _matrixClient;

  MatrixClient({String? name}) : super(RandomUtils.getRandomString(20)) {
    if (name != null) {
      _matrixClient = _createMatrixClient(name);
    }
  }

  static String hash(String name) {
    var bytes = utf8.encode(name);
    var hash = sha256.convert(bytes);
    return hash.toString();
  }

  static Future<void> loadFromDB(ClientManager manager) async {
    var clients = preferences.getRegisteredMatrixClients();

    if (clients != null) {
      for (var clientName in clients) {
        var client = MatrixClient(name: clientName);
        manager.addClient(client);
        await client.init();
      }
    }
  }

  static matrix.NativeImplementations get nativeImplementations =>
      BuildConfig.WEB ? const matrix.NativeImplementationsDummy() : matrix.NativeImplementationsIsolate(compute);

  @override
  Future<void> init() async {
    if (!_matrixClient.isLogged()) {
      await _matrixClient.init();
      user = MatrixPeer(_matrixClient, _matrixClient.userID!);
      addPeer(user!);
    }

    _matrixClient.onSync.stream.listen((event) => {onSync.add(null), _updateRoomslist(), _updateSpacesList()});

    _updateRoomslist();
    _updateSpacesList();

    print(_matrixClient.deviceID);

    _matrixClient.onKeyVerificationRequest.stream.listen((event) {
      PopupDialog.show(navigator.currentContext!,
          content: MatrixVerificationPage(request: event), title: "Verification Request");
    });
  }

  @override
  bool isLoggedIn() => _matrixClient.isLogged();

  matrix.Client _createMatrixClient(String name) {
    return matrix.Client(
      name,
      verificationMethods: {KeyVerificationMethod.emoji, KeyVerificationMethod.numbers},
      supportedLoginTypes: {matrix.AuthenticationTypes.password},
      nativeImplementations: nativeImplementations,
      logLevel: BuildConfig.RELEASE ? matrix.Level.warning : matrix.Level.verbose,
      databaseBuilder: (client) async {
        print(await AppConfig.getDatabasePath());
        final db = matrix.HiveCollectionsDatabase(client.clientName, await AppConfig.getDatabasePath());
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

    String name = hash("matrix_client-${DateTime.now().millisecondsSinceEpoch}");

    switch (type) {
      case LoginType.loginPassword:
        var uri = Uri.https(server);
        if (server == "localhost") uri = Uri.http(server);

        _matrixClient = _createMatrixClient(name);

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
      preferences.addRegisteredMatrixClient(name);
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

  @override
  Future<Room> createRoom(String name, RoomVisibility visibility) async {
    var id = await _matrixClient.createRoom(
        name: name,
        visibility: visibility == RoomVisibility.private ? matrix.Visibility.private : matrix.Visibility.public);
    if (roomExists(id)) return getRoom(id)!;
    var room = MatrixRoom(this, _matrixClient.getRoomById(id)!, _matrixClient);
    addRoom(room);
    return room;
  }

  @override
  Future<Space> createSpace(String name, RoomVisibility visibility) async {
    var id = await _matrixClient.createSpace(
        name: name,
        waitForSync: true,
        visibility: visibility == RoomVisibility.private ? matrix.Visibility.private : matrix.Visibility.public);

    if (spaceExists(id)) return getSpace(id)!;
    var space = MatrixSpace(this, _matrixClient.getRoomById(id)!, _matrixClient);
    addSpace(space);
    return space;
  }

  @override
  Future<Space> joinSpace(String address) async {
    var response = await _matrixClient.getRoomIdByAlias(address);
    var state = await _matrixClient.getRoomState(response.roomId!);
    var preview = await getRoomPreview(address);

    var id = await _matrixClient.joinRoom(address);
    await _matrixClient.waitForRoomInSync(id);
    if (spaceExists(id)) return getSpace(id)!;

    var space = MatrixSpace(this, _matrixClient.getRoomById(id)!, _matrixClient);
    addSpace(space);
    return space;
  }

  @override
  Future<PreviewData?> getRoomPreviewInternal(String address) async {
    MatrixRoomPreview preview = MatrixRoomPreview(roomId: address, matrixClient: _matrixClient);
    if (preview.exists) {
      return preview;
    }
    return null;
  }

  @override
  Future<PreviewData?> getSpacePreviewInternal(String address) {
    return getRoomPreviewInternal(address);
  }

  @override
  Future<Room> joinRoom(String address) async {
    var id = await _matrixClient.joinRoom(address);
    _matrixClient.waitForRoomInSync(id);
    if (roomExists(id)) return getRoom(id)!;

    var room = MatrixRoom(this, _matrixClient.getRoomById(id)!, _matrixClient);
    addRoom(room);
    return room;
  }

  @override
  Future<void> close() async {
    await _matrixClient.dispose();
    await super.close();
  }
}
