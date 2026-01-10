import 'package:commet/client/attachment.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/threads/thread_component.dart';
import 'package:commet/client/components/url_preview/url_preview_component.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event_encrypted.dart';
import 'package:commet/client/timeline_events/timeline_event_feature_reactions.dart';
import 'package:commet/client/timeline_events/timeline_event_message.dart';
import 'package:commet/client/timeline_events/timeline_event_feature_related.dart';
import 'package:commet/client/timeline_events/timeline_event_sticker.dart';
import 'package:commet/client/timeline_events/timeline_event_unknown.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_attachments.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_reactions.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_reply.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_sticker.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_thread.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_url_previews.dart';
import 'package:commet/ui/molecules/timeline_events/layouts/timeline_event_layout_message.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_layout.dart';
import 'package:commet/ui/organisms/user_profile/user_profile.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class TimelineEventViewMessage extends StatefulWidget {
  const TimelineEventViewMessage(
      {super.key,
      this.timeline,
      this.room,
      this.initialEvent,
      this.isThreadTimeline = false,
      this.overrideShowSender = false,
      this.jumpToEvent,
      this.detailed = false,
      this.previewMedia = false,
      required this.initialIndex});

  final Function(String eventId)? jumpToEvent;

  final Timeline? timeline;
  final TimelineEvent? initialEvent;
  final Room? room;
  final int initialIndex;
  final bool overrideShowSender;
  final bool detailed;
  final bool isThreadTimeline;
  final bool previewMedia;

  @override
  State<TimelineEventViewMessage> createState() =>
      _TimelineEventViewMessageState();
}

