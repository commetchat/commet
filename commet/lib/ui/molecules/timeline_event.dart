import 'package:commet/config/build_config.dart';
import 'package:commet/ui/atoms/generic_room_event.dart';
import 'package:commet/ui/molecules/message.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../client/client.dart';

class TimelineEventView extends StatefulWidget {
  const TimelineEventView(
      {required this.event, super.key, this.onDelete, this.hovered = false, this.showSender = true, this.debugInfo});
  final TimelineEvent event;
  final bool hovered;
  final Function? onDelete;
  final bool showSender;
  final String? debugInfo;

  @override
  State<TimelineEventView> createState() => _TimelineEventState();
}

/*if (widget.hovered)
            Positioned(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                child: PopupIconMenu(
                  icons: [
                    MapEntry(Icons.edit, () {
                      print("Editing");
                    }),
                    MapEntry(Icons.emoji_emotions, () {
                      print("Emoji");
                    }),
                    MapEntry(Icons.reply, () {
                      print("Reply");
                    })
                  ],
                  height: 30,
                ),
              ),
              right: 1,
              top: 1,
            )*/
class _TimelineEventState extends State<TimelineEventView> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: widget.hovered ? m.Colors.red : m.Colors.transparent,
        child: Column(
          children: [
            eventToWidget(widget.event),
            if (BuildConfig.DEBUG && widget.debugInfo != null) tiamat.Text.tiny(widget.debugInfo!)
          ],
        ));
  }

  Widget eventToWidget(TimelineEvent event) {
    switch (widget.event.type) {
      case EventType.message:
        return Message(
          widget.event,
          showSender: widget.showSender,
          onDelete: widget.onDelete,
        );
      case EventType.redaction:
        break;
      case EventType.edit:
        break;
      case EventType.invalid:
        break;
      case EventType.roomState:
        return GenericRoomEvent(widget.event.body!, m.Icons.delete);
      default:
        break;
    }

    return const Placeholder(
      fallbackHeight: 20,
    );
  }
}
