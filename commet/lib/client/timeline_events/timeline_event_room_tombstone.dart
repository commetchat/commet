import 'package:commet/client/timeline_events/timeline_event.dart';

abstract class TimelineEventRoomTombstone extends TimelineEvent {
  String? get replacementRoomId;
}
