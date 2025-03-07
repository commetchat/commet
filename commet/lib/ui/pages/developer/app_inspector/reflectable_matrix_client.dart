import 'package:commet/ui/pages/developer/app_inspector/value_reflector_widget.dart';
import 'package:matrix/matrix.dart' as matrix;

@Reflector()
class ReflectableMatrixClient extends matrix.Client {
  ReflectableMatrixClient(super.clientName);
}

@Reflector()
class ReflectableMatrixRoom extends matrix.Room {
  ReflectableMatrixRoom({required super.id, required super.client});
}

@Reflector()
class ReflectableMatrixEvent extends matrix.Event {
  ReflectableMatrixEvent(
      {required super.content,
      required super.type,
      required super.eventId,
      required super.senderId,
      required super.originServerTs,
      required super.room});
}