class _TimelineEventViewMessageState extends State<TimelineEventViewMessage>
    implements TimelineEventViewWidget {
  late String senderName;
  late String senderId;
  late Color senderColor;

  String get messageFailedToDecrypt => Intl.message("Failed to decrypt event",
      desc: "Placeholde text for when a message fails to decrypt",
      name: "messageFailedToDecrypt");

  GlobalKey reactionsKey = GlobalKey();
  GlobalKey urlPreviewsKey = GlobalKey();

  Widget? formattedContent;
  String? body;
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
    var room = widget.room ?? widget.timeline?.room;
    var client = room!.client;
    currentUserIdentifier = client.self!.identifier;
    if (widget.previewMedia) {
      previewComponent = client.getComponent<UrlPreviewComponent>();
    }

    if (!widget.isThreadTimeline) {
      threadComponent = client.getComponent<ThreadsComponent>();
    }

    if (widget.timeline != null) {
      loadEventState(widget.initialIndex);
    }

    if (widget.initialEvent != null) {
      loadStateFromEvent(widget.initialEvent!);
    }
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
          ? TimelineEventViewAttachments(
              attachments: attachments!,
              previewMedia: widget.previewMedia,
            )
          : null,
      sticker: sticker != null
          ? TimelineEventViewSticker(
              sticker!,
              stickerName: body,
              previewMedia: widget.previewMedia,
            )
          : null,
      inResponseTo: isInResponse && widget.timeline != null
          ? TimelineEventViewReply(
              timeline: widget.timeline!,
              index: index,
              jumpToEvent: widget.jumpToEvent,
            )
          : null,
      reactions: hasReactions && widget.timeline != null
          ? TimelineEventViewReactions(
              key: reactionsKey,
              timeline: widget.timeline!,
              initialIndex: index)
          : null,
      urlPreviews:
          previewComponent != null && doUrlPreview && widget.timeline != null
              ? TimelineEventViewUrlPreviews(
                  initialIndex: index,
                  timeline: widget.timeline!,
                  component: previewComponent!,
                  key: urlPreviewsKey,
                )
              : null,
      thread: isHeadOfThread && widget.timeline != null
          ? TimelineEventViewThread(
              initialIndex: index,
              timeline: widget.timeline!,
              component: threadComponent!)
          : null,
      onAvatarTapped: () => UserProfile.show(context,
          client: widget.timeline!.client, userId: senderId),
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
    if (widget.timeline != null) {
      var event = widget.timeline!.events[eventIndex];
      loadStateFromEvent(event);
    }
  }

  void loadStateFromEvent(TimelineEvent event) {
    showSender = shouldShowSender(index);
    var room = widget.room ?? widget.timeline?.room;

    var sender = room!.getMemberOrFallback(event.senderId);
    eventId = event.eventId;

    senderId = sender.identifier;
    senderName = sender.displayName;
    senderAvatar = sender.avatar;
    senderColor = sender.defaultColor;

    sentTime = event.originServerTs;

    if (widget.timeline != null) {
      if (event is TimelineEventFeatureReactions) {
        hasReactions = (event as TimelineEventFeatureReactions)
            .hasReactions(widget.timeline!);
      }

      isHeadOfThread =
          threadComponent?.isHeadOfThread(event, widget.timeline!) ?? false;

      if (event is TimelineEventMessage) {
        edited = event.isEdited(widget.timeline!);
      }
    } else {
      edited = false;
      isHeadOfThread = false;
      hasReactions = false;
    }

    if (event is TimelineEventSticker) {
      sticker = event.stickerImage;
      body = event.plainTextBody;
    }

    isInResponse = event is TimelineEventFeatureRelated &&
        (event as TimelineEventFeatureRelated).relationshipType ==
            EventRelationshipType.reply;

    if (event is TimelineEventEncrypted) {
      formattedContent = tiamat.Text.error(messageFailedToDecrypt);
    }

    if (event is! TimelineEventMessage) {
      return;
    }

    var content = event.buildFormattedContent(timeline: widget.timeline);
    if (content == null) {
      formattedContent = null;
    } else {
      formattedContent = Container(key: GlobalKey(), child: content);
    }

    attachments = event.attachments;

    doUrlPreview = widget.timeline != null &&
        previewComponent?.shouldGetPreviewDataForTimelineEvent(
                widget.timeline!, event) ==
            true &&
        event.getLinks(timeline: widget.timeline!)?.isEmpty == false;
  }

  String timestampToString(DateTime time) {
    if (PlatformUtils.isAndroid) {
      // I think this only works properly on android and ios, there is no documented
      // Behaviour for other platforms
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

    if (widget.detailed) {
      return TextUtils.timestampToLocalizedTimeSpecific(time, context);
    } else {
      return MaterialLocalizations.of(context)
          .formatTimeOfDay(TimeOfDay.fromDateTime(time));
    }
  }

  bool shouldShowSender(int index) {
    if (widget.overrideShowSender) return true;
    if (widget.timeline == null) return true;

    TimelineEvent? prevEvent;
    for (int i = 1; i < 5; i++) {
      int testIndex = index + i;
      if (widget.timeline!.events.length <= testIndex) {
        return true;
      }
      var event = widget.timeline!.events[testIndex];

      if (preferences.developerMode) {
        prevEvent = event;
        break;
      }

      if (event is! TimelineEventUnknown) {
        prevEvent = event;
        break;
      }
    }

    if (prevEvent == null) {
      return true;
    }

    final thisEvent = widget.timeline!.events[index];
    if (thisEvent is! TimelineEventMessage &&
        thisEvent is! TimelineEventSticker &&
        thisEvent is! TimelineEventEncrypted) {
      return false;
    }

    if (thisEvent is TimelineEventFeatureRelated) {
      if ((thisEvent as TimelineEventFeatureRelated).relationshipType ==
          EventRelationshipType.reply) {
        return true;
      }
    }

    if (prevEvent is! TimelineEventMessage &&
        prevEvent is! TimelineEventEncrypted &&
        prevEvent is! TimelineEventSticker) {
      return true;
    }

    if (widget.timeline!.isEventRedacted(prevEvent)) {
      return true;
    }

    if (widget.isThreadTimeline == false &&
        threadComponent?.isEventInResponseToThread(
                prevEvent, widget.timeline!) ==
            true) {
      return true;
    }

    if (thisEvent.originServerTs
            .difference(prevEvent.originServerTs)
            .inMinutes >
        1) return true;

    return thisEvent.senderId != prevEvent.senderId;
  }
}
