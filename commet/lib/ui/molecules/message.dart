import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/url_preview/url_preview_component.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/diagnostic/benchmark_values.dart';
import 'package:commet/ui/atoms/emoji_reaction.dart';
import 'package:commet/ui/molecules/url_preview_widget.dart';
import 'package:commet/utils/link_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:flutter/material.dart' as material;

import 'package:intl/intl.dart' as intl;

class Message extends StatefulWidget {
  const Message(
      {super.key,
      required this.senderName,
      required this.senderColor,
      required this.sentTimeStamp,
      required this.body,
      required this.currentUserIdentifier,
      this.senderAvatar,
      this.replyBody,
      this.replySenderColor,
      this.replySenderName,
      this.edited = false,
      this.showDetailed = false,
      this.onDoubleTap,
      this.reactions,
      this.onReactionTapped,
      this.onLongPress,
      this.links,
      this.loadingUrlPreviews = false,
      this.isInReply = false,
      this.child,
      this.showSender = true});
  final double avatarSize = 32;

  final bool showSender;
  final bool showDetailed;
  final String senderName;
  final Color? senderColor;

  final String? replyBody;
  final String? replySenderName;
  final Color? replySenderColor;
  final bool isInReply;

  final ImageProvider? senderAvatar;
  final DateTime sentTimeStamp;

  final String currentUserIdentifier;

  final bool edited;

  final Widget body;

  final Widget? child;

  final UrlPreviewData? links;
  final bool loadingUrlPreviews;

  final Map<Emoticon, Set<String>>? reactions;

  final Function()? onLongPress;
  final Function()? onDoubleTap;
  final Function(Emoticon emote)? onReactionTapped;

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> {
  bool hovered = false;
  bool editMode = false;

  String get messageEditedMarker => Intl.message("(Edited)",
      name: "messageEditedMarker",
      desc: "Short text to mark that a message has been edited");

  @override
  Widget build(BuildContext context) {
    return material.Material(
        color: material.Colors.transparent,
        child: BuildConfig.MOBILE
            ? material.InkWell(
                onLongPress: widget.onLongPress,
                onDoubleTap: widget.onDoubleTap,
                child: buildContent(),
              )
            : buildContent());
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isInReply) replyText(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar(),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.showSender)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              senderName(),
                              timeStamp(),
                            ],
                          ),
                        ),
                      body(),
                      if (widget.edited) edited(),
                      if (widget.child != null) widget.child!,
                      if (widget.links != null || widget.loadingUrlPreviews)
                        urlPreviews(),
                      if (widget.reactions != null) reactions(),
                    ],
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget urlPreviews() {
    BenchmarkValues.numTimelineUrlPreviewBuilt += 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 40, 0),
      child: UrlPreviewWidget(
        widget.links,
        onTap: () {
          LinkUtils.open(widget.links!.uri);
        },
      ),
    );
  }

  Widget avatar() {
    return SizedBox(
      width: widget.avatarSize,
      height: widget.showSender ? widget.avatarSize : 0,
      child: widget.showSender
          ? Avatar(
              radius: widget.avatarSize / 2,
              placeholderText: widget.senderName,
              image: widget.senderAvatar,
              placeholderColor: widget.senderColor,
            )
          : null,
    );
  }

  Widget senderName() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 4, 1),
      child: SizedBox(
        child: tiamat.Text.name(
          "${widget.senderName} ",
          color: widget.senderColor,
        ),
      ),
    );
  }

  Widget replyText() {
    BenchmarkValues.numTimelineReplyBodyBuilt += 1;
    return SizedBox(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.ideographic,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: widget.avatarSize / 2,
          ),
          SizedBox(
            width: 30,
            height: 20,
            child: CustomPaint(
              painter: ReplyLinePainter(
                  pathColor: Theme.of(context).colorScheme.secondary),
            ),
          ),
          tiamat.Text.name(
            widget.replySenderName ?? "Loading...",
            color: widget.replySenderColor,
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
              child: tiamat.Text(
                widget.replyBody ?? "Unknown",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                color: material.Theme.of(context).colorScheme.secondary,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget timeStamp() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
        child: SizedBox(
            child: tiamat.Text.labelLow(widget.showDetailed
                ? MediaQuery.of(context).alwaysUse24HourFormat
                    ? intl.DateFormat.yMMMMd()
                        .add_Hms()
                        .format(widget.sentTimeStamp.toLocal())
                    : intl.DateFormat.yMMMMd()
                        .add_jms()
                        .format(widget.sentTimeStamp.toLocal())
                : MediaQuery.of(context).alwaysUse24HourFormat
                    ? intl.DateFormat.Hm()
                        .format(widget.sentTimeStamp.toLocal())
                    : intl.DateFormat.jm()
                        .format(widget.sentTimeStamp.toLocal()))));
  }

  Widget body() {
    return widget.body;
  }

  Widget edited() {
    return tiamat.Text.labelLow(messageEditedMarker);
  }

  Widget reactions() {
    return Wrap(
        spacing: 3,
        runSpacing: 3,
        direction: material.Axis.horizontal,
        children: widget.reactions!.keys.map((key) {
          var value = widget.reactions![key]!;
          return EmojiReaction(
              emoji: key,
              onTapped: widget.onReactionTapped,
              numReactions: value.length,
              highlighted: value.contains(widget.currentUserIdentifier));
        }).toList());
  }
}

class ReplyLinePainter extends CustomPainter {
  Color pathColor;
  double strokeWidth;
  double radius;
  double padding;
  ReplyLinePainter(
      {this.pathColor = Colors.white,
      this.strokeWidth = 2,
      this.radius = 3,
      this.padding = 2}) {
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
    path.moveTo(0, size.height - padding);
    path.lineTo(0, (size.height / 2) + radius);
    path.relativeArcToPoint(Offset(radius, -radius),
        radius: Radius.circular(radius));
    path.lineTo(size.width - 5, size.height / 2);
    canvas.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class ThreadLinePainter extends CustomPainter {
  Color pathColor;
  double strokeWidth;
  double radius;
  double padding;
  ThreadLinePainter(
      {this.pathColor = Colors.white,
      this.strokeWidth = 2,
      this.radius = 3,
      this.padding = 2}) {
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
    path.moveTo(strokeWidth / 2, 0);
    path.relativeLineTo(0, (size.height / 2) - radius);
    path.relativeArcToPoint(
      Offset(radius, radius),
      clockwise: false,
      radius: Radius.circular(radius),
    );
    path.relativeLineTo(size.width - radius - strokeWidth, 0);
    canvas.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
