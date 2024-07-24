import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/timeline.dart';

abstract class TimelineEventFeatureReactions {
  bool hasReactions(Timeline timeline);

  Map<Emoticon, Set<String>> getReactions(Timeline timeline);
}
