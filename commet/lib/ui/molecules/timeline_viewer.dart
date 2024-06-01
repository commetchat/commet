import 'dart:async';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/molecules/message_popup_menu/message_popup_menu.dart';
import 'package:commet/ui/molecules/timeline_event.dart';
import 'package:commet/ui/molecules/timeline_event/timeline_event_2.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/config/config.dart';
import '../../client/client.dart';
import '../../client/components/emoticon/emoticon.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
/* Note: This aint your mother's timeline viewer...
This file contains some unusual hacks in order to achieve a smoother experience

Hack #1: Split Timeline
This timeline renders elements as part of two seperate slivers
one for new events, and one for previous events
this allows us to center the scroll view on the 'middle' of the two slivers/
This prevents the view from jumping around when new items are added / removed from
the top and bottom of the timeline

---

Hack #2: First frame offscreen render
Due to the previous hack, when we initially open the viewer, the recent events are offscreen
because the scrollviewer starts with an offset of 0, and all our recent events are in an offset < 0
To work around this, on the first frame we render the scroll view offstage, so we can grab the 
minScrollExtent of the scroll view

Then after this frame is rendered, we construct a new scroll controller and set the initial offset
to the minScrollExtent we just grabbed, which places timeline right where we would expect it!

---

I know its weird but its necessary!
*/

class TimelineViewer extends StatefulWidget {
  const TimelineViewer(
      {required this.timeline,
      this.markAsRead,
      this.setReplyingEvent,
      this.onEventDoubleTap,
      this.setEditingEvent,
      this.onEventLongPress,
      this.onAddReaction,
      this.onReactionTapped,
      this.doMessageOverlayMenu = true,
      Key? key})
      : super(key: key);

  final bool doMessageOverlayMenu;
  final Timeline timeline;
  final Function(TimelineEvent event)? markAsRead;
  final Function(TimelineEvent? event)? setReplyingEvent;
  final Function(TimelineEvent? event)? setEditingEvent;
  final Function(TimelineEvent event)? onEventDoubleTap;
  final Function(TimelineEvent event)? onEventLongPress;
  final Function(TimelineEvent event, Emoticon emote)? onAddReaction;
  final Function(TimelineEvent event, Emoticon emote)? onReactionTapped;

  @override
  State<TimelineViewer> createState() => TimelineViewerState();
}

