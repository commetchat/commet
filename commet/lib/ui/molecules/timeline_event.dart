import 'package:commet/config/build_config.dart';
import 'package:commet/ui/molecules/message.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../client/client.dart';

class TimelineEventView extends StatefulWidget {
  const TimelineEventView(
      {required this.event,
      super.key,
      this.onDelete,
      this.hovered = false,
      this.showSender = true,
      this.debugInfo});
  final TimelineEvent event;
  final bool hovered;
  final Function? onDelete;
  final bool showSender;
  final String? debugInfo;

  @override
  State<TimelineEventView> createState() => _TimelineEventState();
}

class _TimelineEventState extends State<TimelineEventView> {
  @override
  Widget build(BuildContext context) {
    var display = eventToWidget(widget.event);
    return AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: widget.hovered ? m.Colors.red : m.Colors.transparent,
        child: display);
  }

  Widget? eventToWidget(TimelineEvent event) {
    switch (widget.event.type) {
      case EventType.message:
        return Message(
          widget.event,
          showSender: widget.showSender,
          onDelete: widget.onDelete,
        );
      default:
        break;
    }

    if (BuildConfig.DEBUG) {
      return m.Padding(
        padding: const EdgeInsets.all(8.0),
        child: Placeholder(
            child: event.source != null
                ? tiamat.Text.tiny(event.source!)
                : const Placeholder(
                    fallbackHeight: 20,
                  )),
      );
    }
    return null;
  }
}
