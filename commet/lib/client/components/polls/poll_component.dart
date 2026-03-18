import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';

class PollAnswer {
  String id;
  String answer;

  PollAnswer(this.id, this.answer);
}

class PollCreateArgs {
  String question;
  List<String> options;
  bool multiAnswer;
  bool publicAnswers;

  PollCreateArgs({
    required this.question,
    required this.options,
    this.multiAnswer = false,
    this.publicAnswers = false,
  });
}

abstract class PollComponent<R extends Client> implements Component<R> {
  Map<String, Set<String>> getPollResponses(
      Timeline timeline, TimelineEvent event);

  bool isPollEvent(TimelineEvent event);

  String getPollQuestion(TimelineEvent event);

  int getMaxSelections(TimelineEvent event);

  bool shouldShowResults(TimelineEvent<Client> event, Timeline timeline);

  bool isFinished(TimelineEvent<Client> event, Timeline timeline);

  List<PollAnswer> getAllowedPollAnswers(TimelineEvent event);

  Future<void> createPoll(Room room, PollCreateArgs args);

  Future<void> endPoll(Room room, TimelineEvent event);

  bool canEndPoll(Room room, TimelineEvent event, Timeline timeline);

  Future<void> setAnswer(
      TimelineEvent event, Room room, List<PollAnswer> answer);
}
