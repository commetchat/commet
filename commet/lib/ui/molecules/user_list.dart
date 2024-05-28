import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/member.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:flutter/material.dart';

import '../../client/room.dart';

class RoomMemberList extends StatefulWidget {
  const RoomMemberList(this.room, {super.key});
  final Room room;

  @override
  State<RoomMemberList> createState() => _RoomMemberListState();
}

class _RoomMemberListState extends State<RoomMemberList> {
  List<Member>? roomMembers;

  @override
  void initState() {
    widget.room.fetchMembersList().then((value) => setState(() {
          roomMembers = value;
        }));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (roomMembers == null) {
      return CircularProgressIndicator();
    }
    return ListView.builder(
      itemCount: roomMembers!.length,
      itemBuilder: (context, i) => MemberPanel(
        roomMembers![i],
        userColor: widget.room.getColorOfUser(roomMembers![i].identifier),
      ),
    );
  }
}
