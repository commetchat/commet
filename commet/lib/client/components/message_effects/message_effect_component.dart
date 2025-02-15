import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';

abstract class MessageEffectComponent<T extends Client>
    implements Component<T> {
  void doEffect(TimelineEvent event);

  bool hasEffect(TimelineEvent event);
}
