import 'package:commet/client/timeline.dart';
import 'package:commet/diagnostic/benchmark_values.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:flutter/material.dart' as material;

class TimelineEventViewReply extends StatefulWidget {
  const TimelineEventViewReply(
      {super.key,
      required this.timeline,
      required this.index,
      this.avatarSize = 32});
  final Timeline timeline;
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

  @override
  void initState() {
    getStateFromIndex(widget.index);
    super.initState();
  }

  void getStateFromIndex(int index) {
    var event = widget.timeline.events[index];
    var replyEvent = widget.timeline.tryGetEvent(event.relatedEventId!);

    if (replyEvent == null) {
      loading = true;
      widget.timeline.room.getEvent(event.relatedEventId!).then((value) {
        if (mounted && value != null) {
          setStateFromEvent(value);
        }
      });
    } else {
      setStateFromEvent(replyEvent);
    }
  }

  void setStateFromEvent(TimelineEvent event) {
    setState(() {
      var sender = widget.timeline.room.getMemberOrFallback(event.senderId);
      senderName = sender.displayName;
      senderColor = sender.defaultColor;
      body = event.body ?? "";
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    BenchmarkValues.numTimelineReplyBodyBuilt += 1;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 45,
          child: SizedBox.expand(
            child: CustomPaint(
              painter: ReplyLinePainter2(
                  pathColor: material.Theme.of(context).colorScheme.secondary,
                  avatarSize: widget.avatarSize),
            ),
          ),
        ),
        Column(
          children: [
            tiamat.Text(
              senderName ?? "Loading",
              color: senderColor,
              autoAdjustBrightness: true,
            ),
          ],
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: tiamat.Text(
              body ?? "Unknown",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              color: material.Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      ]),
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
    path.relativeLineTo(0, (-size.height + 11 + padding) + radius);
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
