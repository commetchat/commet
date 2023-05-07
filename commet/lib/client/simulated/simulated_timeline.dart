import 'dart:async';
import '../client.dart';

class SimulatedTimeline extends Timeline {
  @override
  Future<void> loadMoreHistory() async {}

  @override
  void markAsRead(TimelineEvent event) {}

  @override
  Iterable<Peer>? get receipts => null;
}
