import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class AlternateTimelineViewer extends StatefulWidget {
  const AlternateTimelineViewer({required this.room, Key? key}) : super(key: key);
  final Room room;

  @override
  State<AlternateTimelineViewer> createState() => AlternateTimelineViewerState();
}

class AlternateTimelineViewerState extends State<AlternateTimelineViewer> {
  late ScrollController scrollController;
  late StreamSubscription eventAdded;

  int reverseIndex(int index) {
    return widget.room.timeline!.events.length - index - 1;
  }

  @override
  void dispose() {
    eventAdded.cancel();
    super.dispose();
  }

  void scrollToEnd(Duration duration) {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollToEnd(duration);
      }
    });
  }

  @override
  void initState() {
    scrollController = ScrollController();

    if (widget.room.timeline != null) {
      eventAdded = widget.room.timeline!.onEventAdded.stream.listen((index) {
        setState(() {});

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
                itemCount: widget.room.timeline!.events.length,
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  if (widget.room.timeline!.events[reverseIndex(index)].widget == null) return SizedBox();
                  return widget.room.timeline!.events[reverseIndex(index)].widget!;
                },
              )),
          ElevatedButton(onPressed: () => scrollToEnd(Duration(milliseconds: 500)), child: Text("Scroll to end"))
        ],
      ),
    );
  }
}
