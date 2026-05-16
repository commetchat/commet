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
  bool get canEditTopic =>
      room.canChangeStateEvent(matrix.EventTypes.RoomTopic);

  @override
  bool get canEnableE2EE => room.canChangeStateEvent("m.room.encryption");

  @override
  bool get canEditRoomEmoticons => room.canSendDefaultStates;

  @override
  bool get canDeleteOtherUserMessages => room.canRedact;

  @override
  bool get canEditChildren =>
      room.canChangeStateEvent(matrix.EventTypes.SpaceChild);

  @override
  bool get canInviteUser => room.canInvite;

  @override
  bool get canChangeRoles => room.canChangePowerLevel;

  @override
  bool get canMentionRoom => canUserMentionRoom(room.client.userID!, room);

  static bool canUserMentionRoom(String user, matrix.Room room) {
    int powerLevel = 50;

    var data = room
        .getState(matrix.EventTypes.RoomPowerLevels)
        ?.content
        .tryGetMap<String, int>('notifications');

    if (data != null) {
      var level = data["room"];

      if (level != null) powerLevel = level;
    }

    return room.getPowerLevelByUserId(user) >= powerLevel;
  }

  @override
  bool get canChangeVisibility =>
      room.canChangeStateEvent(matrix.EventTypes.RoomJoinRules);
}
