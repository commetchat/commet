import 'dart:math';

import 'package:commet/client/client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

import '../../utils/rng.dart';

class SimulatedSpace extends Space {
  SimulatedSpace(displayName, client) : super(RandomUtils.getRandomString(20), client) {
    notificationCount = 1;
    this.displayName = displayName;

    var images = [
      "assets/images/placeholder/generic/checker_green.png",
      "assets/images/placeholder/generic/checker_purple.png",
      "assets/images/placeholder/generic/checker_orange.png"
    ];
    var placeholderImageIndex = Random().nextInt(images.length);

    avatar = AssetImage(images[placeholderImageIndex]);
  }

  static const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final Random _rnd = Random();

  String getRandomString(int length) =>
      String.fromCharCodes(Iterable.generate(length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
}
