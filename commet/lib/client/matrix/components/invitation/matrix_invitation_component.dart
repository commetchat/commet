import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/invitation/invitation.dart';
import 'package:commet/client/components/invitation/invitation_component.dart';
import 'package:commet/client/components/profile/profile_component.dart';
import 'package:commet/client/matrix/components/profile/matrix_profile_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixInvitationComponent
    implements InvitationComponent<MatrixClient>, NeedsPostLoginInit {
  @override
  final MatrixClient client;

  @override
  NotifyingList<Invitation> invitations = NotifyingList.empty(growable: true);

  MatrixInvitationComponent(this.client);

  @override
  Future<void> acceptInvitation(Invitation invitation) async {
    var mx = client.getMatrixClient();
    await mx.joinRoom(invitation.roomId);
    invitations.remove(invitation);
  }

  @override
  Future<void> rejectInvitation(Invitation invitation) async {
    var mx = client.getMatrixClient();
    await mx.leaveRoom(invitation.roomId);
    invitations.remove(invitation);
  }

  @override
  void postLoginInit() {
    Log.i("Loading invite list!");
    _updateInviteList();

    client.onSync.listen((_) => _updateInviteList());
  }

  void _updateInviteList() async {
    var mx = client.getMatrixClient();
    var invitedRooms = mx.rooms.where((element) => element.membership.isInvite);

    for (var room in invitedRooms) {
      if (invitations
          .where((element) => element.roomId == room.id)
          .isNotEmpty) {
        continue;
      }

      var state = room.states[matrix.EventTypes.RoomMember]?[mx.userID];
      var sender = state?.senderId;

      var avatar =
          room.avatar != null ? MatrixMxcImage(room.avatar!, mx) : null;

      var entry = Invitation(
          roomId: room.id,
          avatar: avatar,
          senderId: sender,
          color: MatrixPeer.hashColor(room.id),
          displayName: room.getLocalizedDisplayname());

      invitations.add(entry);
    }
  }

  @override
  Future<void> inviteUserToRoom(
      {required String userId, required String roomId}) {
    var mx = client.getMatrixClient();
    return mx.inviteUser(roomId, userId);
  }

  @override
  Future<List<Profile>> searchUsers(String term) async {
    var mx = client.getMatrixClient();
    var result = await mx.searchUserDirectory(term);

    var finalResult =
        result.results.map((e) => MatrixProfile(client, e)).toList();
    if (term.isValidMatrixId && !finalResult.any((i) => i.identifier == term)) {
      finalResult = [
        MatrixProfile(
            client, matrix.Profile(userId: term, displayName: term.localpart)),
        ...finalResult
      ];
    }

    return finalResult;
  }
}
