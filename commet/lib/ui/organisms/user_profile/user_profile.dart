import 'package:commet/client/client.dart';
import 'package:commet/ui/navigation/navigation_signals.dart';
import 'package:commet/ui/organisms/user_profile/user_profile_view.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@WidgetbookUseCase(name: 'User Profile', type: UserProfile)
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
      isSelf: user.client.user == user,
      onMessageButtonClicked: openDirectMessage,
    );
  }

  Future<void> openDirectMessage() async {
    var existingRooms = user.client.directMessages
        .where((element) => user.identifier == element.directMessagePartnerID);

    if (existingRooms.isNotEmpty) {
      NavigationSignals.openRoom.add(existingRooms.first.identifier);
    } else {
      var room = await user.client.createDirectMessage(user.identifier);
      if (room != null) {
        NavigationSignals.openRoom.add(room.identifier);
      }
    }

    dismiss?.call();
  }
}
