import 'package:commet/client/attachment.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_message.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixBackgroundTimelineEventMessage implements TimelineEventMessage {
  matrix.MatrixEvent event;

  MatrixBackgroundTimelineEventMessage(this.event);

  @override
  List<Attachment>? get attachments => null;

  @override
  String? get body => event.content.toString();

  @override
  String? get bodyFormat => null;

  @override
  Widget? buildFormattedContent({Timeline? timeline}) {
    return null;
  }

  @override
  bool get editable => false;

  @override
  String get eventId => event.eventId;

  @override
  String? get formattedBody => null;

  @override
  List<Uri>? getLinks({Timeline? timeline}) {
    throw UnimplementedError();
  }

  @override
  bool isEdited(Timeline timeline) {
    throw UnimplementedError();
  }

  @override
  DateTime get originServerTs => event.originServerTs;

  @override
  String get plainTextBody {
    if (event.type == matrix.EventTypes.Encrypted) {
      return "Sent a message";
    }

    if (event.type == matrix.EventTypes.Message) {
      if (event.content["body"] is String) {
        return event.content["body"] as String;
      }
    }

    return "Unknown event type";
  }

  @override
  String get senderId => event.senderId;

  @override
  String get source => throw UnimplementedError();

  @override
  TimelineEventStatus get status => throw UnimplementedError();

  @override
  String getPlaintextBody(Timeline timeline) {
    return plainTextBody;
  }
}
