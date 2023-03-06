import 'dart:async';
import 'dart:math';

import 'package:commet/client/timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class TimelineViewer extends StatefulWidget {
  ///Child scrollable widget.
  final Timeline timeline;

  TimelineViewer({required this.timeline, Key? key}) : super(key: key);

  @override
  State<TimelineViewer> createState() => TimelineViewerState();
}

class TimelineViewerState extends State<TimelineViewer> {
  bool attachedToBottom = true;
  final ScrollController controller = ScrollController();
  final ScrollPhysics physics = BouncingScrollPhysics();
  Key centerKey = ValueKey<String>('bottom-sliver-list');
  late StreamSubscription eventAdded;

  List<TimelineEvent> history = <TimelineEvent>[];
  List<TimelineEvent> newEvents = <TimelineEvent>[];
  int newEventsCount = 0;
  int historyEventsCount = 0;
  bool toBeDisposed = false;

  void animateAndSnapToBottom() {
    if (toBeDisposed) {
      print("Cancelling animation about to be disposed");
      return;
    }
    controller
        .animateTo(controller.position.maxScrollExtent,
            duration: Duration(milliseconds: 500), curve: Curves.easeOutExpo)
        .then((value) => controller.jumpTo(controller.position.maxScrollExtent));
  }

  void forceToBottom() {
    controller.jumpTo(controller.position.maxScrollExtent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!(controller.position.pixels >= controller.position.maxScrollExtent)) forceToBottom();
    });
  }

  void prepareForDisposal() {
    print("Preparing for disposal");
    toBeDisposed = true;
    controller.position.hold(() {});
  }

  @override
  void dispose() {
    eventAdded.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    newEvents =
        List.from(widget.timeline.events.sublist(0, min(widget.timeline.events.length - 1, 20)), growable: true);
    newEventsCount = newEvents.length;

    controller.addListener(() {
      handleBottomAttached();
    });

    eventAdded = widget.timeline.onEventAdded.stream.listen((index) {
      newEvents.insert(index, widget.timeline.events[index]);
      setState(() {
        newEventsCount++;

        if (attachedToBottom) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            animateAndSnapToBottom();
          });
        }
      });
    });
  }

  int reverseIndexHistory(int index) {
    return history.length - index - 1;
  }

  int reverseIndexNew(int index) {
    return newEvents.length - index - 1;
  }

  void handleBottomAttached() {
    setState(() {
      attachedToBottom = controller.position.pixels >= controller.position.maxScrollExtent;
      print("Scroll view attached to bottom: ");
      print(attachedToBottom);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        center: centerKey,
        controller: controller,
        physics: physics,
        slivers: <Widget>[
          SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
            if (history[reverseIndexHistory(index)].widget == null) return SizedBox();
            return history[reverseIndexHistory(index)].widget!;
          }, childCount: history.length)),
          SliverList(
              key: centerKey,
              delegate: SliverChildBuilderDelegate((context, index) {
                if (newEvents[reverseIndexNew(index)].widget == null) return SizedBox();
                return newEvents[reverseIndexNew(index)].widget!;
              }, childCount: newEventsCount)),
        ],
      ),
    );
  }
}
