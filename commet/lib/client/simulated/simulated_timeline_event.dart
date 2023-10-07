import 'package:commet/client/attachment.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/timeline.dart';
import 'package:flutter/widgets.dart';

class SimulatedTimelineEvent implements TimelineEvent {
  @override
  List<Attachment>? get attachments => null;

  @override
  String? body;

  @override
  String? get bodyFormat => null;

  @override
  bool get editable => false;

  @override
  bool get edited => false;

  @override
  String eventId;

  @override
  String? get formattedBody => null;

  @override
  Widget? get formattedContent => null;

  @override
  DateTime originServerTs;

  @override
  Map<Emoticon, Set<String>>? get reactions => null;

  @override
  String? get relatedEventId => null;

  @override
  EventRelationshipType? get relationshipType => null;

  @override
  String senderId;

  @override
  String? get source => null;

  @override
  String? get stateKey => null;

  @override
  TimelineEventStatus get status => TimelineEventStatus.synced;

  @override
  EventType get type => EventType.message;

  @override
  bool get highlight => false;

  SimulatedTimelineEvent({
    required this.body,
    required this.eventId,
    required this.originServerTs,
    required this.senderId,
  });
}
