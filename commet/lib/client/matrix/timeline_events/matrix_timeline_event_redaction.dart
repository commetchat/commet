import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event_redaction.dart';

class MatrixTimelineEventRedaction extends MatrixTimelineEvent
    implements TimelineEventRedaction {
  MatrixTimelineEventRedaction(super.event, {required super.client});
}
