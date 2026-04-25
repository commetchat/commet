import 'package:commet/client/client.dart';
import 'package:commet/client/components/polls/poll_component.dart';
import 'package:commet/client/components/read_receipts/read_receipt_component.dart';
import 'package:commet/client/components/threads/thread_component.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_create_room.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event_emote.dart';
import 'package:commet/client/timeline_events/timeline_event_encrypted.dart';
import 'package:commet/client/timeline_events/timeline_event_generic.dart';
import 'package:commet/client/timeline_events/timeline_event_message.dart';
import 'package:commet/client/timeline_events/timeline_event_sticker.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/diagnostic/benchmark_values.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/adaptive_context_menu.dart';
import 'package:commet/ui/atoms/emoji_widget.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_generic.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_message.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_poll.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_date_time_marker.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_layout.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_menu.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_menu_dialog.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/context_menu.dart';
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
      this.previewMedia = false,
      this.highlightedEventId,
      this.canCollapse = false,
      super.key});
  final Timeline timeline;
  final int initialIndex;
  final Function(String eventId)? onEventHovered;
  final Function(TimelineEvent? event)? setReplyingEvent;
  final Function(TimelineEvent? event)? setEditingEvent;
  final Function(String eventId)? jumpToEvent;
  final bool showDetailed;
  final bool isThreadTimeline;
  final bool canCollapse;
  final String? highlightedEventId;
  final bool previewMedia;

  // Should be true if we are showing this event on its own, and not as part of a timeline
  final bool singleEvent;

  @override
  State<TimelineViewEntry> createState() => TimelineViewEntryState();
}

// This enum exists because we need to know which type of message to render
// But if we try to check the actual type of the event during build e.g: (`event is TimelineEventMessage`)
// It causes extra widget rebuilds, so we check type only during the event update and store it with this enum
// I thought maybe if we override hashcode of TimelineEventBase it would allow us to just check the type
// But it didnt. I dont know if there is a way to fix that
enum TimelineEventWidgetDisplayType {
  message,
  generic,
  emote,
  roomCreate,
  poll,
  hidden,
}

enum TimelineEventWidgetCollapseType {
  root,
  child,
}

