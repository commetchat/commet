import 'dart:async';
import 'dart:math';

import 'package:commet/client/client.dart';
import 'package:commet/client/member.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/atoms/shimmer_loading.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:flutter/material.dart';

import '../../client/room.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class RoomMemberList extends StatefulWidget {
  const RoomMemberList(this.room, {super.key});
  final Room room;

  @override
  State<RoomMemberList> createState() => _RoomMemberListState();
}

class _RoomMemberListState extends State<RoomMemberList> {
  late List<Member> roomMembers;
  bool loadingMoreMembers = false;

  int limit = 100;

  @override
  void initState() {
    roomMembers = widget.room.membersList();

    if (!widget.room.isMembersListComplete) {
      Log.d("Member list is not complete, loading more members!");
      loadingMoreMembers = true;

      widget.room.fetchMembersList().then((value) {
        if (mounted)
          setState(() {
            loadingMoreMembers = false;
            roomMembers = value;
          });
      });
    } else {
      Log.d("Member list is complete!");
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var count = roomMembers.length;
    count = min(count, limit);

    var diff = roomMembers.length - count;

    return ListView.builder(
        itemCount: loadingMoreMembers ? count + 1 : count,
        itemBuilder: (context, i) {
          if (loadingMoreMembers && i == count) return buildLoadingDisplay();

          Widget result = MemberPanel(
            roomMembers[i],
            userColor: widget.room.getColorOfUser(roomMembers[i].identifier),
          );
          if (!loadingMoreMembers && diff > 0 && i == count - 1) {
            result = Column(
              children: [
                result,
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 20, 8, 8),
                  child: tiamat.Button.secondary(
                    text: "+$diff more",
                    onTap: () => setState(() {
                      limit += 50;
                    }),
                  ),
                )
              ],
            );
          }

          return result;
        });
  }

  Widget buildLoadingDisplay() {
    return Shimmer(
      linearGradient: const LinearGradient(
        colors: [
          Color.fromARGB(200, 65, 65, 65),
          Color.fromARGB(200, 244, 244, 244),
          Color.fromARGB(200, 65, 65, 65),
        ],
        stops: [
          0.0,
          0.3,
          0.4,
        ],
        begin: Alignment(-1, 0),
        end: Alignment(1, 0),
        tileMode: TileMode.clamp,
      ),
      child: Column(
        children: [
          for (var i = 0; i < 15; i++)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
              child: UserPanelView(
                displayName: "$i",
                shimmer: true,
                random: Random(i).nextDouble(),
              ),
            )
        ],
      ),
    );
  }
}
