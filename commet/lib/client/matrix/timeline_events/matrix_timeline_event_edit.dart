import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event_edit.dart';

class MatrixTimelineEventEdit extends MatrixTimelineEvent
    implements TimelineEventEdit {
  MatrixTimelineEventEdit(super.event, {required super.client});
}
