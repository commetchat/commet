import 'dart:async';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/client/matrix/extensions/matrix_client_extensions.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/config/app_config.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/pages/matrix/authentication/matrix_uia_request.dart';
import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:flutter/foundation.dart';

import 'package:crypto/crypto.dart';
import 'dart:convert'; // for the utf8.encode method

import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/utils/rng.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:matrix/encryption.dart';

import '../../ui/atoms/code_block.dart';
import '../../ui/pages/matrix/verification/matrix_verification_page.dart';
import 'components/emoticon/matrix_emoticon_component.dart';
import 'components/emoticon/matrix_emoticon_pack.dart';
import 'matrix_room.dart';
import 'matrix_space.dart';

class MatrixClient extends Client {
  late matrix.Client _matrixClient;

  Future? firstSync;
  MatrixEmoticonComponent? _emoticons;

  matrix.ServerConfig? config;

  matrix.NativeImplementations get nativeImplentations => BuildConfig.WEB
      ? const matrix.NativeImplementationsDummy()
      : matrix.NativeImplementationsIsolate(compute);

  MatrixClient({String? name, String? identifier})
      : super(identifier ?? RandomUtils.getRandomString(20)) {
    if (name != null) {
      _matrixClient = _createMatrixClient(name);
    }
  }

  @override
  EmoticonComponent? get emoticons => _emoticons;

  static String hash(String name) {
    var bytes = utf8.encode(name);
    var hash = sha256.convert(bytes);
    return hash.toString();
  }

  @override
  bool get supportsE2EE => true;

  @override
  int? get maxFileSize => config?.mUploadSize;

  static Future<void> loadFromDB(ClientManager manager) async {
    var clients = preferences.getRegisteredMatrixClients();

    List<Future> futures = List.empty(growable: true);

    if (clients != null) {
      for (var clientName in clients) {
        var client = MatrixClient(name: clientName, identifier: clientName);
        try {
          manager.addClient(client);
          futures.add(client.init(true));
        } catch (_) {
          manager.removeClient(client);
          preferences.removeRegisteredMatrixClient(clientName);
        }
      }
    }

    await Future.wait(futures);
  }

  static matrix.NativeImplementations get nativeImplementations =>
      BuildConfig.WEB
          ? const matrix.NativeImplementationsDummy()
          : matrix.NativeImplementationsIsolate(compute);

  @override
  Future<void> init(bool loadingFromCache) async {
    if (!_matrixClient.isLogged()) {
      await _matrixClient.init(
          waitForFirstSync: !loadingFromCache,
          waitUntilLoadCompletedLoaded: true);
      user = MatrixPeer(_matrixClient, _matrixClient.userID!);
      addPeer(user!);

      firstSync = _matrixClient.oneShotSync();
    }

    _matrixClient.getConfig().then((value) {
      config = value;
    });

    _matrixClient.onSync.stream.listen(
        (event) => {onSync.add(null), _updateRoomslist(), _updateSpacesList()});

    _updateRoomslist();
    _updateSpacesList();
    _emoticons =
        MatrixEmoticonComponent(MatrixPersonalEmoticonHelper(this), this);

    _matrixClient.onKeyVerificationRequest.stream.listen((event) {
      AdaptiveDialog.show(navigator.currentContext!,
          builder: (_) => MatrixVerificationPage(request: event),
          title: "Verification Request");
    });

    _matrixClient.onUiaRequest.stream.listen((event) {
      if (event.state == matrix.UiaRequestState.waitForUser) {
        AdaptiveDialog.show(navigator.currentContext!,
            builder: (_) => MatrixUIARequest(event, this),
            title: "Authentication Request");
      }
    });
  }

  @override
  bool isLoggedIn() => _matrixClient.isLogged();

  matrix.Client _createMatrixClient(String name) {
    return matrix.Client(
      name,
      verificationMethods: {
        KeyVerificationMethod.emoji,
        KeyVerificationMethod.numbers
      },
      importantStateEvents: {"im.ponies.room_emotes"},
      supportedLoginTypes: {matrix.AuthenticationTypes.password},
      nativeImplementations: nativeImplementations,
      logLevel:
          BuildConfig.RELEASE ? matrix.Level.warning : matrix.Level.verbose,
      databaseBuilder: (client) async {
        final db = matrix.HiveCollectionsDatabase(
            client.clientName, await AppConfig.getDatabasePath());
        await db.open();
        return db;
      },
    );
  }

  matrix.Client getMatrixClient() {
    return _matrixClient;
  }

