import 'dart:convert';

import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:matrix/matrix.dart' as matrix;

abstract class MatrixTimelineEvent implements TimelineEvent {
  final MatrixClient client;

  matrix.Event event;

  MatrixTimelineEvent(this.event, {required this.client});

  @override
  bool get editable => false;

  @override
  String get eventId => event.eventId;

  @override
  DateTime get originServerTs => event.originServerTs;

  @override
  String get senderId => event.senderId;

  @override
  String get source =>
      const JsonEncoder.withIndent('  ').convert(event.toJson());

  @override
  TimelineEventStatus get status => switch (event.status) {
        matrix.EventStatus.error => TimelineEventStatus.error,
        matrix.EventStatus.sending => TimelineEventStatus.sending,
        matrix.EventStatus.sent => TimelineEventStatus.sent,
        matrix.EventStatus.synced => TimelineEventStatus.synced,
      };

  @override
  String get plainTextBody => event.plaintextBody;
}
