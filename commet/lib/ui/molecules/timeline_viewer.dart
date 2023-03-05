import 'package:commet/config/style/theme_extensions.dart';
import 'package:commet/ui/molecules/message.dart';
import 'package:commet/widgets/custom_scroll.dart';
import 'package:commet/widgets/custom_scroll_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../client/client.dart';

class TimelineViewer extends StatefulWidget {
  final Room room;
  const TimelineViewer({required this.room, Key? key}) : super(key: key);

  @override
  _TimelineViewerState createState() => _TimelineViewerState();
}

class _TimelineViewerState extends State<TimelineViewer> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final ScrollController scrollController = ScrollController();
  int _count = 0;
  final GlobalKey _offstageMessageKey = GlobalKey();
  late List<TimelineEvent> _renderedEvents;

  int _lastAddedMessageIndex = 0;

  final ValueNotifier<double> _messageHeight = ValueNotifier<double>(-1);
  bool disposing = false;

  @override
  void dispose() {
    disposing = true;
  }

  bool isScrolledToBottom() {
    return scrollController.position.pixels <= scrollController.position.minScrollExtent;
  }

  bool isScrolledToTop() {
    return scrollController.position.pixels >= scrollController.position.maxScrollExtent;
  }

  double prevHeight = 0;

  void onNextFrame(_) {
    print("-----");
    double height = _offstageMessageKey.currentContext!.size!.height;

    print("Next message height: " + _offstageMessageKey.currentContext!.size.toString());

    _renderedEvents.insert(_lastAddedMessageIndex, widget.room.timeline!.events[_lastAddedMessageIndex]);
    _listKey.currentState?.insertItem(_lastAddedMessageIndex, duration: const Duration(milliseconds: 500));
    if (scrollController.position.isScrollingNotifier.value) {
      print("Skipping offset because user scrolling");
      return;
    }
    if (!isScrolledToBottom()) scrollController.jumpTo(scrollController.offset + 68);
  }

  double prev = 0;

  @override
  void initState() {
    _count = widget.room.timeline!.events.length;

    _renderedEvents = List.from(widget.room.timeline!.events, growable: true);
    _count = _renderedEvents.length;

    widget.room.timeline!.onEventAdded.stream.listen((index) {
      if (!disposing) {
        setState(() {
          _lastAddedMessageIndex = index;
        });

        WidgetsBinding.instance.addPostFrameCallback(onNextFrame);
      }
    });

    scrollController.addListener(() {
      print("Scrolling");
      if (isScrolledToTop()) {
        widget.room.timeline!.loadMoreHistory();
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
                child: AnimatedList(
                    key: _listKey,
                    reverse: true,
                    controller: scrollController,
                    physics: BouncingScrollPhysics(),
                    initialItemCount: _count,
                    itemBuilder: (context, i, animation) {
                      // This feels gross? is there a better way to do this?
                      if (widget.room.timeline!.events[i].widget == null) return SizedBox();

                      if (i == 0) {}

                      return SizeTransition(
                          sizeFactor: animation.drive(CurveTween(curve: Curves.easeOutCubic)),
                          child: _renderedEvents[i].widget);
                    }),
              ),
            ],
          ),
        )),
        Offstage(
          offstage: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: Colors.black.withAlpha(128),
                child: widget.room.timeline!.events[0].widget,
                key: _offstageMessageKey,
              ),
            ],
          ),
        )
      ],
    );
  }
}
