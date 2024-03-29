import 'package:commet/client/client.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/ui/organisms/user_profile/user_profile_view.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'User Profile', type: UserProfile)
@Deprecated("widgetbook")
Widget wbUserProfile(BuildContext context) {
  return const Center(
    child: SizedBox(
      child: UserProfileView(
        displayName: "Example User",
        identifier: "user@commet.chat",
        userColor: Colors.redAccent,
        isSelf: false,
      ),
    ),
  );
}

class UserProfile extends StatelessWidget {
  const UserProfile({super.key, required this.user, this.dismiss});
  final Peer user;
  final Function? dismiss;

  @override
  Widget build(BuildContext context) {
    return UserProfileView(
      userAvatar: user.avatar,
      displayName: user.displayName,
      identifier: user.identifier,
      userColor: user.defaultColor,
      isSelf: user.client.self == user,
      onMessageButtonClicked: openDirectMessage,
    );
  }

  Future<void> openDirectMessage() async {
    var existingRooms = user.client.directMessages
        .where((element) => user.identifier == element.directMessagePartnerID);

    if (existingRooms.isNotEmpty) {
      EventBus.openRoom
          .add((existingRooms.first.identifier, user.client.identifier));
    } else {
      var room = await user.client.createDirectMessage(user.identifier);
      if (room != null) {
        EventBus.openRoom.add((room.identifier, user.client.identifier));
      }
    }

    dismiss?.call();
  }
}
