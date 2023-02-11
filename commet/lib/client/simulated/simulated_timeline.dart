import 'dart:async';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:flutter/src/widgets/async.dart';
import '../client.dart';

class SimulatedTimeline implements Timeline {
  @override
  late List<TimelineEvent> events;

  SimulatedTimeline() {
    events = List.empty(growable: true);
  }

  @override
  Future<int> loadMoreHistory() {
    // TODO: implement loadMoreHistory
    throw UnimplementedError();
  }
}
