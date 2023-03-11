import 'package:commet/ui/atoms/generic_room_event.dart';
import 'package:commet/ui/molecules/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import '../../client/client.dart';

class TimelineEventView extends StatefulWidget {
  const TimelineEventView({required this.event, super.key, this.onDelete});
  final TimelineEvent event;

  final Function? onDelete;

  @override
  State<TimelineEventView> createState() => _TimelineEventState();
}

class _TimelineEventState extends State<TimelineEventView> {
  @override
  Widget build(BuildContext context) {
    switch (widget.event.type) {
      case EventType.message:
        return Message(
          widget.event,
          onDelete: widget.onDelete,
        );
        break;
      case EventType.redaction:
        // TODO: Handle this case.
        break;
      case EventType.edit:
        // TODO: Handle this case.
        break;
      case EventType.invalid:
        // TODO: Handle this case.
        break;
      case EventType.roomState:
        return GenericRoomEvent(widget.event.body!, Icons.delete);
        break;
    }

    return Placeholder(
      fallbackHeight: 20,
    );
  }
}
