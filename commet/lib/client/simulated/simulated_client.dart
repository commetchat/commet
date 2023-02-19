import 'dart:async';
import 'package:commet/client/client.dart';
import 'package:commet/client/simulated/simulated_peer.dart';
import 'package:commet/client/simulated/simulated_room.dart';
import 'package:commet/client/simulated/simulated_space.dart';
import 'package:commet/utils/rng.dart';
import 'package:flutter/material.dart';

class SimulatedClient extends Client {
  bool _isLogged = false;

  SimulatedClient() : super(RandomUtils.getRandomString(20));

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
  Future<LoginResult> login(LoginType type, String userIdentifier, String server,
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

    user = SimulatedPeer(
        this, "simulated@example.com", "Simulated", AssetImage("assets/images/placeholder/generic/checker_red.png"));
  }

  void _updateRoomslist() {
    addRoom(SimulatedRoom("Simulated Room", this));
    addRoom(SimulatedRoom("Simulated Room 2", this));
    addRoom(SimulatedRoom("Simulated Room 3", this));
    addRoom(SimulatedRoom("Simulated Room 4", this));
    addRoom(SimulatedRoom("Simulated Room 5", this));
    addRoom(SimulatedRoom("Simulated Room 6", this));
    addRoom(SimulatedRoom("Simulated Room 7", this));
  }

  void _updateSpacesList() {
    List<Space> _spaces = List.empty(growable: true);

    addSpace(SimulatedSpace("Simulated Space 1", this));
    addSpace(SimulatedSpace("Simulated Space 2", this));
    addSpace(SimulatedSpace("Simulated Space 3", this));

    Future.delayed(const Duration(seconds: 10), () {
      List<Space> _spaces = List.empty(growable: true);
      addSpace(SimulatedSpace("Simulated Space 4", this));
      addSpace(SimulatedSpace("Simulated Space 5", this));
    });
  }
}
