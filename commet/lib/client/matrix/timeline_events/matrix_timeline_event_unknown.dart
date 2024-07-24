import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event_unknown.dart';

class MatrixTimelineEventUnknown extends MatrixTimelineEvent
    implements TimelineEventUnknown {
  MatrixTimelineEventUnknown(super.event, {required super.client});

  @override
  String get plainTextBody => "Unknown Event Type: ${event.type}";
}
