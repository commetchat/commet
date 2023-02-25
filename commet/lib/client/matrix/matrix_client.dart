import 'dart:async';
import 'package:path/path.dart' as p;

import 'package:crypto/crypto.dart';
import 'dart:convert'; // for the utf8.encode method

import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/utils/rng.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:path_provider/path_provider.dart';

import 'matrix_room.dart';
import 'matrix_space.dart';

class MatrixClient extends Client {
  @override
  late StreamController<void> onSync = StreamController.broadcast();

  late matrix.Client _matrixClient;

  MatrixClient() : super(RandomUtils.getRandomString(20)) {
    log("Creating matrix client");
  }

  void log(String s) {
    print('Matrix Client] $s');
  }

  @override
  Future<void> init() async {
    log("Initialising client");
    if (!_matrixClient.isLogged()) {
      await _matrixClient.init();
      if (_matrixClient.userID != null) user = MatrixPeer(_matrixClient, _matrixClient.userID!);
    }

    _matrixClient.onSync.stream
        .listen((event) => {log("On Sync Happened?"), onSync.add(null), _updateRoomslist(), _updateSpacesList()});

    _updateRoomslist();
    _updateSpacesList();
  }

  @override
  bool isLoggedIn() => _matrixClient.isLogged();

  @override
  Future<LoginResult> login(LoginType type, String userIdentifier, String server,
      {String? password, String? token}) async {
    LoginResult loginResult = LoginResult.error;

    log("Attempting to log in!");
    print(type);
    switch (type) {
      case LoginType.loginPassword:
        print("Checking homeserver");

        var uri = Uri.https(server);
        if (server == "localhost") uri = Uri.http(server);

        var name = 'matrix_$userIdentifier@$server';
        var bytes = utf8.encode(name);
        var hash = sha256.convert(bytes);
        name = hash.toString();

        _matrixClient = matrix.Client(
          'Commet',
          databaseBuilder: (_) async {
            final dir = await getApplicationSupportDirectory();
            var path = p.join(dir.path, name, name) + p.separator;
            final db = matrix.HiveCollectionsDatabase('data.', path.toString());
            await db.open();
            return db;
          },
        );

        await _matrixClient.checkHomeserver(uri);

        try {
          var result = await _matrixClient.login(matrix.LoginType.mLoginPassword,
              password: password, identifier: matrix.AuthenticationUserIdentifier(user: userIdentifier));

          loginResult = LoginResult.success;
        } catch (_) {
          loginResult = LoginResult.failed;
        }

        break;
      case LoginType.token:
        // TODO: Handle this case.
        break;
    }

    if (loginResult == LoginResult.success) {
      log("Login success!");
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
