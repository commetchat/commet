import 'package:commet/client/client.dart';
import 'package:commet/client/components/room_component.dart';
import 'package:commet/client/member.dart';

abstract class TypingIndicatorComponent<R extends Client, T extends Room>
    implements RoomComponent<R, T> {
  Stream<void> get onTypingUsersUpdated;

  List<Member> get typingUsers;

  Future<void> setTypingStatus(bool status);
}
