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
