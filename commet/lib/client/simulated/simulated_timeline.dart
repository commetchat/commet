import 'dart:async';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:flutter/src/widgets/async.dart';
import '../client.dart';

class SimulatedTimeline extends Timeline {
  @override
  Future<int> loadMoreHistory() {
    throw UnimplementedError();
  }
}
