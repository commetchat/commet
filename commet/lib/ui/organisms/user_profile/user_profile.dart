import 'package:commet/client/client.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/profile.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/ui/organisms/user_profile/user_profile_view.dart';
import 'package:flutter/material.dart';

class UserProfile extends StatefulWidget {
  const UserProfile(
      {super.key, required this.userId, required this.client, this.dismiss});
  final Client client;
  final String userId;
  final Function? dismiss;

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  Profile? profile;

  @override
  void initState() {
    super.initState();
    widget.client.getProfile(widget.userId).then((value) => setState(() {
          profile = value;
        }));
  }

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return UserProfileView(
      userAvatar: profile!.avatar,
      displayName: profile!.displayName,
      identifier: profile!.identifier,
      userColor: profile!.defaultColor,
      isSelf: widget.client.self == profile,
      onMessageButtonClicked: openDirectMessage,
    );
  }

  Future<void> openDirectMessage() async {
    final component = widget.client.getComponent<DirectMessagesComponent>();
    if (component == null) {
      return;
    }

    var existingRooms = component.directMessageRooms.where((element) =>
        profile!.identifier == component.getDirectMessagePartnerId(element));

    if (existingRooms.isNotEmpty == true) {
      EventBus.openRoom
          .add((existingRooms.first.identifier, widget.client.identifier));
    } else {
      var room = await component.createDirectMessage(profile!.identifier);
      if (room != null) {
        EventBus.openRoom.add((room.identifier, widget.client.identifier));
      }
    }

    widget.dismiss?.call();
  }
}
