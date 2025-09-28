import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/ui/organisms/chat/chat.dart';

abstract class CommandComponent<T extends Client> implements Component<T> {
  List<String> getCommands();

  bool isExecutable(String string);

  // Check if a string *could* be a command, but isn't necessarily valid
  bool isPossiblyCommand(String string);

  Future<void> executeCommand(String string, Room room,
      {TimelineEvent? interactingEvent, EventInteractionType? type});
}
