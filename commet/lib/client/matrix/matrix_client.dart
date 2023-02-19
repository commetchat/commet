import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/utils/union.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:path_provider/path_provider.dart';

import 'matrix_room.dart';
import 'matrix_space.dart';

class MatrixClient implements Client {
  @override
  late StreamController<void> onSync = StreamController.broadcast();

  @override
  Union<Room> rooms = Union<Room>();

  @override
  Union<Space> spaces = Union<Space>();

  late matrix.Client _client;

  MatrixClient() {
    log("Creating matrix client");
    _client = matrix.Client(
      'Commet',
      databaseBuilder: (_) async {
        final dir = await getApplicationSupportDirectory();
        final db = matrix.HiveCollectionsDatabase('matrix_commet.', dir.path);
        await db.open();
        return db;
      },
    );

    _client.onSync.stream
        .listen((event) => {log("On Sync Happened?"), onSync.add(null), _updateRoomslist(), _updateSpacesList()});

    log("Done!");
  }

  void log(String s) {
    print('Matrix Client] $s');
  }

  @override
  Future<void> init() async {
    log("Initialising client");
    var result = await _client.init();
    _updateRoomslist();
    _updateSpacesList();
    return result;
  }

  @override
  bool isLoggedIn() => _client.isLogged();

  @override
  Future<LoginResult> login(LoginType type, String userIdentifier, String server,
      {String? password, String? token}) async {
    LoginResult loginResult = LoginResult.error;

    log("Attempting to log in!");

    switch (type) {
      case LoginType.loginPassword:
        await _client.checkHomeserver((Uri.https((server))));
        var result = await _client.login(matrix.LoginType.mLoginPassword,
            password: password, identifier: matrix.AuthenticationUserIdentifier(user: userIdentifier));

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
    var all_rooms = _client.rooms.where((element) => !element.isSpace);
    List<Room> new_rooms = List.empty(growable: true);

    for (var room in all_rooms) {
      var r = MatrixRoom(this, room, _client);
      new_rooms.add(r);
    }

    rooms.addItems(new_rooms);
  }

  void _updateSpacesList() {
    var rooms = _client.rooms.where((element) => element.isSpace);
    List<Space> new_spaces = List.empty(growable: true);

    for (var room in rooms) {
      var r = MatrixSpace(this, room, _client);
      new_spaces.add(r);
    }

    spaces.addItems(new_spaces);
  }
}
