import 'dart:math';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/member.dart';
import 'package:commet/client/role.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/ui/atoms/adaptive_context_menu.dart';
import 'package:commet/ui/atoms/role_view.dart';
import 'package:commet/ui/atoms/shimmer_loading.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/organisms/user_profile/user_profile.dart';
import 'package:commet/utils/error_utils.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import '../../client/room.dart';

class RoomMemberList extends StatefulWidget {
  const RoomMemberList(this.room, {super.key});
  final Room room;

  @override
  State<RoomMemberList> createState() => _RoomMemberListState();

  static AdaptiveContextMenu userContextMenu(BuildContext context,
      {required String userId,
      required String userDisplayName,
      required Room room,
      required Widget child,
      required bool isSelf,
      Function? onUserKicked,
      Function? onUserBanned,
      Function? onUserRoleChanged}) {
    return AdaptiveContextMenu(
      items: [
        if (room.permissions.canChangeRoles)
          tiamat.ContextMenuItem(
              text: "Set Role",
              icon: Icons.shield,
              onPressed: () async {
                ErrorUtils.tryRun(context, () async {
                  var role = await AdaptiveDialog.pickOne(
                    context,
                    title: "Pick Role for $userDisplayName",
                    items: room.availableRoles,
                    itemBuilder: (context, item, callback) {
                      return SizedBox(
                        height: 50,
                        child: tiamat.TextButton(
                          item.name,
                          icon: item.icon,
                          onTap: callback,
                        ),
                      );
                    },
                  );

                  if (role != null) {
                    await room.setMemberRole(userId, role);
                    onUserRoleChanged?.call();
                  }
                });
              }),
        if (room.permissions.canKick && !isSelf)
          tiamat.ContextMenuItem(
              text: "Kick",
              icon: Icons.subdirectory_arrow_left_rounded,
              color: ColorScheme.of(context).error,
              onPressed: () async {
                if (await AdaptiveDialog.confirmation(context,
                        prompt:
                            "Are you sure you want to kick $userDisplayName from the room?") ==
                    true) {
                  ErrorUtils.tryRun(context, () async {
                    await room.kickUser(userId);
                    onUserKicked?.call();
                  });
                }
              }),
        if (room.permissions.canBan && !isSelf)
          tiamat.ContextMenuItem(
              text: "Ban",
              icon: Icons.shield,
              color: ColorScheme.of(context).error,
              onPressed: () async {
                if (await AdaptiveDialog.confirmation(context,
                        prompt:
                            "Are you sure you want to ban $userDisplayName from the room?") ==
                    true) {
                  ErrorUtils.tryRun(context, () async {
                    await room.banUser(userId);
                    onUserBanned?.call();
                  });
                }
              }),
      ],
      child: child,
    );
  }
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
      padding: EdgeInsets.all(0),
      itemBuilder: (context, index) {
        if (index < itemCount) {
          var member = getDisplayUser(index);
          Widget result = UserPanel(
            key: ValueKey("room-user-list-user-${member.identifier}"),
            client: widget.room.client,
            initialMember: member,
            contextRoom: widget.room,
            userId: member.identifier,
          );

          if (isDirectMessageRoom) {
            if (member.identifier == widget.room.client.self?.identifier)
              return SizedBox(
                height: 0,
              );
            result = Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
              child: UserProfile(
                maxBioHeight: double.infinity,
                doSafeArea: false,
                key: ValueKey("room-user-list-user-${member.identifier}"),
                userId: member.identifier,
                bannerHeight: Layout.mobile ? 200 : 120,
                client: widget.room.client,
                showMessageButton: false,
              ),
            );
          }

          result = RoomMemberList.userContextMenu(context,
              userId: member.identifier,
              room: widget.room,
              userDisplayName: member.displayName,
              isSelf: member.identifier == widget.room.client.self!.identifier,
              child: result,
              onUserBanned: () => roomMembers
                  .removeWhere((i) => i.identifier == member.identifier),
              onUserKicked: () => roomMembers
                  .removeWhere((i) => i.identifier == member.identifier),
              onUserRoleChanged: () => loadAllUsers());

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
