import 'package:commet/client/attachment.dart';
import 'package:commet/client/client.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_attachments.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_reactions.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_reply.dart';
import 'package:commet/ui/molecules/timeline_events/layouts/timeline_event_layout_message.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:intl/intl.dart' as intl;
import 'package:intl/intl.dart';

class TimelineEventViewMessage extends StatefulWidget {
  const TimelineEventViewMessage(
      {super.key,
      required this.timeline,
      this.showSender = true,
      this.detailed = false,
      required this.initialIndex});

  final Timeline timeline;
  final int initialIndex;
  final bool showSender;
  final bool detailed;

  @override
  State<TimelineEventViewMessage> createState() =>
      _TimelineEventViewMessageState();
}

class _TimelineEventViewMessageState extends State<TimelineEventViewMessage>
    implements TimelineEventViewWidget {
  late String senderName;
  late Color senderColor;

  String get messageFailedToDecrypt => Intl.message("Failed to decrypt event",
      desc: "Placeholde text for when a message fails to decrypt",
      name: "messageFailedToDecrypt");

  GlobalKey reactionsKey = GlobalKey();

  Widget? formattedContent;
  ImageProvider? senderAvatar;
  List<Attachment>? attachments;
  bool hasReactions = false;
  bool isInResponse = false;
  bool showSender = false;
  late String currentUserIdentifier;
  late DateTime sentTime;

  int index = 0;

  @override
  void initState() {
    currentUserIdentifier = widget.timeline.client.self!.identifier;
    loadEventState(widget.initialIndex);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TimelineEventLayoutMessage(
      senderName: senderName,
      senderColor: senderColor,
      senderAvatar: senderAvatar,
      showSender: showSender,
      formattedContent: formattedContent,
      timestamp: timestampToString(sentTime),
      attachments: attachments != null
          ? TimelineEventViewAttachments(attachments: attachments!)
          : null,
      inResponseTo: isInResponse
          ? TimelineEventViewReply(
              timeline: widget.timeline,
              index: index,
            )
          : null,
      reactions: hasReactions
          ? TimelineEventViewReactions(
              key: reactionsKey, timeline: widget.timeline, initialIndex: index)
          : null,
    );
  }

  @override
  void update(int newIndex) {
    setState(() {
      loadEventState(newIndex);
    });

    for (var key in [reactionsKey]) {
      if (key.currentState is TimelineEventViewWidget) {
        (key.currentState as TimelineEventViewWidget).update(newIndex);
      }
    }
  }

  void loadEventState(var eventIndex) {
    index = eventIndex;
    var event = widget.timeline.events[eventIndex];
    var sender = widget.timeline.room.getMemberOrFallback(event.senderId);

    senderName = sender.displayName;
    senderAvatar = sender.avatar;
    senderColor = sender.defaultColor;

    showSender = shouldShowSender(eventIndex);

    if (event.type == EventType.encrypted) {
      formattedContent = tiamat.Text.error(messageFailedToDecrypt);
    }

    if (event.bodyFormat != null) {
      formattedContent =
          Container(key: GlobalKey(), child: event.buildFormattedContent()!);
    }

    hasReactions = event.reactions != null && event.reactions!.isNotEmpty;

    attachments = event.attachments;
    isInResponse = event.relatedEventId != null &&
        event.relationshipType == EventRelationshipType.reply;

    sentTime = event.originServerTs;
  }

  String timestampToString(DateTime time) {
    var use24 = MediaQuery.of(context).alwaysUse24HourFormat;

    if (widget.detailed) {
      if (use24) {
        return intl.DateFormat.yMMMMd().add_Hms().format(time.toLocal());
      } else {
        return intl.DateFormat.yMMMMd().add_jms().format(time.toLocal());
      }
    } else {
      if (use24) {
        return intl.DateFormat.Hm().format(time.toLocal());
      } else {
        return intl.DateFormat.jm().format(time.toLocal());
      }
    }
  }

  bool shouldShowSender(int index) {
    if (widget.timeline.events.length <= index + 1) {
      return true;
    }

    if (widget.timeline.events[index].relationshipType ==
        EventRelationshipType.reply) return true;

    if (![EventType.message, EventType.encrypted]
        .contains(widget.timeline.events[index + 1].type)) return true;

    if (widget.timeline.events[index + 1].status ==
        TimelineEventStatus.removed) {
      return true;
    }

    if (widget.timeline.events[index].originServerTs
            .difference(widget.timeline.events[index + 1].originServerTs)
            .inMinutes >
        1) return true;

    return widget.timeline.events[index].senderId !=
        widget.timeline.events[index + 1].senderId;
  }
}
