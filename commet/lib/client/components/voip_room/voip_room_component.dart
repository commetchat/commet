import 'package:commet/client/client.dart';
import 'package:commet/client/components/room_component.dart';

abstract class VoipRoomComponent<R extends Client, T extends Room>
    implements RoomComponent<R, T> {
  bool get isVoipRoom;
}
