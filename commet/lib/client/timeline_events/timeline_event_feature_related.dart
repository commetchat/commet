import 'package:commet/client/timeline.dart';

abstract class TimelineEventFeatureRelated {
  EventRelationshipType? get relationshipType;

  String? get relatedEventId;
}
