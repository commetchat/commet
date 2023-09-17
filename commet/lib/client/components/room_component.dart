import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';

abstract class RoomComponent<R extends Client, T extends Room>
    extends Component<R> {
  late T _room;
  T get room => _room;

  RoomComponent(R client, T room) : super(client) {
    _room = room;
  }
}
