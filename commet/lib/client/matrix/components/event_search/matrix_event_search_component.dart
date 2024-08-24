import 'package:commet/client/client.dart';
import 'package:commet/client/components/event_search/event_search_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_view_entry.dart';

class MatrixEventSearchSession extends EventSearchSession {
  MatrixTimeline timeline;
  String? currentSearchTerm;
  String? prevBatch;

  MatrixEventSearchSession(this.timeline);

  @override
  bool currentlySearching = false;

  @override
  Stream<List<TimelineEvent<Client>>> startSearch(String searchTerm) async* {
    currentSearchTerm = searchTerm;
    currentlySearching = true;
    var search = timeline.matrixTimeline!.startSearch(searchTerm: searchTerm);
    List<TimelineEvent<Client>> result = List.empty();
    await for (final chunk in search) {
      result = chunk.$1
          .map((e) => (timeline.room as MatrixRoom).convertEvent(e))
          .toList();

      Map<String, TimelineEvent> m = {};

      for (var event in result) {
        var type = TimelineViewEntryState.eventToDisplayType(event);
        if (type != TimelineEventWidgetDisplayType.hidden) {
          m[event.eventId] = event;
        }
      }

      if (chunk.$2 != null) {
        prevBatch = chunk.$2;
      }

      result = m.values.toList();
      result.sort((a, b) => b.originServerTs.compareTo(a.originServerTs));

      yield result;
    }

    currentlySearching = false;
    yield result;
  }
}

class MatrixEventSearchComponent implements EventSearchComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixEventSearchComponent(this.client);

  @override
  Future<EventSearchSession> createSearchSession(Room room) async {
    var timeline = await room.getTimeline();
    return MatrixEventSearchSession(timeline as MatrixTimeline);
  }
}
