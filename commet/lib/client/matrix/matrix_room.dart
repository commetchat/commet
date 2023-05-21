import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/client/matrix/matrix_room_permissions.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';

import '../client.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixRoom extends Room {
  late matrix.Room _matrixRoom;

  @override
  bool get isMember => _matrixRoom.membership == matrix.Membership.join;

  @override
  bool get isE2EE => _matrixRoom.encrypted;

  @override
  int get highlightedNotificationCount => _matrixRoom.highlightCount;

  @override
  int get notificationCount => _matrixRoom.notificationCount;

  @override
  PushRule get pushRule {
    switch (_matrixRoom.pushRuleState) {
      case matrix.PushRuleState.notify:
        return PushRule.notify;
      case matrix.PushRuleState.mentionsOnly:
        return PushRule.notify;
      case matrix.PushRuleState.dontNotify:
        return PushRule.dontNotify;
    }
  }

  MatrixRoom(client, matrix.Room room, matrix.Client matrixClient)
      : super(room.id, client) {
    _matrixRoom = room;

    if (room.avatar != null) {
      avatar = MatrixMxcImage(room.avatar!, _matrixRoom.client);
    }

    isDirectMessage = _matrixRoom.isDirectChat;

    if (isDirectMessage) {
      directMessagePartnerID = _matrixRoom.directChatMatrixID!;
    }

    displayName = room.getLocalizedDisplayname();

    var users = room.getParticipants();

    for (var user in users) {
      if (!this.client.peerExists(user.id)) {
        this.client.addPeer(MatrixPeer(matrixClient, user.id));
      }
    }

    members =
        List.from(users.map((e) => this.client.getPeer(e.id)), growable: true);

    timeline = MatrixTimeline(client, this, room);

    _matrixRoom.onUpdate.stream.listen(onMatrixRoomUpdate);

    permissions = MatrixRoomPermissions(_matrixRoom);
  }

  @override
  Future<TimelineEvent?> sendMessage(String message,
      {TimelineEvent? inReplyTo}) async {
    matrix.Event? replyingTo;

    if (inReplyTo != null) {
      replyingTo = await _matrixRoom.getEventById(inReplyTo.eventId);
    }

    String? id =
        await _matrixRoom.sendTextEvent(message, inReplyTo: replyingTo);

    if (id != null) {
      var event = await _matrixRoom.getEventById(id);
      return (timeline as MatrixTimeline).convertEvent(event!);
    }

    return null;
  }

  @override
  Future<void> setDisplayNameInternal(String name) async {
    await _matrixRoom.setName(name);
  }

  @override
  Future<void> enableE2EE() async {
    await _matrixRoom.enableEncryption();
  }

  void onMatrixRoomUpdate(String event) async {
    displayName = _matrixRoom.getLocalizedDisplayname();
    onUpdate.add(null);
  }

  @override
  Future<void> setPushRule(PushRule rule) async {
    var newRule = _matrixRoom.pushRuleState;

    switch (rule) {
      case PushRule.notify:
        newRule = matrix.PushRuleState.notify;
        break;
      case PushRule.mentionsOnly:
        newRule = matrix.PushRuleState.mentionsOnly;
        break;
      case PushRule.dontNotify:
        newRule = matrix.PushRuleState.dontNotify;
        break;
    }

    await _matrixRoom.setPushRuleState(newRule);
    onUpdate.add(null);
  }
}
