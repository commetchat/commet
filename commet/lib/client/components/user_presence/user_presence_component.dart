import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';

enum UserPresenceStatus {
  offline,
  unknown,
  online,
  unavailable,
}

enum PresenceMessageType {
  userCustom,
}

class UserPresenceMessage {
  PresenceMessageType messageType;
  String message;

  UserPresenceMessage(this.message, this.messageType);
}

class UserPresence {
  UserPresenceStatus status;
  UserPresenceMessage? message;

  UserPresence(this.status, {this.message});
}

abstract class UserPresenceComponent<T extends Client> implements Component<T> {
  Stream<(String, UserPresence)> get onPresenceChanged;

  Future<UserPresence> getUserPresence(String userId);

  Future<void> setStatus(UserPresenceStatus status,
      {String? message, bool clearMessage = false});
}
