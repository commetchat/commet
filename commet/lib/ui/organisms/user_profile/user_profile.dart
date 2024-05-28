import 'package:commet/client/client.dart';
import 'package:commet/client/profile.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/ui/organisms/user_profile/user_profile_view.dart';
import 'package:flutter/material.dart';

class UserProfile extends StatelessWidget {
  const UserProfile(
      {super.key, required this.user, required this.client, this.dismiss});
  final Client client;
  final Profile user;
  final Function? dismiss;

  @override
  Widget build(BuildContext context) {
    return UserProfileView(
      userAvatar: user.avatar,
      displayName: user.displayName,
      identifier: user.identifier,
      userColor: user.defaultColor,
      isSelf: client.self == user,
      onMessageButtonClicked: openDirectMessage,
    );
  }

  Future<void> openDirectMessage() async {
    var existingRooms = client.directMessages
        .where((element) => user.identifier == element.directMessagePartnerID);

    if (existingRooms.isNotEmpty) {
      EventBus.openRoom
          .add((existingRooms.first.identifier, client.identifier));
    } else {
      var room = await client.createDirectMessage(user.identifier);
      if (room != null) {
        EventBus.openRoom.add((room.identifier, client.identifier));
      }
    }

    dismiss?.call();
  }
}
