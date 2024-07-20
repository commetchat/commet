import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_base.dart';
import 'package:commet/client/timeline_events/timeline_event_feature_related.dart';
import 'package:commet/diagnostic/benchmark_values.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:flutter/material.dart' as material;

class TimelineEventViewReply extends StatefulWidget {
  const TimelineEventViewReply(
      {super.key,
      required this.timeline,
      required this.index,
      this.jumpToEvent,
      this.avatarSize = 32});
  final Timeline timeline;
  final Function(String eventId)? jumpToEvent;
  final int index;
  final double avatarSize;

  @override
  State<TimelineEventViewReply> createState() => _TimelineEventViewReplyState();
}

class _TimelineEventViewReplyState extends State<TimelineEventViewReply> {
  String? senderName;
  String? body;
  Color? senderColor;

  bool loading = false;
  String? replyEventId;

  @override
  void initState() {
    getStateFromIndex(widget.index);
    super.initState();
  }

  void getStateFromIndex(int index) {
    var event = widget.timeline.events[index];
    if (event is! TimelineEventFeatureRelated) {
      return;
    }

    var e = event as TimelineEventFeatureRelated;
    if (e.relatedEventId == null) {
      return;
    }

    var replyEvent = widget.timeline.tryGetEvent(e.relatedEventId!);

    if (replyEvent == null) {
      loading = true;
      widget.timeline.room.getEvent(e.relatedEventId!).then((value) {
        if (mounted && value != null) {
          setStateFromEvent(value);
        }
      });
    } else {
      setStateFromEvent(replyEvent);
    }
  }

  void setStateFromEvent(TimelineEventBase event) {
    setState(() {
      replyEventId = event.eventId;
      var sender = widget.timeline.room.getMemberOrFallback(event.senderId);
      senderName = sender.displayName;
      senderColor = sender.defaultColor;
      body = event.plainTextBody;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    BenchmarkValues.numTimelineReplyBodyBuilt += 1;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.jumpToEvent?.call(replyEventId!),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 45,
                child: SizedBox.expand(
                  child: CustomPaint(
                    painter: ReplyLinePainter2(
                        pathColor:
                            material.Theme.of(context).colorScheme.secondary,
                        avatarSize: widget.avatarSize),
                  ),
                ),
              ),
              Flexible(
                child: RichText(
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    text: TextSpan(children: [
                      TextSpan(
                          text: "${senderName ?? "Loading"} ",
                          style: TextStyle(
                              color: tiamat.Text.adjustColor(
                                  context, senderColor ?? Colors.white))),
                      TextSpan(
                          text: body ?? "Unknown",
                          style: TextStyle(
                              color: material.Theme.of(context)
                                  .colorScheme
                                  .secondary)),
                    ])),
              )
              // Column(
              //   children: [
              //     tiamat.Text(
              //       senderName ?? "Loading",
              //       color: senderColor,
              //       autoAdjustBrightness: true,
              //     ),
              //   ],
              // ),
              // Flexible(
              //   child: Padding(
              //     padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              //     child: tiamat.Text(
              //       body ?? "Unknown",
              //       maxLines: 2,
              //       overflow: TextOverflow.ellipsis,
              //       color: material.Theme.of(context).colorScheme.secondary,
              //     ),
              //   ),
              // ),
            ]),
          ),
        ),
      ),
    );
  }
}

class ReplyLinePainter2 extends CustomPainter {
  Color pathColor;
  double strokeWidth;
  double radius;
  double padding;
  double avatarSize;
  ReplyLinePainter2(
      {this.pathColor = Colors.white,
      this.strokeWidth = 1.5,
      this.radius = 5,
      this.avatarSize = 32,
      this.padding = 4}) {
    _paint = Paint()
      ..color = pathColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
  }

  late Paint _paint;

  @override
  void paint(Canvas canvas, Size size) {
    Path path = Path();
    path.moveTo(avatarSize / 2, size.height - padding);
    path.relativeLineTo(0, (-size.height + 9 + padding) + radius);
    path.relativeArcToPoint(Offset(radius, -radius),
        radius: Radius.circular(radius));
    path.relativeLineTo(size.width - (avatarSize / 2) - radius - padding, 0);
    canvas.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
