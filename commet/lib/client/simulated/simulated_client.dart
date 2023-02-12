import 'dart:async';
import 'package:commet/client/simulated/simulated_room.dart';
import 'package:commet/client/simulated/simulated_space.dart';
import '../client.dart';

class SimulatedClient implements Client {
  late List<Room> _rooms;

  @override
  List<Space> get spaces => _spaces;

  @override
  List<Room> get rooms => _rooms;

  @override
  late StreamController<void> onSync;

  @override
  late StreamController<void> onRoomListUpdated;

  late final List<Space> _spaces = List.empty(growable: true);

  bool _isLogged = false;

  SimulatedClient() {
    log("Creating simulated client");
    _rooms = List.empty(growable: true);
    onSync = StreamController<void>();
    onRoomListUpdated = StreamController<void>();
    log("Done!");
  }

  void log(String s) {
    print('Matrix Client] $s');
  }

  @override
  Future<void> init() async {
    log("Initialising client");
  }

  @override
  bool isLoggedIn() => _isLogged;

  @override
  Future<LoginResult> login(
      LoginType type, String userIdentifier, String server,
      {String? password, String? token}) async {
    LoginResult loginResult = LoginResult.success;
    _isLogged = true;

    _postLoginSuccess();
    return loginResult;
  }

  @override
  Future<void> logout() async {
    _isLogged = false;
  }

  void _postLoginSuccess() {
    _updateRoomslist();
    _updateSpacesList();
  }

  void _updateRoomslist() {
    _rooms.add(SimulatedRoom("Simulated Room", this));
    _rooms.add(SimulatedRoom("Simulated Room 2", this));
    _rooms.add(SimulatedRoom("Simulated Room 3", this));
    _rooms.add(SimulatedRoom("Simulated Room 4", this));
    _rooms.add(SimulatedRoom("Simulated Room 5", this));

    onRoomListUpdated.add(null);
  }

  void _updateSpacesList() {
    _spaces.add((SimulatedSpace("Simulated Space 1", this)));
    _spaces.add((SimulatedSpace("Simulated Space 2", this)));
    _spaces.add((SimulatedSpace("Simulated Space 3", this)));
  }
}
