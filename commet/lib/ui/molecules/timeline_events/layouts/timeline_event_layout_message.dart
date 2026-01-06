import 'package:commet/diagnostic/benchmark_values.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class TimelineEventLayoutMessage extends StatelessWidget {
  const TimelineEventLayoutMessage(
      {super.key,
      required this.senderName,
      required this.senderColor,
      this.senderAvatar,
      this.formattedContent,
      this.attachments,
      this.inResponseTo,
      this.reactions,
      this.timestamp,
      this.sticker,
      this.thread,
      this.urlPreviews,
      this.onAvatarTapped,
      this.edited = false,
      this.avatarSize = 32,
      this.showSender = true});
  final String senderName;
  final Color senderColor;
  final ImageProvider? senderAvatar;
  final Widget? formattedContent;
  final Widget? attachments;
  final Widget? inResponseTo;
  final Widget? reactions;
  final Widget? urlPreviews;
  final Widget? thread;
  final Widget? sticker;
  final bool showSender;
  final bool edited;
  final String? timestamp;
  final Function()? onAvatarTapped;

  final double avatarSize;

  String get messageEditedMarker => Intl.message("(Edited)",
      name: "messageEditedMarker",
      desc: "Short text to mark that a message has been edited");

  @override
  Widget build(BuildContext context) {
    BenchmarkValues.numTimelineMessageBodyBuilt += 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
      child: Column(
        children: [
          if (inResponseTo != null) inResponseTo!,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar(),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showSender)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            name(),
                            if (timestamp != null)
                              tiamat.Text.labelLow(timestamp!),
                          ],
                        ),
                      if (formattedContent != null)
                        RepaintBoundary(child: formattedContent!),
                      if (edited) tiamat.Text.labelLow(messageEditedMarker),
                      if (attachments != null) attachments!,
                      if (sticker != null) sticker!,
                      if (urlPreviews != null) urlPreviews!,
                      if (reactions != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                          child: reactions!,
                        ),
                    ],
                  ),
                ),
              )
            ],
          ),
          if (thread != null) thread!,
        ],
      ),
    );
  }

  Widget name() {
    return SelectionContainer.disabled(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onAvatarTapped,
          child: tiamat.Text.name(
            senderName,
            color: senderColor,
          ),
        ),
      ),
    );
  }

  SizedBox avatar() {
    return SizedBox(
      width: avatarSize,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onAvatarTapped,
          child: tiamat.Avatar(
            radius: avatarSize / 2,
            image: senderAvatar,
            placeholderText: senderName,
            placeholderColor: senderColor,
            isPadding: showSender == false,
          ),
        ),
      ),
    );
  }
}
