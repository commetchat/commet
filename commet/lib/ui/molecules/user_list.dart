import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:flutter/material.dart';

import '../../client/room.dart';

class PeerList extends StatefulWidget {
  const PeerList(this.room, {super.key});
  final Room room;

  @override
  State<PeerList> createState() => _PeerListState();
}

class _PeerListState extends State<PeerList> {
  int _count = 0;
  StreamSubscription? subscription;

  @override
  void initState() {
    _count = widget.room.memberIds.length;
    subscription = widget.room.membersUpdated.listen(onMembersListUpdated);
    //widget.room.loadMembers();
    super.initState();
  }

  void onMembersListUpdated(void event) {
    setState(() {
      _count = widget.room.memberIds.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _count,
      itemBuilder: (context, i) => UserPanel(
        widget.room.client.getPeer(widget.room.memberIds.elementAt(i)),
        userColor:
            widget.room.getColorOfUser(widget.room.memberIds.elementAt(i)),
      ),
    );
  }
}
