import 'package:matrix/matrix.dart' as matrix;

import '../permissions.dart';

class MatrixRoomPermissions extends Permissions {
  late matrix.Room room;

  MatrixRoomPermissions(this.room);

  @override
  bool get canBan => room.canBan;

  @override
  bool get canKick => room.canKick;

  @override
  bool get canSendMessage => room.canSendDefaultMessages;

  @override
  bool get canEditAvatar => room.canChangeStateEvent("m.room.avatar");

  @override
  bool get canEditName => room.canChangeStateEvent("m.room.name");

  @override
  bool get canEnableE2EE => room.canChangeStateEvent("m.room.encryption");

  @override
  bool get canEditRoomEmoticons => room.canSendDefaultStates;
}
