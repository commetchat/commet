import 'package:commet/client/client.dart';
import 'package:commet/client/components/polls/poll_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/utils/rng.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:matrix/msc_extensions/msc_3381_polls/poll_event_extension.dart';

class MatrixPollComponent implements PollComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixPollComponent(this.client);

  bool isPollEvent(TimelineEvent event) {
    var e = event as MatrixTimelineEvent;

    return e.event.type == "org.matrix.msc3381.poll.start";
  }

  @override
  List<PollAnswer> getAllowedPollAnswers(TimelineEvent event) {
    var mxEvent = (event as MatrixTimelineEvent).event;

    return mxEvent.parsedPollEventContent.pollStartContent.answers
        .map((i) => PollAnswer(i.id, i.mText))
        .toList();
  }

  @override
  int getMaxSelections(TimelineEvent event) {
    var mxEvent = (event as MatrixTimelineEvent).event;

    return mxEvent.parsedPollEventContent.pollStartContent.maxSelections;
  }

  @override
  Map<String, Set<String>> getPollResponses(
      Timeline timeline, TimelineEvent event) {
    Map<String, Set<String>> responses = {};

    var mxEvent = (event as MatrixTimelineEvent).event;

    var mxResponses =
        mxEvent.getPollResponses((timeline as MatrixTimeline).matrixTimeline!);

    for (var userId in mxResponses.keys) {
      for (var answer in mxResponses[userId]!) {
        if (responses.containsKey(answer) == false) {
          responses[answer] = Set();
        }
        responses[answer]!.add(userId);
      }
    }

    return responses;
  }

  @override
  String getPollQuestion(TimelineEvent<Client> event) {
    var mxEvent = (event as MatrixTimelineEvent).event;

    return mxEvent.parsedPollEventContent.pollStartContent.question.mText;
  }

  @override
  Future<void> setAnswer(
      TimelineEvent<Client> event, Room room, List<PollAnswer> answers) async {
    var mxEvent = (event as MatrixTimelineEvent).event;
    await mxEvent.answerPoll(answers.map((i) => i.id).toList());
  }

  @override
  bool shouldShowResults(TimelineEvent<Client> event, Timeline timeline) {
    var mxEvent = (event as MatrixTimelineEvent).event;

    if (mxEvent.parsedPollEventContent.pollStartContent.kind ==
        matrix.PollKind.disclosed) {
      return true;
    }

    return mxEvent
        .getPollHasBeenEnded((timeline as MatrixTimeline).matrixTimeline!);
  }

  @override
  bool isFinished(TimelineEvent<Client> event, Timeline timeline) {
    var mxEvent = (event as MatrixTimelineEvent).event;

    return mxEvent
        .getPollHasBeenEnded((timeline as MatrixTimeline).matrixTimeline!);
  }

  @override
  Future<void> createPoll(Room room, PollCreateArgs args) async {
    await (room as MatrixRoom).matrixRoom.startPoll(
        question: args.question,
        answers: args.options
            .map((i) => matrix.PollAnswer(
                id: RandomUtils.getRandomString(10), mText: i))
            .toList(),
        kind: args.publicAnswers
            ? matrix.PollKind.disclosed
            : matrix.PollKind.undisclosed,
        maxSelections: args.multiAnswer ? args.options.length : 1);
  }

  @override
  bool canEndPoll(Room room, TimelineEvent<Client> event, Timeline timeline) {
    if (isFinished(event, timeline)) {
      return false;
    }

    return event.senderId == room.client.self!.identifier;
  }

  @override
  Future<void> endPoll(Room room, TimelineEvent<Client> event) async {
    var mxEvent = (event as MatrixTimelineEvent).event;
    await mxEvent.endPoll();
  }
}
