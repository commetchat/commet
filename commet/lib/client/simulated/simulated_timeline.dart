import 'dart:async';
import '../client.dart';

class SimulatedTimeline extends Timeline {
  @override
  Future<void> loadMoreHistory() async {}

  @override
  void markAsRead(TimelineEvent event) {}

  @override
  Iterable<String>? get receipts => null;

  SimulatedTimeline(
    Client client,
    Room room,
  ) {
    this.client = client;
    this.room = room;
  }

  @override
  Future<TimelineEvent?> fetchEventByIdInternal(String eventId) async {
    return tryGetEvent(eventId);
  }
}
