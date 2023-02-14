import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:commet/client/room.dart';
import 'package:commet/client/space.dart';

import '../utils/union.dart';

export 'package:commet/client/room.dart';
export 'package:commet/client/space.dart';
export 'package:commet/client/peer.dart';
export 'package:commet/client/timeline.dart';

enum LoginType {
  loginPassword,
  token,
}

enum LoginResult { success, failed, error }

abstract class Client {
  Future<void> init();

  Future<void> logout();

  bool isLoggedIn();

  Future<LoginResult> login(
      LoginType type, String userIdentifier, String server,
      {String? password, String? token});

  Union<Room> rooms = Union<Room>();
  Union<Space> spaces = Union<Space>();

  late StreamController<void> onSync = StreamController.broadcast();
}
