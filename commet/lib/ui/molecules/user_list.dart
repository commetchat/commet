import 'dart:math';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/member.dart';
import 'package:commet/client/role.dart';
import 'package:commet/ui/atoms/role_view.dart';
import 'package:commet/ui/atoms/shimmer_loading.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import '../../client/room.dart';

class RoomMemberList extends StatefulWidget {
  const RoomMemberList(this.room, {super.key});
  final Room room;

  @override
  State<RoomMemberList> createState() => _RoomMemberListState();
}

class _RoomMemberListState extends State<RoomMemberList> {
  late List<Member> roomMembers;
  List<(Member, Role)>? importantMembers;
  bool loadingMoreMembers = false;
  bool isDirectMessageRoom = false;
  DirectMessagesComponent? directMessages;

  int limit = 100;

  @override
  void initState() {
    getInitialUsers();
    isDirectMessageRoom = widget.room.client
            .getComponent<DirectMessagesComponent>()
            ?.isRoomDirectMessage(widget.room) ??
        false;

    if (!widget.room.isMembersListComplete) {
      loadAllUsers();
    }

    super.initState();
  }

  void getInitialUsers() {
    var users = widget.room.membersList();
    var important = widget.room.importantMembers();

    users.removeWhere((element) =>
        important.any((i) => i.$1.identifier == element.identifier));

    roomMembers = users;
    importantMembers = important;
  }

  Future<void> loadAllUsers() async {
    setState(() {
      loadingMoreMembers = true;
    });

    var users = await widget.room.fetchMembersList();
    var important = widget.room.importantMembers();

    var max = min(limit, users.length);

    for (var i = max - 1; i >= 0; i--) {
      if (important.any((element) => element.$1 == users[i])) {
        users.removeAt(i);
      }
    }

    setState(() {
      roomMembers = users;
      loadingMoreMembers = false;
      importantMembers = important;
    });
  }

  int getLimitedDisplayListCount() {
    var count = roomMembers.length;
    count = min(count, limit);

    if (importantMembers != null) {
      count += importantMembers!.length;
    }
    return count;
  }

  int getListCount() {
    var count = roomMembers.length;

    if (importantMembers != null) {
      count += importantMembers!.length;
    }
    return count;
  }

  Member getDisplayUser(int index) {
    if (importantMembers == null || importantMembers!.isEmpty) {
      return roomMembers[index];
    }

    if (index < importantMembers!.length) {
      return importantMembers![index].$1;
    } else {
      return roomMembers[index - importantMembers!.length];
    }
  }

  Role? getDisplayRole(int index) {
    if (isDirectMessageRoom) {
      return null;
    }

    if (index == importantMembers?.length) {
      var user = getDisplayUser(index);
      return widget.room.getMemberRole(user.identifier);
    }

    if (importantMembers != null && index < importantMembers!.length) {
      var role = importantMembers![index].$2;

      if (index == 0) {
        return role;
      }

      var prevRole = importantMembers![index - 1].$2;

      if (prevRole != role) {
        return role;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    var itemCount = getLimitedDisplayListCount();

    return ListView.builder(
      itemBuilder: (context, index) {
        if (index < itemCount) {
          var member = getDisplayUser(index);
          Widget result = MemberPanel(
            client: widget.room.client,
            member: member,
            userColor: member.defaultColor,
          );

          var role = getDisplayRole(index);
          if (role != null) {
            result = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [RoleView(name: role.name, icon: role.icon), result],
            );
          }

          return result;
        }

        if (loadingMoreMembers && index == itemCount) {
          return buildLoadingDisplay();
        }

        var limitedCount = getLimitedDisplayListCount();
        var listCount = getListCount();
        if (index == limitedCount && limitedCount != listCount) {
          var diff = listCount - limitedCount;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: tiamat.Button.secondary(
              text: "+$diff More",
              onTap: () => setState(() {
                limit += 50;
              }),
            ),
          );
        }

        return null;
      },
    );
  }

  Widget buildLoadingDisplay() {
    return Shimmer(
      linearGradient: Shimmer.harshGradient,
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
