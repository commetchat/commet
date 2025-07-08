import 'package:commet/client/client.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/components/event_search/event_search_component.dart';
import 'package:commet/client/components/invitation/invitation_component.dart';
import 'package:commet/client/components/pinned_messages/pinned_messages_component.dart';
import 'package:commet/client/components/voip/voip_component.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/organisms/invitation_view/send_invitation.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';

class RoomQuickAccessMenu {
  final Room room;
  late final List<RoomQuickAccessMenuEntry> actions;

  RoomQuickAccessMenu({required this.room}) {
    final bool canSearch =
        room.client.getComponent<EventSearchComponent>() != null;

    final invitation = room.client.getComponent<InvitationComponent>();

    final bool supportsPinnedMessages =
        room.getComponent<PinnedMessagesComponent>() != null;

    final calls = room.client.getComponent<VoipComponent>();
    final direct = room.client.getComponent<DirectMessagesComponent>();
    final bool canCall =
        calls != null && direct?.isRoomDirectMessage(room) == true;

    actions = [
      if (invitation != null)
        RoomQuickAccessMenuEntry(
            name: "Invite",
            action: (context) => AdaptiveDialog.show(context,
                builder: (context) => SendInvitationWidget(room, invitation),
                title: "Invite"),
            icon: Icons.person_add),
      if (supportsPinnedMessages)
        RoomQuickAccessMenuEntry(
            name: "Pinned Messages",
            action: (context) => EventBus.openPinnedMessages.add(null),
            icon: Icons.push_pin),
      if (canSearch)
        RoomQuickAccessMenuEntry(
            name: "Search",
            action: (context) => EventBus.startSearch.add(null),
            icon: Icons.search),
      if (canCall)
        RoomQuickAccessMenuEntry(
            name: "Call",
            action: (context) =>
                calls.startCall(room.identifier, CallType.voice),
            icon: Icons.call),
    ];
  }
}

class RoomQuickAccessMenuEntry {
  final String name;
  final Function(BuildContext context)? action;
  final IconData icon;

  RoomQuickAccessMenuEntry(
      {required this.name, required this.action, required this.icon});
}
