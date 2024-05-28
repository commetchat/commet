import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/invitation/invitation.dart';
import 'package:commet/client/profile.dart';
import 'package:commet/utils/notifying_list.dart';

abstract class InvitationComponent<T extends Client> implements Component<T> {
  NotifyingList<Invitation> get invitations;

  Future<void> acceptInvitation(Invitation invitation);

  Future<void> rejectInvitation(Invitation invitation);

  Future<void> inviteUserToRoom(
      {required String userId, required String roomId});

  Future<List<Profile>> searchUsers(String term);
}
