import 'package:commet/debug/log.dart';
import 'package:commet/diagnostic/benchmark_values.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
      this.avatarSize = 32,
      this.showSender = true});
  final String senderName;
  final Color senderColor;
  final ImageProvider? senderAvatar;
  final Widget? formattedContent;
  final Widget? attachments;
  final Widget? inResponseTo;
  final Widget? reactions;
  final bool showSender;

  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    BenchmarkValues.numTimelineMessageBodyBuilt += 1;
    Log.d(
        "Num times messageevent body built: ${BenchmarkValues.numTimelineMessageBodyBuilt}");
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
                      if (showSender) name(),
                      if (formattedContent != null)
                        RepaintBoundary(child: formattedContent!),
                      if (attachments != null) attachments!,
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
          )
        ],
      ),
    );
  }

  tiamat.Text name() {
    return tiamat.Text.name(
      senderName,
      color: senderColor,
    );
  }

  SizedBox avatar() {
    return SizedBox(
      width: avatarSize,
      child: tiamat.Avatar(
        radius: avatarSize / 2,
        image: senderAvatar,
        placeholderText: senderName,
        placeholderColor: senderColor,
        isPadding: showSender == false,
      ),
    );
  }
}
