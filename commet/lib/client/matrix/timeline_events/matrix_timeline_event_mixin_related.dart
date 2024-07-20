import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_base.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_feature_related.dart';

mixin MatrixTimelineEventRelated on MatrixTimelineEventBase
    implements TimelineEventFeatureRelated {
  @override
  String? get relatedEventId => _getRelatedEventId();

  @override
  EventRelationshipType? get relationshipType =>
      switch (event.relationshipType) {
        "m.in_reply_to" => EventRelationshipType.reply,
        "m.thread" => _getThreadRichResponseId() != null
            ? EventRelationshipType.reply
            : null,
        _ => null,
      };

  String? _getThreadRichResponseId() {
    var rel = event.content["m.relates_to"] as Map<String, dynamic>?;
    if (rel == null) {
      return null;
    }

    var reponse = rel["m.in_reply_to"] as Map<String, dynamic>?;

    if (reponse == null) {
      return null;
    }

    if (rel["is_falling_back"] == true) {
      return null;
    }

    return reponse["event_id"];
  }

  String? _getRelatedEventId() {
    if (event.relationshipType == "m.thread") {
      return _getThreadRichResponseId();
    }

    return event.relationshipEventId;
  }
}
