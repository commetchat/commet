import 'dart:async';
import 'dart:math';

import 'package:commet/config/style/theme_extensions.dart';
import 'package:commet/ui/molecules/message.dart';
import 'package:commet/widgets/custom_scroll.dart';
import 'package:commet/widgets/custom_scroll_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../../client/client.dart';

class TimelineViewer extends StatefulWidget {
  final Room room;
  const TimelineViewer({required this.room, Key? key}) : super(key: key);

  @override
  _TimelineViewerState createState() => _TimelineViewerState();
}

class _TimelineViewerState extends State<TimelineViewer> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late ScrollController scrollController;
  int _displayCount = 0;
  late GlobalKey lastKey;

  late List<TimelineEvent> displayEvents;

  bool isScrolledToBottom() {
    var result = scrollController.position.pixels >= scrollController.position.maxScrollExtent;
    return result;
  }

  bool isScrolledToTop() {
    return scrollController.position.pixels <= scrollController.position.minScrollExtent;
  }

  // We manually reverse the list because using ListView's 'reverse' makes the scroll behaviour annoying
  // And doing it this way allows us to work around some annoying hacky stuff like offsetting the scroll position
  // When appending new items to the list
  int reverseIndex(int index) {
    return _displayCount - index - 1;
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void loadMoreHistory() {
    double scrollHeight = scrollController.position.maxScrollExtent;
    var timelineEvents = widget.room.timeline!.events;
    int numToCopy = min(20, timelineEvents.length - displayEvents.length);
    if (displayEvents.length < timelineEvents.length) {
      int startIndex = displayEvents.length;
      displayEvents.addAll(timelineEvents.sublist(displayEvents.length, displayEvents.length + numToCopy));
      int endIndex = displayEvents.length;
      _displayCount = displayEvents.length;

      for (int i = startIndex; i < endIndex; i++) {
        _listKey.currentState!.insertItem(reverseIndex(i));
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        print(scrollHeight);
        print(scrollController.position.maxScrollExtent);
        print(scrollController.position.maxScrollExtent - scrollHeight);
      });
    }
  }

  void recursiveScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isScrolledToBottom()) {
          recursiveScrollToBottom();
        }
      });
    });
  }

  @override
  void initState() {
    displayEvents = List.from(widget.room.timeline!.events.sublist(0, min(20, widget.room.timeline!.events.length - 1)),
        growable: true);
    _displayCount = displayEvents.length;

    print("Num Events: " + _displayCount.toString());

    scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500), curve: Curves.easeOutExpo);
    });

    widget.room.timeline!.onEventAdded.stream.listen((index) {
      _displayCount++;
      if (index < displayEvents.length) {
        displayEvents.insert(index, widget.room.timeline!.events[index]);

        _listKey.currentState?.insertItem(reverseIndex(index), duration: const Duration(milliseconds: 0));
      }

      if (!scrollController.hasClients) return;

      if (isScrolledToBottom()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollController.animateTo(scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500), curve: Curves.easeOutExpo);
        });
      }
    });

    scrollController.addListener(() {
      if (isScrolledToTop()) {
        loadMoreHistory();
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
            child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: [
              const Divider(height: 1),
              Expanded(
                key: widget.room.key,
                child: AnimatedList(
                    key: _listKey,
                    reverse: false,
                    controller: scrollController,
                    initialItemCount: _displayCount,
                    //physics: BouncingScrollPhysics(),
                    itemBuilder: (context, i, animation) {
                      // This feels gross? is there a better way to do this?
                      if (displayEvents[reverseIndex(i)].widget == null) return SizedBox();

                      return displayEvents[reverseIndex(i)].widget!;
                    }),
              ),
            ],
          ),
        )),
        ElevatedButton(onPressed: recursiveScrollToBottom, child: Text("Scroll to bottom"))
      ],
    );
  }
}
