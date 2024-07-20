import 'package:commet/client/client.dart';

abstract class TimelineEventBase<T extends Client> {
  TimelineEventStatus get status;

  String get plainTextBody;

  String get eventId;
  String get senderId;
  DateTime get originServerTs;
  String get source;

  bool get editable;

  @override
  int get hashCode => eventId.hashCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other);
  }
}
