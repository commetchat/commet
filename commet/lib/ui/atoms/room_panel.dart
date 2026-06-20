import 'dart:async';

import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/components/user_presence/user_presence_component.dart';
import 'package:commet/client/room.dart';
import 'package:commet/ui/atoms/adaptive_context_menu.dart';
import 'package:commet/ui/atoms/room_panel_view.dart';
import 'package:commet/ui/atoms/room_text_button.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';

class RoomPanel extends StatefulWidget {
  const RoomPanel(this.room,
      {this.onTap, super.key, this.shouldShowAvatarForRoom});

  final Room room;
  final Function()? onTap;

  @override
  State<RoomPanel> createState() => _RoomPanelState();

  final bool Function(Room room)? shouldShowAvatarForRoom;
}

class _RoomPanelState extends State<RoomPanel> {
  late List<StreamSubscription> subs;
  String? directMessagePartner;
  UserPresence? presence = null;

  @override
  void initState() {
    subs = List.empty(growable: true);
    subs.add(widget.room.onUpdate.listen((_) => setState(() {})));

    var dm = widget.room.client.getComponent<DirectMessagesComponent>();
    directMessagePartner = dm?.getDirectMessagePartnerId(widget.room);

    if (directMessagePartner != null) {
      final presenceComponent =
          widget.room.client.getComponent<UserPresenceComponent>();

      if (presenceComponent == null) {
        return;
      }

      presenceComponent
          .getUserPresence(directMessagePartner!)
          .then((s) => setState(() {
                presence = s;
              }));

      subs.add(presenceComponent.onPresenceChanged
          .where((tuple) => tuple.$1 == directMessagePartner)
          .listen(userPresenceChanged));
    }

    super.initState();
  }

  @override
  void dispose() {
    for (var sub in subs) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDm = directMessagePartner != null;
    String? eventSender = widget.room.lastMessage?.senderId;

    if (eventSender != null) {
      if (eventSender == widget.room.client.self!.identifier) {
        eventSender = "You";
      } else {
        if (isDm) {
          eventSender = null;
        } else {
          var member = widget.room.getMemberOrFallback(eventSender);
          eventSender = member.displayName;
        }
      }
    }

    return AdaptiveContextMenu(
      items: RoomTextButton.createRoomContextMenuItems(context, widget.room),
      child: RoomPanelView(
        displayName: widget.room.displayName,
        avatar: widget.room.avatar,
        onTap: widget.onTap ??
            () {
              EventBus.doOpenRoom(widget.room.identifier,
                  clientId: widget.room.client.identifier);
            },
        color: widget.room.defaultColor,
        showUserAvatar: widget.shouldShowAvatarForRoom == null
            ? false
            : widget.shouldShowAvatarForRoom!(widget.room),
        userColor: widget.room.client.self?.defaultColor,
        userDisplayName: widget.room.client.self?.displayName,
        userAvatar: widget.room.client.self?.avatar,
        directMessagePartner: directMessagePartner,
        userPresence: presence,
        recentEventSender: eventSender,
        recentEventSenderColor: widget.room.lastMessage != null
            ? widget.room.getColorOfUser(widget.room.lastMessage!.senderId)
            : null,
        body: widget.room.lastMessage?.plainTextBody,
        notificationCount: widget.room.notificationCount,
      ),
    );
  }

  void userPresenceChanged((String, UserPresence) event) {
    if (mounted) {
      setState(() {
        presence = event.$2;
      });
    }
  }
}
