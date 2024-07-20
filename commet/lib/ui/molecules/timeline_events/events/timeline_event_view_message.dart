import 'package:commet/client/attachment.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/threads/thread_component.dart';
import 'package:commet/client/components/url_preview/url_preview_component.dart';
import 'package:commet/client/timeline_events/timeline_event_feature_reactions.dart';
import 'package:commet/client/timeline_events/timeline_event_message.dart';
import 'package:commet/client/timeline_events/timeline_event_feature_related.dart';
import 'package:commet/client/timeline_events/timeline_event_sticker.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_attachments.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_reactions.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_reply.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_sticker.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_thread.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_url_previews.dart';
import 'package:commet/ui/molecules/timeline_events/layouts/timeline_event_layout_message.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:intl/intl.dart' as intl;
import 'package:intl/intl.dart';

class TimelineEventViewMessage extends StatefulWidget {
  const TimelineEventViewMessage(
      {super.key,
      required this.timeline,
      this.isThreadTimeline = false,
      this.overrideShowSender = false,
      this.jumpToEvent,
      this.detailed = false,
      required this.initialIndex});

  final Function(String eventId)? jumpToEvent;

  final Timeline timeline;
  final int initialIndex;
  final bool overrideShowSender;
  final bool detailed;
  final bool isThreadTimeline;

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
  GlobalKey urlPreviewsKey = GlobalKey();

  Widget? formattedContent;
  ImageProvider? senderAvatar;
  List<Attachment>? attachments;
  ImageProvider? sticker;
  bool hasReactions = false;
  bool isInResponse = false;
  bool showSender = false;
  late String eventId;
  late String currentUserIdentifier;
  late DateTime sentTime;

  UrlPreviewComponent? previewComponent;
  bool doUrlPreview = false;

  ThreadsComponent? threadComponent;
  bool isHeadOfThread = false;

  int index = 0;

  bool edited = false;

  @override
  void initState() {
    currentUserIdentifier = widget.timeline.client.self!.identifier;
    previewComponent =
        widget.timeline.room.client.getComponent<UrlPreviewComponent>();

    if (!widget.isThreadTimeline) {
      threadComponent =
          widget.timeline.room.client.getComponent<ThreadsComponent>();
    }

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
      edited: edited,
      attachments: attachments != null
          ? TimelineEventViewAttachments(attachments: attachments!)
          : null,
      sticker: sticker != null ? TimelineEventViewSticker(sticker!) : null,
      inResponseTo: isInResponse
          ? TimelineEventViewReply(
              timeline: widget.timeline,
              index: index,
              jumpToEvent: widget.jumpToEvent,
            )
          : null,
      reactions: hasReactions
          ? TimelineEventViewReactions(
              key: reactionsKey, timeline: widget.timeline, initialIndex: index)
          : null,
      urlPreviews: previewComponent != null && doUrlPreview
          ? TimelineEventViewUrlPreviews(
              initialIndex: index,
              timeline: widget.timeline,
              component: previewComponent!,
              key: urlPreviewsKey,
            )
          : null,
      thread: isHeadOfThread
          ? TimelineEventViewThread(
              initialIndex: index,
              timeline: widget.timeline,
              component: threadComponent!)
          : null,
    );
  }

  @override
  void update(int newIndex) {
    setState(() {
      loadEventState(newIndex);
    });

    for (var key in [reactionsKey, urlPreviewsKey]) {
      if (key.currentState is TimelineEventViewWidget) {
        (key.currentState as TimelineEventViewWidget).update(newIndex);
      }
    }
  }

  void loadEventState(var eventIndex) {
    index = eventIndex;
    var event = widget.timeline.events[eventIndex];
    var sender = widget.timeline.room.getMemberOrFallback(event.senderId);
    eventId = event.eventId;

    senderName = sender.displayName;
    senderAvatar = sender.avatar;
    senderColor = sender.defaultColor;

    showSender = shouldShowSender(eventIndex);

    sentTime = event.originServerTs;

    if (event is TimelineEventFeatureReactions) {
      hasReactions = (event as TimelineEventFeatureReactions)
          .hasReactions(widget.timeline);
    }

    if (event is TimelineEventSticker) {
      sticker = event.stickerImage;
    }

    isInResponse = event is TimelineEventFeatureRelated &&
        (event as TimelineEventFeatureRelated).relationshipType ==
            EventRelationshipType.reply;

    isHeadOfThread =
        threadComponent?.isHeadOfThread(event, widget.timeline) ?? false;

    if (event is! TimelineEventMessage) {
      return;
    }

    edited = event.isEdited(widget.timeline);
    // TODO: REIMPLEMENT
    // if (event.type == EventType.encrypted) {
    //   formattedContent = tiamat.Text.error(messageFailedToDecrypt);
    // }

    var content = event.buildFormattedContent(timeline: widget.timeline);
    if (content == null) {
      formattedContent = null;
    } else {
      formattedContent = Container(key: GlobalKey(), child: content);
    }

    attachments = event.attachments;

    doUrlPreview =
        previewComponent?.shouldGetPreviewData(widget.timeline.room, event) ==
                true &&
            event.links?.isNotEmpty == true;
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
    if (widget.overrideShowSender) return true;

    if (widget.timeline.events.length <= index + 1) {
      return true;
    }

    final thisEvent = widget.timeline.events[index];
    if (thisEvent is! TimelineEventMessage &&
        thisEvent is! TimelineEventSticker) {
      return false;
    }

    if (thisEvent is TimelineEventFeatureRelated) {
      if ((thisEvent as TimelineEventFeatureRelated).relationshipType ==
          EventRelationshipType.reply) {
        return true;
      }
    }

    final prevEvent = widget.timeline.events[index + 1];

    // TODO: HANDLE IF PREV EVENT IS ENCRYPTED
    if (prevEvent is! TimelineEventMessage) {
      return true;
    }

    if (widget.timeline.isEventRedacted(prevEvent)) {
      return true;
    }

    if (widget.isThreadTimeline == false &&
        threadComponent?.isEventInResponseToThread(
                widget.timeline.events[index + 1], widget.timeline) ==
            true) {
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