class TimelineViewerState extends State<TimelineViewer>
    with WidgetsBindingObserver {
  Key historyEventsKey = GlobalKey();
  ScrollController controller = ScrollController(initialScrollOffset: -999999);
  bool firstFrame = true;

  int recentItemsCount = 0;
  int historyItemsCount = 0;
  int hoveredIndex = -1;
  double height = -1;
  bool animatingToBottom = false;
  bool get attachedToBottom => controller.hasClients
      ? controller.offset - controller.positions.first.minScrollExtent < 50 ||
          animatingToBottom
      : true;

  Future? loadingHistory;
  bool toBeDisposed = false;

  bool showJumpToBottom = false;

  StreamController<int> onHoveredMessageChanged = StreamController.broadcast();

  late StreamSubscription eventAdded;
  late StreamSubscription eventChanged;
  late StreamSubscription eventRemoved;
  final LayerLink messageLayerLink = LayerLink();

  bool messagePopupIsBeingInteracted = false;

  String get labelJumpToLatest => Intl.message("Jump to latest",
      desc:
          "Label for the button which jumps the room timeline view to the latest message",
      name: "labelJumpToLatest");

  @override
  void initState() {
    recentItemsCount = widget.timeline.events.length;
    eventAdded = widget.timeline.onEventAdded.stream.listen(onEventAdded);
    eventChanged = widget.timeline.onChange.stream.listen(onEventChanged);
    eventRemoved = widget.timeline.onRemove.stream.listen(onEventRemoved);
    WidgetsBinding.instance.addPostFrameCallback(onAfterFirstFrame);
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      if (attachedToBottom) {
        widget.markAsRead?.call(widget.timeline.events.first);
      }
    }
  }

  @override
  void dispose() {
    eventAdded.cancel();
    eventChanged.cancel();
    eventRemoved.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget buildOverlay() {
    if (hoveredIndex == -1) {
      return Container();
    }

    var event = widget.timeline.events[hoveredIndex];
    return Positioned(
        height: 50,
        child: CompositedTransformFollower(
            targetAnchor: Alignment.topRight,
            followerAnchor: Alignment.topRight,
            showWhenUnlinked: false,
            offset: const Offset(-20, -48),
            link: messageLayerLink,
            child: SizedBox(child: buildPopupMenu(event, false))));
  }

  onEventLongPress(TimelineEvent event) {
    if (BuildConfig.MOBILE) {
      showModalBottomSheet(
          showDragHandle: true,
          isScrollControlled: true,
          elevation: 0,
          context: context,
          builder: (context) => buildPopupMenu(event, true));
    }
  }

  Widget buildPopupMenu(TimelineEvent event, bool asDialog) {
    return SingleChildScrollView(
      child: MessagePopupMenu(
        event,
        widget.timeline,
        isEditable: canUserEditEvent(event),
        asDialog: asDialog,
        isDeletable: widget.timeline.canDeleteEvent(event),
        setEditingEvent: widget.setEditingEvent,
        setReplyingEvent: widget.setReplyingEvent,
        canSaveAttachment: event.attachments?.isNotEmpty ?? false,
        addReaction: widget.onAddReaction,
        onPopupStateChanged: (state) => messagePopupIsBeingInteracted = state,
      ),
    );
  }

  bool canUserEditEvent(TimelineEvent event) {
    if (event.attachments != null) return false;

    return widget.timeline.room.permissions.canUserEditMessages &&
        event.senderId == widget.timeline.room.client.self!.identifier;
  }

  void onAfterFirstFrame(_) {
    if (widget.timeline.events.isNotEmpty) {
      widget.markAsRead?.call(widget.timeline.events.first);
    }

    if (controller.hasClients) {
      double extent = controller.position.minScrollExtent;
      controller = ScrollController(initialScrollOffset: extent);
      controller.addListener(onScroll);
      setState(() {
        firstFrame = false;
      });
    }
  }

  void loadMoreHistory() async {
    loadingHistory = widget.timeline.loadMoreHistory();
    await loadingHistory;
    loadingHistory = null;
  }

  bool shouldScrollPositionLoadHistory() {
    return controller.offset > controller.position.maxScrollExtent - 500;
  }

  void onScroll() {
    if (shouldScrollPositionLoadHistory()) {
      if (loadingHistory == null) loadMoreHistory();
    }

    setState(() {
      showJumpToBottom = !attachedToBottom;
    });
  }

  void animateAndSnapToBottom() {
    if (toBeDisposed) return;
    controller.position.hold(() {});

    setState(() {
      animatingToBottom = true;
      showJumpToBottom = false;
    });
    int lastEvent = recentItemsCount;

    controller
        .animateTo(controller.position.minScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutExpo)
        .then((value) {
      if (recentItemsCount == lastEvent) {
        controller.jumpTo(controller.position.minScrollExtent);

        setState(() {
          animatingToBottom = false;
          showJumpToBottom = false;
        });
      }
    });
  }

  void onEventAdded(int index) {
    setState(() {});
    if (index == 0 || index < recentItemsCount) {
      recentItemsCount += 1;
    } else {
      historyItemsCount = widget.timeline.events.length - recentItemsCount;
    }

    if (index == 0) {
      if (attachedToBottom || animatingToBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          animateAndSnapToBottom();
        });

        widget.markAsRead?.call(widget.timeline.events[0]);
      }
    }
  }

  void onEventChanged(int index) {
    setState(() {});
  }

  void onEventRemoved(int index) {
    setState(() {});
  }

  void prepareForDisposal() {
    toBeDisposed = true;
    controller.position.hold(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (firstFrame) {
      return Offstage(
        child: buildScrollView(),
      );
    }

    return NotificationListener(
        onNotification: (SizeChangedLayoutNotification notification) {
          var prevHeight = height;
          height = MediaQuery.of(context).size.height;
          if (prevHeight == -1) return true;

          var diff = prevHeight - height;
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            controller.jumpTo(controller.offset + diff);
          });

          return true;
        },
        child: buildScrollView());
  }

  Widget buildScrollView() {
    var view = CustomScrollView(
      center: historyEventsKey,
      reverse: true,
      controller: controller,
      cacheExtent: 200,
      anchor: 0,
      slivers: [
        //Beware, these are in reverse order
        SliverList(
            delegate: SliverChildBuilderDelegate(buildRecentItem,
                childCount: recentItemsCount)),
        SliverList(
            key: historyEventsKey,
            delegate: SliverChildBuilderDelegate(buildHistoryItem,
                childCount: historyItemsCount)),
      ],
    );

    return ClipRect(
      child: Stack(
        children: [
          if (Layout.mobile) view,
          if (Layout.desktop) SelectionArea(child: view),
          if (Layout.desktop) buildOverlay(),
          Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedSlide(
                  offset: Offset(0, showJumpToBottom ? 0 : 1),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOutCubic,
                  child: buildJumpToLatestButton()))
        ],
      ),
    );
  }

  Widget buildJumpToLatestButton() {
    var padding = BuildConfig.MOBILE
        ? const EdgeInsets.fromLTRB(18, 12, 18, 12)
        : const EdgeInsets.fromLTRB(12, 4, 12, 4);
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor,
                  blurRadius: 5,
                )
              ],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Theme.of(context).extension<ExtraColors>()!.highlight,
                  width: 1),
              color: Theme.of(context).extension<ExtraColors>()!.surfaceHigh1),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: animateAndSnapToBottom,
                child: Padding(
                  padding: padding,
                  child: tiamat.Text.labelLow(
                    labelJumpToLatest,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  Widget? buildHistoryItem(BuildContext context, int index) {
    var displayIndex = recentItemsCount + index;
    return Container(
        color: BuildConfig.DEBUG && preferences.developerMode
            ? Colors.red.withAlpha(15)
            : null,
        child: buildEvent(displayIndex, index));
  }

  Widget? buildRecentItem(BuildContext context, int index) {
    int displayIndex = recentItemsCount - index - 1;
    return Container(
        color: BuildConfig.DEBUG && preferences.developerMode
            ? Colors.blue.withAlpha(15)
            : null,
        child: buildEvent(displayIndex, index));
  }

  Widget buildEvent(int displayIndex, int actualIndex) {
    var event = Stack(alignment: Alignment.topRight, children: [
      buildTimelineEvent(displayIndex),
      if (displayIndex == hoveredIndex)
        CompositedTransformTarget(
          link: messageLayerLink,
          child: const SizedBox(
            height: 1,
            width: 1,
          ),
        )
    ]);

    if (shouldShowDate(displayIndex)) {
      return Column(
        children: [
          dateTimeMarker(displayIndex),
          event,
        ],
      );
    }

    return event;
  }

  Widget dateTimeMarker(int actualIndex) {
    var color = Theme.of(context).extension<ExtraColors>()!.surfaceLow2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Divider(
              height: 1,
              color: Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: tiamat.Text.labelLow(TextUtils.timestampToLocalizedTime(
                widget.timeline.events[actualIndex].originServerTs,
                MediaQuery.of(context).alwaysUse24HourFormat)),
          ),
          Expanded(
            child: Divider(
              height: 1,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTimelineEvent(int index) {
    return MouseRegion(
      onEnter: (event) {
        if (!widget.doMessageOverlayMenu) return;
        if (index == hoveredIndex) return;
        if (messagePopupIsBeingInteracted) return;

        setState(() {
          hoveredIndex = index;
        });
      },
      child: Container(
          color: hoveredIndex == index
              ? Theme.of(context).hoverColor
              : Colors.transparent,
          child: TimelineEvent2(
            timeline: widget.timeline,
            eventIndex: index,
          )),
    );
  }

  bool shouldShowDate(int index) {
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
