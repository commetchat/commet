import 'dart:async';
import 'package:commet/client/client.dart';
import 'package:commet/client/simulated/simulated_room.dart';
import 'package:commet/client/simulated/simulated_space.dart';

import '../../utils/union.dart';

class SimulatedClient implements Client {
  @override
  Union<Room> rooms = Union<Room>();

  @override
  Union<Space> spaces = Union<Space>();

  @override
  late StreamController<void> onSync = StreamController.broadcast();
  bool _isLogged = false;

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
    List<Room> _rooms = List.empty(growable: true);
    _rooms.add(SimulatedRoom("Simulated Room", this));
    _rooms.add(SimulatedRoom("Simulated Room 2", this));
    _rooms.add(SimulatedRoom("Simulated Room 3", this));
    _rooms.add(SimulatedRoom("Simulated Room 4", this));
    _rooms.add(SimulatedRoom("Simulated Room 5", this));

    rooms.addItems(_rooms);

    Future.delayed(const Duration(seconds: 10), () {
      print("Adding another space");
    });
  }

  void _updateSpacesList() {
    List<Space> _spaces = List.empty(growable: true);
    _spaces.add((SimulatedSpace("Simulated Space 1", this)));
    _spaces.add((SimulatedSpace("Simulated Space 2", this)));
    _spaces.add((SimulatedSpace("Simulated Space 3", this)));

    spaces.addItems(_spaces);

    Future.delayed(const Duration(seconds: 10), () {
      List<Space> _spaces = List.empty(growable: true);
      _spaces.add((SimulatedSpace("Simulated Space 4", this)));
      _spaces.add((SimulatedSpace("Simulated Space 5", this)));
      spaces.addItems(_spaces);
    });
  }
}
