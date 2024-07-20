import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_base.dart';
import 'package:commet/client/timeline_events/timeline_event_add_reaction.dart';

class MatrixTimelineEventAddReaction extends MatrixTimelineEvent
    implements TimelineEventAddReaction {
  MatrixTimelineEventAddReaction(super.event, {required super.client});
}
