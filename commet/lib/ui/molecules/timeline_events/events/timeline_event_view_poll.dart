import 'package:commet/client/components/polls/poll_component.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/ui/molecules/timeline_events/layouts/timeline_event_layout_message.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_layout.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/error_utils.dart';
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
  int maxSelections = 0;
  bool showResults = false;
  bool canVote = false;
  List<PollAnswer> allowedAnswers = [];
  Map<String, Set<String>> pollResponses = {};
  TimelineEvent? event;

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
          if (!showResults)
            tiamat.Text.labelLow(
                "Results will be visible once the poll has ended")
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
      final e = widget.timeline.events[index];
      var sender = widget.timeline.room.getMemberOrFallback(e.senderId);

      senderId = sender.identifier;
      senderName = sender.displayName;
      senderAvatar = sender.avatar;
      senderColor = sender.defaultColor;
      maxSelections = polls!.getMaxSelections(e);
      showResults = polls!.shouldShowResults(e, widget.timeline);
      body = polls!.getPollQuestion(e);
      canVote = polls!.canVote(e, widget.timeline);
      allowedAnswers = polls!.getAllowedPollAnswers(e);
      pollResponses = polls!.getPollResponses(widget.timeline, e);
      event = e;
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

    return Material(
      clipBehavior: Clip.antiAlias,
      color: isOurResponse
          ? ColorScheme.of(context).primaryContainer
          : ColorScheme.of(context).surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onLongPress: () {
          AdaptiveDialog.show(
            context,
            scrollable: false,
            builder: (context) => SizedBox(
              height: 400,
              width: 400,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: tiamat.Text.largeTitle(answer.answer),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: responses?.length ?? 0,
                      itemBuilder: (context, index) {
                        final id = responses!.elementAt(index);
                        return UserPanel(
                            userId: id,
                            contextRoom: widget.timeline.room,
                            client: widget.timeline.client);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        onTap: !canVote
            ? null
            : () {
                List<PollAnswer> selectedAnswer;

                if (maxSelections > 1) {
                  selectedAnswer = allowedAnswers
                      .where((i) =>
                          pollResponses[i.id]?.contains(
                              widget.timeline.client.self!.identifier) ==
                          true)
                      .toList(growable: true);

                  if (isOurResponse) {
                    selectedAnswer.remove(answer);
                  } else {
                    selectedAnswer.add(answer);
                  }
                } else {
                  selectedAnswer = [answer];
                }

                ErrorUtils.tryRun(context, () async {
                  await polls?.setAnswer(
                    event!,
                    widget.timeline.room,
                    selectedAnswer,
                  );
                });
              },
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
                  if (showResults)
                    tiamat.Text(
                      (responses?.length ?? 0).toString(),
                      color: bodyColor,
                    )
                ],
              ),
              if (showResults)
                LinearProgressIndicator(
                    value: (responses?.length ?? 0) / mostVoted,
                    color: bodyColor),
            ],
          ),
        ),
      ),
    );
  }
}