class TimelineViewEntryState extends State<TimelineViewEntry>
    implements TimelineEventViewWidget, SelectableEventViewWidget {
  late String eventId;
  late TimelineEventStatus status;

  // Note that this index is only reliable on builds - if an item is inserted in to the list, this index will be out of sync until its updated.
  // If you need to get the event which this widget represents, use the ID
  late int index;

  GlobalKey eventKey = GlobalKey();

  bool selected = false;
  bool isThreadReply = false;
  bool highlighted = false;
  bool redacted = false;

  TimelineEventWidgetCollapseType? collapse = null;

  TimelineEventWidgetDisplayType _widgetType =
      TimelineEventWidgetDisplayType.hidden;
  LayerLink? timelineLayerLink;

  late DateTime time;
  bool showDateSeperator = false;

  ThreadsComponent? threads;
  PollComponent? polls;

  List<String> readReceipts = [];

  @override
  void initState() {
    threads = widget.timeline.room.client.getComponent<ThreadsComponent>();
    polls = widget.timeline.client.getComponent<PollComponent>();

    isThreadReply = threads?.isEventInResponseToThread(
            widget.timeline.events[widget.initialIndex], widget.timeline) ??
        false;

    loadState(widget.initialIndex);
    super.initState();
  }

  void loadState(int eventIndex) {
    var event = widget.timeline.events[eventIndex];
    redacted = widget.timeline.isEventRedacted(event);

    var receipts = widget.timeline.room
        .getComponent<ReadReceiptComponent>()
        ?.getReceipts(event);
    if (receipts != null) {
      readReceipts = receipts;
    }

    eventId = event.eventId;
    status = event.status;
    index = eventIndex;
    time = event.originServerTs;

    _widgetType = eventToDisplayType(event, polls: polls);

    bool isCollapsible = false;
    bool isPrevCollapsible = false;
    bool isNextCollapsible = false;

    isCollapsible = isEventTypeCollapsible(_widgetType);

    bool showRedactions = false;

    if (widget.timeline.events.length > eventIndex + 1) {
      var prevEvent = widget.timeline.events[eventIndex + 1];
      var prevEventType = eventToDisplayType(prevEvent, polls: polls);

      isPrevCollapsible = isEventTypeCollapsible(prevEventType);
      if (widget.timeline.isEventRedacted(prevEvent) == true) {
        isPrevCollapsible = !showRedactions;
      }
    }

    if (eventIndex > 0) {
      var nextEvent = widget.timeline.events[eventIndex - 1];
      var nextEventType = eventToDisplayType(nextEvent, polls: polls);
      isNextCollapsible = isEventTypeCollapsible(nextEventType);

      if (widget.timeline.isEventRedacted(nextEvent) == true) {
        isNextCollapsible = !showRedactions;
      }
    }

    if (isCollapsible && isNextCollapsible && !isPrevCollapsible) {
      collapse = TimelineEventWidgetCollapseType.root;
    }

    if (isCollapsible && isPrevCollapsible) {
      collapse = TimelineEventWidgetCollapseType.child;
    }

    showDateSeperator = shouldEventShowDate(eventIndex);
    highlighted = event.eventId == widget.highlightedEventId;
  }

  bool isEventTypeCollapsible(TimelineEventWidgetDisplayType eventType) {
    const collapsibleTypes = [
      TimelineEventWidgetDisplayType.generic,
      TimelineEventWidgetDisplayType.hidden
    ];

    return collapsibleTypes.contains(eventType);
  }

  static TimelineEventWidgetDisplayType eventToDisplayType(TimelineEvent event,
      {PollComponent? polls}) {
    if (event is TimelineEventMessage ||
        event is TimelineEventSticker ||
        event is TimelineEventEncrypted) {
      return TimelineEventWidgetDisplayType.message;
    }

    if (event is MatrixTimelineEventCreateRoom) {
      return TimelineEventWidgetDisplayType.roomCreate;
    }

    if (event is TimelineEventEmote) {
      return TimelineEventWidgetDisplayType.emote;
    }

    if (event is TimelineEventGeneric) {
      return TimelineEventWidgetDisplayType.generic;
    }

    if (polls?.isPollEvent(event) == true) {
      return TimelineEventWidgetDisplayType.poll;
    }

    if (event.status == TimelineEventStatus.error) {
      return TimelineEventWidgetDisplayType.generic;
    }

    return TimelineEventWidgetDisplayType.hidden;
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

    var event = widget.timeline.events[index];
    if (event is! TimelineEventMessage &&
        event is! TimelineEventEmote &&
        event is! TimelineEventSticker) {
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

    if (redacted) return Container();

    if (widget.canCollapse && collapse == TimelineEventWidgetCollapseType.child)
      return Container();

    if (collapse != null &&
        preferences.showStateEvents.value == false &&
        preferences.developerMode.value == false) return Container();

    var result = buildEvent();

    if (collapse == TimelineEventWidgetCollapseType.root &&
        widget.canCollapse) {
      int endIndex = index;

      List<String> bodies = List.empty(growable: true);

      var count = 0;
      const maxBodies = 3;

      for (int i = index; i > 0; i--) {
        var event = widget.timeline.events[i];
        var type = eventToDisplayType(event, polls: polls);
        if (!isEventTypeCollapsible(type)) {
          break;
        }

        if (type != TimelineEventWidgetDisplayType.hidden ||
            preferences.developerMode.value) {
          count += 1;
          if (bodies.length < maxBodies) {
            bodies.add(event.plainTextBody);
          }
        }

        endIndex = i;
      }

      if (count == 0) return Container();

      var diff = count - bodies.length;
      var text = bodies.join(", ");
      if (diff > 0) {
        text += " and $diff more";
      }
      return ExpansionTile(
        title: Padding(
          padding: const EdgeInsets.fromLTRB(52, 0, 0, 0),
          child: tiamat.Text.labelLow(text),
        ),
        children: [
          Column(
            children: [
              for (int i = index; i >= endIndex; i--)
                TimelineViewEntry(
                  timeline: widget.timeline,
                  initialIndex: i,
                  canCollapse: false,
                  highlightedEventId: widget.highlightedEventId,
                  onEventHovered: widget.onEventHovered,
                )
            ],
          )
        ],
      );
    }

    if (result == null) {
      return Container();
    }

    if (status == TimelineEventStatus.sending ||
        status == TimelineEventStatus.error) {
      result = Opacity(
        opacity: 0.5,
        child: result,
      );
    }

    if (status == TimelineEventStatus.error) {
      result = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: Icon(
              Icons.error,
              size: 14,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          Expanded(child: result),
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

    if (Layout.desktop) {
      var event = widget.timeline.tryGetEvent(eventId);
      if (event != null) {
        var menu = TimelineEventMenu(
            timeline: widget.timeline,
            event: event,
            setEditingEvent: widget.setEditingEvent,
            setReplyingEvent: widget.setReplyingEvent);
        result = AdaptiveContextMenu(items: [
          if (menu.addReactionAction != null)
            ContextMenuItem(
              text: "Add Reaction",
              customBuilder: (context, onClick) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (var i = 0;
                        i < 3 && i < menu.recentReactions.length;
                        i++)
                      InkWell(
                          onTap: () {
                            widget.timeline.room
                                .addReaction(event, menu.recentReactions[i]);
                            onClick();
                          },
                          child: SizedBox(
                              height: 30,
                              width: 30,
                              child: EmojiWidget(menu.recentReactions[i]))),
                    tiamat.IconButton(
                      icon: Icons.add_reaction,
                      size: 24,
                      onPressed: () {
                        onClick();

                        AdaptiveDialog.show(
                          context,
                          builder: (newContext) {
                            return SizedBox(
                                width: 500,
                                height: 500,
                                child: menu
                                    .addReactionAction!.secondaryMenuBuilder!
                                    .call(
                                  newContext,
                                  () {
                                    Navigator.of(newContext).pop();
                                  },
                                ));
                          },
                        );
                        menu.addReactionAction?.action?.call(context);
                      },
                    )
                  ],
                ),
              ),
            ),
          for (var i in menu.primaryActions)
            ContextMenuItem(
                text: i.name,
                icon: i.icon,
                onPressed: () => i.action?.call(context)),
          for (var i in menu.secondaryActions)
            ContextMenuItem(
                text: i.name,
                icon: i.icon,
                onPressed: () => i.action?.call(context))
        ], child: result);
      }
    }

    if (selected) {
      result = Container(
        color: Theme.of(context).hoverColor.withAlpha(5),
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
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
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
          result
        ],
      );
    }

    if (showDateSeperator) {
      result = Column(
        children: [TimelineEventDateTimeMarker(time: time), result],
      );
    }

    return result;
  }

  Widget? buildEvent() {
    if (redacted) {
      return null;
    }

    if (widget.singleEvent == false &&
        widget.isThreadTimeline == false &&
        isThreadReply) {
      return null;
    }

    if (_widgetType == TimelineEventWidgetDisplayType.message)
      return TimelineEventViewMessage(
          key: eventKey,
          timeline: widget.timeline,
          isThreadTimeline: widget.isThreadTimeline,
          detailed: widget.showDetailed || selected,
          onReadReceiptsTapped: onReadReceiptsTapped,
          readReceipts: readReceipts,
          overrideShowSender: widget.singleEvent || showDateSeperator,
          jumpToEvent: widget.jumpToEvent,
          previewMedia: widget.previewMedia,
          initialIndex: widget.initialIndex);

    if (_widgetType == TimelineEventWidgetDisplayType.generic &&
        (preferences.showStateEvents.value || preferences.developerMode.value))
      return TimelineEventViewGeneric(
        timeline: widget.timeline,
        initialIndex: widget.initialIndex,
        room: widget.timeline.room,
        readReceipts: readReceipts,
        onReadReceiptsTapped: onReadReceiptsTapped,
        key: eventKey,
      );

    if (_widgetType == TimelineEventWidgetDisplayType.emote ||
        _widgetType == TimelineEventWidgetDisplayType.roomCreate)
      return TimelineEventViewGeneric(
        timeline: widget.timeline,
        initialIndex: widget.initialIndex,
        room: widget.timeline.room,
        readReceipts: readReceipts,
        onReadReceiptsTapped: onReadReceiptsTapped,
        key: eventKey,
      );

    if (_widgetType == TimelineEventWidgetDisplayType.poll) {
      return TimelineEventViewPoll(
        initialIndex: widget.initialIndex,
        timeline: widget.timeline,
        key: eventKey,
      );
    }

    if (preferences.developerMode.value == false &&
        _widgetType == TimelineEventWidgetDisplayType.hidden) {
      return null;
    }

    return preferences.developerMode.value
        ? TimelineEventViewGeneric(
            timeline: widget.timeline,
            room: widget.timeline.room,
            initialIndex: widget.initialIndex,
            key: eventKey,
            onReadReceiptsTapped: onReadReceiptsTapped,
            readReceipts: readReceipts,
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
    if (mounted)
      setState(() {
        highlighted = value;
      });
  }

  onReadReceiptsTapped() {
    AdaptiveDialog.show(context, title: "Read Receipts", builder: (context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: readReceipts
            .map((i) => UserPanel(
                userId: i,
                client: widget.timeline.client,
                contextRoom: widget.timeline.room))
            .toList(),
      );
    });
  }
}
