import '../permissions.dart';

class SimulatedRoomPermissions extends Permissions {
  @override
  bool get canBan => true;

  @override
  bool get canKick => true;

  @override
  bool get canSendMessage => true;

  @override
  bool get canEditAvatar => true;

  @override
  bool get canEditName => true;
}
