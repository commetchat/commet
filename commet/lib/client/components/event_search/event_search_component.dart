import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';

abstract class EventSearchSession {
  Stream<List<TimelineEvent>> startSearch(String searchTerm);

  bool get currentlySearching;
}

abstract class EventSearchComponent<T extends Client> implements Component<T> {
  Future<EventSearchSession> createSearchSession(Room room);
}
