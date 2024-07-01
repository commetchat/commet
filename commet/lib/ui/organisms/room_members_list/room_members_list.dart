import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/components/invitation/invitation_component.dart';
import 'package:commet/client/room.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/ui/molecules/user_list.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/organisms/invitation_view/send_invitation.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomMembersListWidget extends StatefulWidget {
  const RoomMembersListWidget(this.room, {super.key});
  final Room room;

  @override
  State<RoomMembersListWidget> createState() => _RoomMembersListWidgetState();
}

class _RoomMembersListWidgetState extends State<RoomMembersListWidget> {
  late bool isDirectMessage;
  @override
  void initState() {
    isDirectMessage = widget.room.client
            .getComponent<DirectMessagesComponent>()
            ?.isRoomDirectMessage(widget.room) ??
        false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var iconSize = Layout.mobile ? 40.0 : 35.0;
    var invitation = widget.room.client.getComponent<InvitationComponent>();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const tiamat.Text.labelLow("Room Members"),
            if (invitation != null &&
                !isDirectMessage &&
                widget.room.permissions.canInviteUser)
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: tiamat.IconButton(
                  icon: Icons.person_add,
                  size: iconSize / 2,
                  onPressed: () => AdaptiveDialog.show(context,
                      builder: (context) =>
                          SendInvitationWidget(widget.room, invitation),
                      title: "Invite"),
                ),
              ),
          ],
        ),
        Expanded(
          child: RoomMemberList(
              key: ValueKey("room-participant-list-key-${widget.room.localId}"),
              widget.room),
        ),
      ],
    );
  }
}
