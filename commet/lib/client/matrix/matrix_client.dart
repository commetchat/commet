import 'dart:async';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:flutter/src/widgets/async.dart';
import '../client.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixClient implements Client {
  @override
  late List<Room> _rooms;

  @override
  List<Room> get rooms => _rooms;

  late matrix.Client _client;

  @override
  late StreamController<void> onSync;

  @override
  late StreamController<void> onRoomListUpdated;

  MatrixClient() {
    log("Creating matrix client");
    _client = matrix.Client(
      'Commet',
      /*databaseBuilder: (_) async {
        final dir = await getApplicationSupportDirectory();
        final db = matrix.HiveCollectionsDatabase('matrix_commet.', dir.path);
        await db.open();
        return db;
      },*/
    );

    _rooms = List.empty(growable: true);

    onSync = StreamController<void>();
    onRoomListUpdated = StreamController<void>();

    _client.onSync.stream
        .listen((event) => {log("On Sync Happened?"), onSync.add(null)});

    log("Done!");
  }

  void log(String s) {
    print('Matrix Client] $s');
  }

  @override
  Future<void> init() {
    log("Initialising client");
    return _client.init();
  }

  @override
  bool isLoggedIn() => _client.isLogged();

  @override
  Future<LoginResult> login(
      LoginType type, String userIdentifier, String server,
      {String? password, String? token}) async {
    LoginResult loginResult = LoginResult.error;

    log("Attempting to log in!");

    switch (type) {
      case LoginType.loginPassword:
        await _client.checkHomeserver((Uri.https((server))));
        var result = await _client.login(matrix.LoginType.mLoginPassword,
            password: password,
            identifier:
                matrix.AuthenticationUserIdentifier(user: userIdentifier));

        loginResult = LoginResult.success;

        break;
      case LoginType.token:
        // TODO: Handle this case.
        break;
    }

    switch (loginResult) {
      case LoginResult.success:
        log("Login success!");
        _postLoginSuccess();
        break;
    }

    return loginResult;
  }

  @override
  Future<void> logout() {
    return _client.logout();
  }

  void _postLoginSuccess() {
    _updateRoomslist();
  }

  void _updateRoomslist() {
    var rooms = _client.rooms;
    bool updated = false;
    //Add rooms that dont exist in the list
    for (var room in rooms) {
      if (!_rooms.any((element) => element.identifier == room.id)) {
        _rooms.add(MatrixRoom(
          this,
          room,
          _client,
        ));
        updated = true;
      }
    }

    //Remove rooms that no longer exist in the list
    for (var room in _rooms
        .where((element) => !rooms.any((r) => element.identifier == r.id))) {
      _rooms.remove(room);
      updated = true;
    }

    for (var room in _rooms) {
      log(room.identifier);
    }

    if (updated) onRoomListUpdated.add(null);
  }
}
