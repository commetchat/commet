import 'package:commet/client/components/polls/poll_component.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/ui/molecules/timeline_events/layouts/timeline_event_layout_message.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_layout.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class TimelineEventViewPoll extends StatefulWidget {
  const TimelineEventViewPoll(
      {required this.initialIndex, required this.timeline, super.key});

  final int initialIndex;
  final Timeline timeline;
  @override
  State<TimelineEventViewPoll> createState() => _TimelineEventViewPollState();
}

class _TimelineEventViewPollState extends State<TimelineEventViewPoll>
    implements TimelineEventViewWidget {
  PollComponent? polls;
  String? body;

  ImageProvider? senderAvatar;
  late String senderName;
  late String senderId;
  late Color senderColor;
  List<PollAnswer> allowedAnswers = [];
  Map<String, Set<String>> pollResponses = {};

  @override
  void initState() {
    polls = widget.timeline.client.getComponent<PollComponent>();
    setStateFromIndex(widget.initialIndex);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TimelineEventLayoutMessage(
      senderName: senderName,
      senderColor: senderColor,
      senderAvatar: senderAvatar,
      showSender: true,
      formattedContent: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          if (body != null) tiamat.Text.label(body!),
          for (var answer in allowedAnswers) buildAnswer(answer),
        ],
      ),
    );
  }

  @override
  void update(int newIndex) {
    setStateFromIndex(newIndex);
  }

  void setStateFromIndex(int index) {
    setState(() {
      final event = widget.timeline.events[index];

      var sender = widget.timeline.room.getMemberOrFallback(event.senderId);

      senderId = sender.identifier;
      senderName = sender.displayName;
      senderAvatar = sender.avatar;
      senderColor = sender.defaultColor;

      body = polls!.getPollQuestion(event);
      allowedAnswers = polls!.getAllowedPollAnswers(event);
      pollResponses = polls!.getPollResponses(widget.timeline, event);
    });
  }

  Widget buildAnswer(PollAnswer answer) {
    var responses = pollResponses[answer.id];

    var isOurResponse =
        responses?.contains(widget.timeline.client.self!.identifier) == true;

    int mostVoted = 1;

    if (responses != null) {
      for (var answer in allowedAnswers) {
        var r = pollResponses[answer.id];
        if (r != null) {
          var len = r.length;
          if (len > mostVoted) {
            mostVoted = len;
          }
        }
      }
    }

    var bodyColor = isOurResponse ? ColorScheme.of(context).onPrimary : null;

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: BoxBorder.all(
              color: ColorScheme.of(context).outlineVariant.withAlpha(200),
              width: 1),
          color: isOurResponse
              ? ColorScheme.of(context).primaryContainer
              : ColorScheme.of(context).surfaceContainerLow),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          spacing: 4,
          children: [
            Row(
              spacing: 8,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                tiamat.Text(
                  answer.answer,
                  color: bodyColor,
                ),
                tiamat.Text(
                  (responses?.length ?? 0).toString(),
                  color: bodyColor,
                )
              ],
            ),
            LinearProgressIndicator(
                value: (responses?.length ?? 0) / mostVoted, color: bodyColor)
          ],
        ),
      ),
    );
  }
}