  @override
  Future<LoginResult> login(
      LoginType type, String userIdentifier, String server,
      {String? password, String? token}) async {
    LoginResult loginResult = LoginResult.error;

    String name =
        hash("matrix_client-${DateTime.now().millisecondsSinceEpoch}");

    switch (type) {
      case LoginType.loginPassword:
        var uri = Uri.https(server);
        if (server == "localhost") uri = Uri.http(server);

        _matrixClient = _createMatrixClient(name);

        await _matrixClient.checkHomeserver(uri);

        try {
          var result = await _matrixClient.login(
              matrix.LoginType.mLoginPassword,
              initialDeviceDisplayName: BuildConfig.appName,
              password: password,
              identifier:
                  matrix.AuthenticationUserIdentifier(user: userIdentifier));
          if (result.accessToken.isNotEmpty) {
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
    preferences.removeRegisteredMatrixClient(_matrixClient.clientName);
    return _matrixClient.logout();
  }

  void _postLoginSuccess() {
    if (_matrixClient.userID != null) {
      user = MatrixPeer(_matrixClient, _matrixClient.userID!);
    }
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
  Future<Room> createRoom(String name, RoomVisibility visibility,
      {bool enableE2EE = true}) async {
    var id = await _matrixClient.createRoom(
        name: name,
        visibility: visibility == RoomVisibility.private
            ? matrix.Visibility.private
            : matrix.Visibility.public);
    var matrixRoom = _matrixClient.getRoomById(id)!;
    if (enableE2EE) {
      await matrixRoom.enableEncryption();
    }

    if (roomExists(id)) return getRoom(id)!;
    var room = MatrixRoom(this, matrixRoom, _matrixClient);
    addRoom(room);
    return room;
  }

  @override
  Future<Space> createSpace(String name, RoomVisibility visibility) async {
    var id = await _matrixClient.createSpace(
        name: name,
        waitForSync: true,
        visibility: visibility == RoomVisibility.private
            ? matrix.Visibility.private
            : matrix.Visibility.public);

    if (spaceExists(id)) return getSpace(id)!;
    var space =
        MatrixSpace(this, _matrixClient.getRoomById(id)!, _matrixClient);
    addSpace(space);
    return space;
  }

  @override
  Future<Space> joinSpace(String address) async {
    var id = await _matrixClient.joinRoom(address);
    await _matrixClient.waitForRoomInSync(id);
    if (spaceExists(id)) return getSpace(id)!;

    var space =
        MatrixSpace(this, _matrixClient.getRoomById(id)!, _matrixClient);
    addSpace(space);
    return space;
  }

  @override
  Future<RoomPreview?> getRoomPreviewInternal(String address) async {
    return await _matrixClient.getRoomPreview(address);
  }

  @override
  Future<RoomPreview?> getSpacePreviewInternal(String address) {
    return getRoomPreviewInternal(address);
  }

  @override
  Future<Room> joinRoom(String address) async {
    var id = await _matrixClient.joinRoom(address);
    await _matrixClient.waitForRoomInSync(id);
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

  @override
  Future<void> setAvatar(Uint8List bytes, String mimeType) async {
    await _matrixClient.setAvatar(matrix.MatrixImageFile(
        bytes: bytes, name: "avatar", mimeType: mimeType));
    await (user as MatrixPeer).refreshAvatar();
  }

  @override
  Future<void> setDisplayName(String name) async {
    await _matrixClient.setDisplayName(_matrixClient.userID!, name);
    user!.displayName = name;
  }

  @override
  Iterable<Room> getEligibleRoomsForSpace(Space space) {
    return rooms.where((room) => !space.containsRoom(room.identifier));
  }

  @override
  Peer fetchPeerInternal(String identifier) {
    var peer = MatrixPeer(_matrixClient, identifier);
    return peer;
  }

  @override
  Widget buildDebugInfo() {
    var data = _matrixClient.accountData.copy();

    // is this really necessary? i dont know
    for (var event in data.values) {
      if (event.type.startsWith("m.secret_storage.key") ||
          event.type == matrix.EventTypes.SecretStorageDefaultKey ||
          event.type == matrix.EventTypes.MegolmBackup ||
          event.type.startsWith("m.cross_signing")) {
        for (var key in event.content.keys) {
          event.content[key] = "[REDACTED BY COMMET]";
        }
      }
    }

    return SelectionArea(
      child: Codeblock(
        language: "json",
        text: const JsonEncoder.withIndent('  ').convert(data),
      ),
    );
  }
}
