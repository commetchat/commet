import 'package:commet/client/client.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';

abstract class TimelineEventEncrypted extends TimelineEvent {
  Future<TimelineEvent?> attemptDecrypt(Room room);
}
