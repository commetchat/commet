import 'dart:math';

import 'package:commet/client/simulated/simulated_peer.dart';
import 'package:commet/client/simulated/simulated_timeline.dart';
import 'package:flutter/painting.dart';

import '../client.dart';
import 'package:matrix/matrix.dart' as matrix;

class SimulatedSpace implements Space {
  @override
  late Client client;

  @override
  late String identifier;

  @override
  ImageProvider? avatar;

  @override
  late String displayName;

  @override
  int notificationCount = 0;

  @override
  List<Room> rooms = List.empty(growable: true);

  SimulatedSpace(this.displayName, this.client) {
    identifier = getRandomString(20);
    notificationCount = 1;
  }

  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final Random _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
}
