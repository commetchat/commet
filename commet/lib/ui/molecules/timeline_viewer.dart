import 'dart:async';
import 'dart:math';

import 'package:commet/client/client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class TimelineViewer extends StatefulWidget {
  const TimelineViewer({required this.room, Key? key}) : super(key: key);
  final Room room;

  @override
  State<TimelineViewer> createState() => TimelineViewerState();
}

class TimelineViewerState extends State<TimelineViewer> {
  late ScrollController scrollController;
  late StreamSubscription eventAdded;
  late List<TimelineEvent> _displayEvents;
  int _displayStartIndex = 0;
  int _initialDisplayMaxEvents = 20;

  bool _aboutToDispose = false;

  int reverseIndex(int index) {
    return _displayEvents.length - index - 1;
  }

  @override
  void dispose() {
    eventAdded.cancel();
    super.dispose();
  }

  void prepareForDisposal() {
    print("About to be disposed");
    _aboutToDispose = true;
    scrollController.position.hold(() {});
  }

  void scrollToEnd(Duration duration) {
    if (_aboutToDispose) {
      print("Cancelling due to disposal");
      return;
    }
    if (!scrollController.hasClients || scrollController.positions.isEmpty) return;
    if (duration.inMilliseconds > 0) {
      scrollController
          .animateTo(scrollController.position.maxScrollExtent, duration: duration, curve: Curves.easeOutExpo)
          .then((value) => scrollController.jumpTo(scrollController.position.maxScrollExtent));
    } else {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    }
  }

  scrollToEndNextFrame(Duration duration) {
    print("Scrolling to end?");
    if (_aboutToDispose) {
      print("Cancelling due to disposal");
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollToEnd(duration);
      }
    });
  }

  @override
  void initState() {
    scrollController = ScrollController();
    var events = widget.room.timeline!.events;
    _displayEvents = List.from(events.sublist(0, min(events.length - 1, _initialDisplayMaxEvents)));
    _displayStartIndex = 0;

    if (widget.room.timeline != null) {
      eventAdded = widget.room.timeline!.onEventAdded.stream.listen((index) {
        setState(() {
          _displayEvents.insert(index, widget.room.timeline!.events[index]);
        });

        if (isScrolledToBottom()) {
          scrollToEndNextFrame(Duration(milliseconds: 500));
        }
      });
    }

    super.initState();
  }

  bool isScrolledToBottom() {
    var result = scrollController.position.pixels >= scrollController.position.maxScrollExtent;
    return result;
  }

  bool isScrolledToTop() {
    return scrollController.position.pixels <= scrollController.position.minScrollExtent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      // Listen... I'm not happy about this either
      // ListView and AnimatedList both try to be too smart for their own good,
      // It makes the scrolling experience terrible for lists which dont have consistent item height
      // Trust me, I TRIED to make it work without shrinkwrap. It cannot be done...
      child: Stack(
        children: [
          SingleChildScrollView(
              reverse: false,
              controller: scrollController,
              physics: BouncingScrollPhysics(),
              child: ListView.builder(
                itemCount: _displayEvents.length,
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  if (_displayEvents[reverseIndex(index)].widget == null) return SizedBox();
                  return _displayEvents[reverseIndex(index)].widget!;
                },
              )),
          ElevatedButton(onPressed: () => scrollToEnd(Duration(milliseconds: 500)), child: Text("Scroll to end"))
        ],
      ),
    );
  }
}
