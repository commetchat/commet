import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';

class PollAnswer {
  String id;
  String answer;

  PollAnswer(this.id, this.answer);
}

abstract class PollComponent<R extends Client> implements Component<R> {
  Map<String, Set<String>> getPollResponses(
      Timeline timeline, TimelineEvent event);

  bool isPollEvent(TimelineEvent event);

  String getPollQuestion(TimelineEvent event);

  int getMaxSelections(TimelineEvent event);

  bool shouldShowResults(TimelineEvent<Client> event, Timeline timeline);

  bool canVote(TimelineEvent<Client> event, Timeline timeline);

  List<PollAnswer> getAllowedPollAnswers(TimelineEvent event);

  Future<void> setAnswer(
      TimelineEvent event, Room room, List<PollAnswer> answer);
}
