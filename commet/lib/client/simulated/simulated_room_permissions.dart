import '../permissions.dart';

class SimulatedRoomPermissions implements Permissions {
  @override
  bool get canBan => true;

  @override
  bool get canChangeSettings => true;

  @override
  bool get canKick => true;

  @override
  bool get canSendMessage => true;
}
