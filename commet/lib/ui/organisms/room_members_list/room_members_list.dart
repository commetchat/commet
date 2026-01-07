import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/room.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/ui/molecules/user_list.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isDirectMessage) const tiamat.Text.labelLow("Room Members"),
        Expanded(
          child: SizedBox(
            width: Layout.desktop
                ? isDirectMessage
                    ? 300
                    : 200
                : null,
            child: RoomMemberList(
                key: ValueKey(
                    "room-participant-list-key-${widget.room.localId}"),
                widget.room),
          ),
        ),
      ],
    );
  }
}
