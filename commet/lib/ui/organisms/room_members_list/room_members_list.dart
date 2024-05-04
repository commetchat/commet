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
  @override
  Widget build(BuildContext context) {
    var iconSize = Layout.mobile ? 40.0 : 35.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            tiamat.Text.labelLow("Room Members"),
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: tiamat.IconButton(
                icon: Icons.person_add,
                size: iconSize / 2,
                onPressed: () => AdaptiveDialog.show(context,
                    builder: (context) => SendInvitationWidget(),
                    title: "Invite"),
              ),
            ),
          ],
        ),
        Expanded(
          child: PeerList(
              key: ValueKey("room-participant-list-key-${widget.room.localId}"),
              widget.room),
        ),
      ],
    );
  }
}
