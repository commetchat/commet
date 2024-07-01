import 'package:commet/client/client.dart';
import 'package:commet/client/components/threads/thread_component.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/diagnostic/benchmark_values.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_generic.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_message.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_date_time_marker.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_layout.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_menu.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_menu_dialog.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class TimelineViewEntry extends StatefulWidget {
  const TimelineViewEntry(
      {required this.timeline,
      required this.initialIndex,
      this.onEventHovered,
      this.setEditingEvent,
      this.setReplyingEvent,
      this.jumpToEvent,
      this.showDetailed = false,
      this.singleEvent = false,
      this.isThreadTimeline = false,
      super.key});
  final Timeline timeline;
  final int initialIndex;
  final Function(String eventId)? onEventHovered;
  final Function(TimelineEvent? event)? setReplyingEvent;
  final Function(TimelineEvent? event)? setEditingEvent;
  final Function(String eventId)? jumpToEvent;
  final bool showDetailed;
  final bool isThreadTimeline;

  // Should be true if we are showing this event on its own, and not as part of a timeline
  final bool singleEvent;

  @override
  State<TimelineViewEntry> createState() => TimelineViewEntryState();
}

class TimelineViewEntryState extends State<TimelineViewEntry>
    implements TimelineEventViewWidget, SelectableEventViewWidget {
  late String eventId;
  late EventType eventType;
  late TimelineEventStatus status;

  // Note that this index is only reliable on builds - if an item is inserted in to the list, this index will be out of sync until its updated.
  // If you need to get the event which this widget represents, use the ID
  late int index;

  GlobalKey eventKey = GlobalKey();

  bool selected = false;
  bool isThreadReply = false;
  bool highlighted = false;
  LayerLink? timelineLayerLink;

  late DateTime time;
  bool showDate = false;

  ThreadsComponent? threads;
  @override
  void initState() {
    threads = widget.timeline.room.client.getComponent<ThreadsComponent>();

    isThreadReply = threads?.isEventInResponseToThread(
            widget.timeline.events[widget.initialIndex], widget.timeline) ??
        false;

    loadState(widget.initialIndex);
    super.initState();
  }

  void loadState(int eventIndex) {
    var event = widget.timeline.events[eventIndex];
    eventId = event.eventId;
    eventType = event.type;
    status = event.status;
    index = eventIndex;
    time = event.originServerTs;
    showDate = shouldEventShowDate(eventIndex);
  }

  bool shouldEventShowDate(int index) {
    if (widget.singleEvent) {
      return false;
    }

    if (widget.isThreadTimeline) {
      if (threads?.isHeadOfThread(
              widget.timeline.events[index], widget.timeline) ==
          true) {
        return true;
      }
    }

    var offsetIndex = index + 1;

    if (widget.timeline.events.length <= offsetIndex) {
      return false;
    }

    if ([
          EventType.emote,
          EventType.message,
        ].contains(widget.timeline.events[index].type) ==
        false) {
      return false;
    }

    if (widget.timeline.events[index].originServerTs.toLocal().day !=
        widget.timeline.events[offsetIndex].originServerTs.toLocal().day) {
      return true;
    }

    if (widget.timeline.events[index].originServerTs
            .difference(widget.timeline.events[offsetIndex].originServerTs)
            .inHours >
        2) return true;

    return false;
  }

  @override
  void update(int newIndex) {
    index = newIndex;
    setState(() {
      loadState(newIndex);
    });

    if (eventKey.currentState is TimelineEventViewWidget) {
      (eventKey.currentState as TimelineEventViewWidget).update(newIndex);
    } else {
      Log.w("Failed to get state from event key");
    }
  }

  @override
  Widget build(BuildContext context) {
    BenchmarkValues.numTimelineEventsBuilt += 1;

    if (status == TimelineEventStatus.removed) return Container();

    var result = buildEvent();

    if (status == TimelineEventStatus.sending && result != null) {
      result = Opacity(
        opacity: 0.5,
        child: result,
      );
    }

    if (status == TimelineEventStatus.error && result != null) {
      result = Column(
        children: [
          result,
          const tiamat.Text.error("Failed to send"),
        ],
      );
    }

    if (Layout.desktop) {
      result = MouseRegion(
        onEnter: (_) => widget.onEventHovered?.call(eventId),
        child: result,
      );
    }

    if (Layout.mobile) {
      result = InkWell(
        onLongPress: () {
          var event = widget.timeline.tryGetEvent(eventId);
          if (event == null) {
            return;
          }

          showModalBottomSheet(
              showDragHandle: true,
              isScrollControlled: true,
              elevation: 0,
              context: context,
              builder: (context) => TimelineEventMenuDialog(
                    event: event,
                    timeline: widget.timeline,
                    menu: TimelineEventMenu(
                      timeline: widget.timeline,
                      isThreadTimeline: widget.isThreadTimeline,
                      event: event,
                      setEditingEvent: widget.setEditingEvent,
                      setReplyingEvent: widget.setReplyingEvent,
                      onActionFinished: () => Navigator.of(context).pop(),
                    ),
                  ));
        },
        child: result,
      );
    }

    if (selected) {
      result = Container(
        color: Theme.of(context).hoverColor,
        child: result,
      );
    }

    if (highlighted) {
      result = Container(
        decoration: BoxDecoration(
            border: Border(
                left: BorderSide(
                    color: Theme.of(context).colorScheme.primary, width: 3)),
            color: Theme.of(context).colorScheme.surfaceContainer),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(-3, 0, 0, 0),
          child: result,
        ),
      );
    }

    if (timelineLayerLink != null) {
      result = Stack(
        alignment: Alignment.topRight,
        children: [
          CompositedTransformTarget(
              link: timelineLayerLink!, child: const SizedBox()),
          result ?? Container()
        ],
      );
    }

    if (showDate) {
      result = Column(
        children: [
          TimelineEventDateTimeMarker(time: time),
          result ?? Container()
        ],
      );
    }

    return result ?? Container();
  }

  Widget? buildEvent() {
    switch (eventType) {
      case EventType.message:
      case EventType.sticker:
      case EventType.encrypted:
        if (widget.singleEvent ||
            (widget.isThreadTimeline) ||
            (!widget.isThreadTimeline && !isThreadReply))
          return TimelineEventViewMessage(
              key: eventKey,
              timeline: widget.timeline,
              isThreadTimeline: widget.isThreadTimeline,
              detailed: widget.showDetailed || selected,
              overrideShowSender: widget.singleEvent,
              jumpToEvent: widget.jumpToEvent,
              initialIndex: widget.initialIndex);
      case EventType.roomCreated:
      case EventType.memberJoined:
      case EventType.memberLeft:
      case EventType.memberAvatar:
      case EventType.memberDisplayName:
      case EventType.memberInvited:
      case EventType.memberInvitationRejected:
      case EventType.emote:
        return TimelineEventViewGeneric(
          timeline: widget.timeline,
          initialIndex: widget.initialIndex,
          key: eventKey,
        );
      default:
        break;
    }
    return preferences.developerMode
        ? TimelineEventViewGeneric(
            timeline: widget.timeline,
            initialIndex: widget.initialIndex,
            key: eventKey,
          )
        : Container(
            key: eventKey,
          );
  }

  @override
  void deselect() {
    if (mounted)
      setState(() {
        selected = false;
        timelineLayerLink = null;
      });
  }

  @override
  void select(LayerLink link) {
    if (mounted)
      setState(() {
        selected = true;
        timelineLayerLink = link;
      });
  }

  void setHighlighted(bool value) {
    setState(() {
      highlighted = value;
    });
  }
}
