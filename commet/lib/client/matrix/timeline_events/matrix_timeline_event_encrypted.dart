import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event_encrypted.dart';

class MatrixTimelineEventEncrypted extends MatrixTimelineEvent
    implements TimelineEventEncrypted {
  MatrixTimelineEventEncrypted(super.event, {required super.client});

  @override
  Future<TimelineEvent<Client>?> attemptDecrypt(Room room) async {
    if (room is! MatrixTimelineEvent) {
      return null;
    }
    await event.requestKey();
    return room.getEvent(event.eventId);
  }
}
