import 'dart:async';
import 'dart:math';

import 'package:commet/client/client.dart';
import 'package:commet/utils/union.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

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
  StreamController<void> onUpdate = StreamController.broadcast();

  @override
  Union<Room> rooms = Union();

  @override
  Key key = UniqueKey();

  SimulatedSpace(this.displayName, this.client) {
    identifier = getRandomString(20);
    notificationCount = 1;

    var images = [
      "assets/images/placeholder/generic/checker_green.png",
      "assets/images/placeholder/generic/checker_purple.png",
      "assets/images/placeholder/generic/checker_orange.png"
    ];

    var placeholderImageIndex = Random().nextInt(images.length);

    avatar = AssetImage(images[placeholderImageIndex]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Space) return false;

    return identifier == other.identifier;
  }

  @override
  int get hashCode => identifier.hashCode;

  static const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final Random _rnd = Random();

  String getRandomString(int length) =>
      String.fromCharCodes(Iterable.generate(length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
}
