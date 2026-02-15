import 'package:commet/client/components/threads/thread_component.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_message.dart';
import 'package:commet/client/timeline_events/timeline_event_sticker.dart';
import 'package:commet/ui/atoms/thread_reply_footer.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';

class TimelineEventViewThread extends StatefulWidget {
  const TimelineEventViewThread(
      {super.key,
      required this.initialIndex,
      required this.timeline,
      required this.component});

  final int initialIndex;
  final Timeline timeline;
  final ThreadsComponent component;

  @override
  State<TimelineEventViewThread> createState() =>
      _TimelineEventViewThreadState();
}

class _TimelineEventViewThreadState extends State<TimelineEventViewThread> {
  String? senderName;
  String? body;
  ImageProvider? senderAvatar;
  Color? senderColor;

  late String threadEventId;

  @override
  void initState() {
    getStateFromIndex(widget.initialIndex);
    super.initState();
  }

  void getStateFromIndex(int index) {
    var event = widget.timeline.events[index];
    threadEventId = event.eventId;
    var threadEvent =
        widget.component.getFirstReplyToThread(event, widget.timeline);
    if (threadEvent == null) {
      return;
    }

    var sender = widget.timeline.room.getMemberOrFallback(threadEvent.senderId);

    if (threadEvent is TimelineEventMessage) {
      body = threadEvent.body;
    } else if (threadEvent is TimelineEventSticker) {
      body = threadEvent.stickerName;
    }

    senderName = sender.displayName;
    senderAvatar = sender.avatar;
    senderColor = sender.defaultColor;
  }

  @override
  Widget build(BuildContext context) {
    return ThreadReplyFooter(
      body: body ?? "",
      senderName: senderName ?? "Unknown Sender",
      senderAvatar: senderAvatar,
      senderColor: senderColor,
      onTap: () => EventBus.openThread.add((
        widget.timeline.client.identifier,
        widget.timeline.room.roomId,
        threadEventId
      )),
    );
  }
}
