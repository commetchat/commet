import 'package:commet/ui/pages/developer/app_inspector/value_reflector_widget.dart';
import 'package:matrix/matrix.dart' as matrix;
// ignore: implementation_imports
import 'package:matrix/src/utils/space_child.dart';

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

@Reflector()
class ReflectableMatrixSpaceChild extends SpaceChild {
  ReflectableMatrixSpaceChild.fromState(super.state) : super.fromState();
}

@Reflector()
class ReflectableMatrixSpaceParent extends SpaceParent {
  ReflectableMatrixSpaceParent.fromState(super.state) : super.fromState();
}

@Reflector()
class ReflectableMatrixBasicEvent extends matrix.BasicEvent {
  ReflectableMatrixBasicEvent({required super.type, required super.content});
}
