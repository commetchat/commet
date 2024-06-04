import 'package:commet/client/client.dart';
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

class TimelineViewEntry extends StatefulWidget {
  const TimelineViewEntry(
      {required this.timeline,
      required this.initialIndex,
      this.onEventHovered,
      this.setEditingEvent,
      this.setReplyingEvent,
      this.showDetailed = false,
      this.overrideShowSender = false,
      super.key});
  final Timeline timeline;
  final int initialIndex;
  final Function(String eventId)? onEventHovered;
  final Function(TimelineEvent? event)? setReplyingEvent;
  final Function(TimelineEvent? event)? setEditingEvent;
  final bool showDetailed;
  final bool overrideShowSender;

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
  LayerLink? timelineLayerLink;

  late DateTime time;
  bool showDate = false;

  @override
  void initState() {
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
    // setState(() {
    loadState(newIndex);

    if (eventKey.currentState is TimelineEventViewWidget) {
      (eventKey.currentState as TimelineEventViewWidget).update(newIndex);
    } else {
      Log.w("Failed to get state from event key");
    }
  }

  @override
  Widget build(BuildContext context) {
    BenchmarkValues.numTimelineEventsBuilt += 1;
    Log.d(
        "Num times timeline event built: ${BenchmarkValues.numTimelineEventsBuilt} ($eventId)");

    if (status == TimelineEventStatus.removed) return Container();

    var result = buildEvent();

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
        return TimelineEventViewMessage(
            key: eventKey,
            timeline: widget.timeline,
            detailed: widget.showDetailed || selected,
            overrideShowSender: widget.overrideShowSender,
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
  }

  @override
  void deselect() {
    setState(() {
      selected = false;
      timelineLayerLink = null;
    });
  }

  @override
  void select(LayerLink link) {
    setState(() {
      selected = true;
      timelineLayerLink = link;
    });
  }
}
