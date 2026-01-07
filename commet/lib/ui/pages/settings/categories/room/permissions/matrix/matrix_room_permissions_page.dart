import 'package:commet/ui/pages/settings/categories/room/permissions/matrix/matrix_room_permissions_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixRoomPermissionEntry {
  String title;
  String description;
  String key;
  String? keyParent;
  int powerLevel;
  late int originalPowerLevel;
  IconData? icon;
  MatrixRoomPermissionEntry({
    required this.key,
    required this.title,
    required this.description,
    required this.powerLevel,
    this.icon,
    this.keyParent,
  }) {
    originalPowerLevel = powerLevel;
  }
}

class MatrixRoomRoleEntry {
  String name;
  int powerlevel;
  IconData? icon;

  MatrixRoomRoleEntry({
    required this.name,
    required this.powerlevel,
    this.icon,
  });
}

class MatrixRoomPermissionsPage extends StatefulWidget {
  const MatrixRoomPermissionsPage(this.room,
      {super.key, this.showCalendarPermissions = false});
  final matrix.Room room;
  final bool showCalendarPermissions;

  @override
  State<MatrixRoomPermissionsPage> createState() =>
      _MatrixRoomPermissionsPageState();
}

class _MatrixRoomPermissionsPageState extends State<MatrixRoomPermissionsPage> {
  late List<MatrixRoomRoleEntry> roles;
  late List<MatrixRoomPermissionEntry> permissions;
  bool loading = false;

  String get labelMatrixPermissionsRoleAdmin => Intl.message(
        "Admin",
        name: "labelMatrixPermissionsRoleAdmin",
        desc: "Label for the room administrator role",
      );

  String get labelMatrixPermissionsRoleModerator => Intl.message(
        "Moderator",
        name: "labelMatrixPermissionsRoleModerator",
        desc: "Label for the room moderator role",
      );

  String get labelMatrixPermissionsRoleMember => Intl.message(
        "Room Member",
        name: "labelMatrixPermissionsRoleMember",
        desc: "Label for the room member role",
      );

  String get labelMatrixPermissionsSpaceManageChildrenTitle => Intl.message(
        "Manage Children",
        name: "labelMatrixPermissionsSpaceManageChildrenTitle",
        desc: "Title for permission to manage children",
      );

  String get labelMatrixPermissionsSpaceManageChildrenDescription =>
      Intl.message(
        "Allows the user to manage which rooms are part of this space",
        name: "labelMatrixPermissionsSpaceManageChildrenDescription",
        desc: "Describes the permission to manage child rooms",
      );

  String get labelMatrixPermissionsRoomDeleteMessagesTitle => Intl.message(
        "Delete Messages",
        name: "labelMatrixPermissionsRoomDeleteMessagesTitle",
        desc: "Title for permission to delete messages",
      );

  String get labelMatrixPermissionsRoomDeleteMessagesDescription =>
      Intl.message(
        "Allows the user to delete messages sent by others",
        name: "labelMatrixPermissionsRoomDeleteMessagesDescription",
        desc: "Describes the permission to delete messages",
      );

  String get labelMatrixPermissionsRoomSendMessagesTitle => Intl.message(
        "Send Messages",
        name: "labelMatrixPermissionsRoomSendMessagesTitle",
        desc: "Title for the permission to send messages",
      );

  String get labelMatrixPermissionsRoomSendMessagesDescription => Intl.message(
        "Allows a user to send messages in this room",
        name: "labelMatrixPermissionsRoomSendMessagesDescription",
        desc: "Describes the permission to send messages",
      );

  String get labelMatrixPermissionsRoomAddReactionsTitle => Intl.message(
        "Add Reactions",
        name: "labelMatrixPermissionsRoomAddReactionsTitle",
        desc: "Title for the permission to add an emoji reaction to a message",
      );

  String get labelMatrixPermissionsRoomAddReactionsDescription => Intl.message(
        "Add reactions to messages",
        name: "labelMatrixPermissionsRoomAddReactionsDescription",
        desc: "describes the permission to add an emoji reaction to a message",
      );

  String get labelMatrixPermissionsRoomHistoryVisibilityTitle => Intl.message(
        "History Visibility",
        name: "labelMatrixPermissionsRoomHistoryVisibilityTitle",
        desc: "Title for the permission to add change room history settings",
      );

  String get labelMatrixPermissionsRoomHistoryVisibilityDescription =>
      Intl.message(
        "Allows the user to change the visibility of chat history in this room",
        name: "labelMatrixPermissionsRoomHistoryVisibilityDescription",
        desc: "describes the permission to change room history settings",
      );

  String get labelMatrixPermissionsRoomAvatarTitle => Intl.message(
        "Set Room Avatar",
        name: "labelMatrixPermissionsRoomAvatarTitle",
        desc: "Title for the permission to add change the rooms avatar image",
      );

  String get labelMatrixPermissionsRoomAvatarDescription => Intl.message(
        "Change the room's avatar image",
        name: "labelMatrixPermissionsRoomAvatarDescription",
        desc: "Title for the permission to add change the rooms avatar image",
      );

  String get labelMatrixPermissionsChangeRoomNameTitle => Intl.message(
        "Change room name",
        name: "labelMatrixPermissionsChangeRoomNameTitle",
        desc: "Title for the permission to add change the rooms name",
      );

  String get labelMatrixPermissionsChangeRoomNameDescription => Intl.message(
        "Allows the user to change the name of this room",
        name: "labelMatrixPermissionsChangeRoomNameDescription",
        desc: "Description for the permission to add change the rooms name",
      );

  String get labelMatrixPermissionsChangeRoomTopicTitle => Intl.message(
        "Change room topic",
        name: "labelMatrixPermissionsChangeRoomTopicTitle",
        desc: "Title for the permission to add change the rooms topic",
      );

  String get labelMatrixPermissionsChangeRoomTopicDescription => Intl.message(
        "Allows the user to change the topic of this room",
        name: "labelMatrixPermissionsChangeRoomTopicDescription",
        desc: "Description for the permission to add change the rooms topic",
      );

  String get labelMatrixPermissionsChangeRoomPermissionsTitle => Intl.message(
        "Change permissions",
        name: "labelMatrixPermissionsChangeRoomPermissionsTitle",
        desc: "Title for the permission to change permissions of the room",
      );

  String get labelMatrixPermissionsChangeRoomPermissionsDescription =>
      Intl.message(
        "Allows the user to change permission settings",
        name: "labelMatrixPermissionsChangeRoomPermissionsDescription",
        desc:
            "Description for the permission to change permissions of the room",
      );

  String get labelMatrixPermissionsKickUserTitle => Intl.message(
        "Kick users",
        name: "labelMatrixPermissionsKickUserTitle",
        desc: "Title for the permission to kick other users out of the room",
      );

  String get labelMatrixPermissionsKickUserDescription => Intl.message(
        "Kick other users out of the room",
        name: "labelMatrixPermissionsKickUserDescription",
        desc:
            "Description for the permission to kick other users out of the room",
      );

  String get labelMatrixPermissionsBanUserTitle => Intl.message(
        "Ban users",
        name: "labelMatrixPermissionsBanUserTitle",
        desc: "Title for the permission to ban other users from the room",
      );

  String get labelMatrixPermissionsBanUserDescription => Intl.message(
        "Ban other users from the room",
        name: "labelMatrixPermissionsBanUserDescription",
        desc: "Description for the permission to ban other users from the room",
      );

  String get labelMatrixPermissionsJoinCallTitle => Intl.message(
        "Join Call",
        name: "labelMatrixPermissionsJoinCallTitle",
        desc:
            "Title for the permission to allow users to join a call in a room",
      );

  String get labelMatrixPermissionsJoinCallDescription => Intl.message(
        "Allow users to join an ongoing call in this room",
        name: "labelMatrixPermissionsJoinCallDescription",
        desc:
            "Description for the permission to allow users to join a call in a room",
      );

  String get labelMatrixPermissionsAddCalendarEventTitle => Intl.message(
        "Edit Calendar Events",
        name: "labelMatrixPermissionsAddCalendarEvent",
        desc: "Title for the permission to allow users to edit the calendar",
      );

  String get labelMatrixPermissionsAddCalendarEventDescription => Intl.message(
        "Allow users to edit events in the calendar",
        name: "labelMatrixPermissionsCreateCalendarEventDescription",
        desc:
            "Description for the permission to allow users to create an event on the calendar",
      );

  void initPermissions() {
    bool isCalendarRoom = widget.showCalendarPermissions;

    roles = [
      // MatrixRoomRoleEntry(
      //     name: "Founder", powerlevel: 101, icon: Icons.star_rounded),
      MatrixRoomRoleEntry(
        name: labelMatrixPermissionsRoleAdmin,
        powerlevel: 100,
        icon: Icons.security,
      ),
      MatrixRoomRoleEntry(
        name: labelMatrixPermissionsRoleModerator,
        powerlevel: 50,
        icon: Icons.shield_rounded,
      ),

      if (isCalendarRoom)
        MatrixRoomRoleEntry(
          name: "Calendar Moderator",
          powerlevel: 25,
          icon: Icons.edit_calendar,
        ),

      MatrixRoomRoleEntry(
        name: labelMatrixPermissionsRoleMember,
        powerlevel: 0,
        icon: Icons.groups,
      ),
    ];

    permissions = List.empty(growable: true);

    if (widget.room.isSpace) {
      permissions.addAll([
        MatrixRoomPermissionEntry(
          key: "m.space.child",
          keyParent: "events",
          title: labelMatrixPermissionsSpaceManageChildrenTitle,
          description: labelMatrixPermissionsSpaceManageChildrenDescription,
          powerLevel: 50,
          icon: Icons.list,
        ),
      ]);
    } else {
      permissions.addAll([
        MatrixRoomPermissionEntry(
          key: "redact",
          title: labelMatrixPermissionsRoomDeleteMessagesTitle,
          description: labelMatrixPermissionsRoomDeleteMessagesDescription,
          powerLevel: 50,
          icon: Icons.delete,
        ),
        MatrixRoomPermissionEntry(
          key: "events_default",
          title: labelMatrixPermissionsRoomSendMessagesTitle,
          description: labelMatrixPermissionsRoomSendMessagesDescription,
          powerLevel: 0,
          icon: Icons.message,
        ),
        MatrixRoomPermissionEntry(
          key: "m.reaction",
          keyParent: "events",
          title: labelMatrixPermissionsRoomAddReactionsTitle,
          description: labelMatrixPermissionsRoomAddReactionsDescription,
          icon: Icons.favorite,
          powerLevel: 0,
        ),
        MatrixRoomPermissionEntry(
          key: "m.room.history_visibility",
          keyParent: "events",
          title: labelMatrixPermissionsRoomHistoryVisibilityTitle,
          description: labelMatrixPermissionsRoomHistoryVisibilityDescription,
          powerLevel: 50,
          icon: Icons.history,
        ),
      ]);
    }

    permissions.addAll([
      MatrixRoomPermissionEntry(
        key: "m.room.avatar",
        keyParent: "events",
        title: labelMatrixPermissionsRoomAvatarTitle,
        description: labelMatrixPermissionsRoomAvatarDescription,
        icon: Icons.image,
        powerLevel: 50,
      ),
      MatrixRoomPermissionEntry(
        key: "m.room.power_levels",
        keyParent: "events",
        title: labelMatrixPermissionsChangeRoomPermissionsTitle,
        description: labelMatrixPermissionsChangeRoomPermissionsDescription,
        powerLevel: 50,
        icon: Icons.admin_panel_settings,
      ),
      MatrixRoomPermissionEntry(
        key: "m.room.name",
        keyParent: "events",
        title: labelMatrixPermissionsChangeRoomNameTitle,
        description: labelMatrixPermissionsChangeRoomNameDescription,
        powerLevel: 50,
        icon: Icons.edit,
      ),
      MatrixRoomPermissionEntry(
        key: "m.room.topic",
        keyParent: "events",
        title: labelMatrixPermissionsChangeRoomTopicTitle,
        description: labelMatrixPermissionsChangeRoomTopicDescription,
        icon: Icons.edit_note_rounded,
        powerLevel: 50,
      ),
      MatrixRoomPermissionEntry(
        key: "kick",
        title: labelMatrixPermissionsKickUserTitle,
        description: labelMatrixPermissionsKickUserDescription,
        powerLevel: 50,
        icon: Icons.gavel,
      ),
      MatrixRoomPermissionEntry(
        key: "ban",
        title: labelMatrixPermissionsBanUserTitle,
        description: labelMatrixPermissionsBanUserDescription,
        powerLevel: 100,
        icon: Icons.gavel,
      ),
    ]);
    bool isVoipRoom =
        widget.room.getState(matrix.EventTypes.RoomCreate)?.content['type'] ==
            "org.matrix.msc3417.call";
    if (isVoipRoom) {
      permissions.addAll([
        MatrixRoomPermissionEntry(
          key: "org.matrix.msc3401.call.member",
          keyParent: "events",
          title: labelMatrixPermissionsJoinCallTitle,
          description: labelMatrixPermissionsJoinCallDescription,
          icon: Icons.call,
          powerLevel: 0,
        ),
      ]);
    }

    if (isCalendarRoom) {
      permissions.addAll([
        MatrixRoomPermissionEntry(
          key: "chat.commet.calendar_event",
          keyParent: "events",
          title: labelMatrixPermissionsAddCalendarEventTitle,
          description: labelMatrixPermissionsAddCalendarEventDescription,
          icon: Icons.calendar_month,
          powerLevel: 25,
        ),
      ]);
    }
  }

  @override
  void initState() {
    initPermissions();

    var event = widget.room.states["m.room.power_levels"]?[""];
    if (event != null) {
      updatePowerLevels(event.content);
    } else {
      loading = true;

      widget.room.postLoad().then((value) {
        var event = widget.room.getState("m.room.power_levels");
        updatePowerLevels(event!.content);
        setState(() {
          loading = false;
        });
      });
    }

    super.initState();
  }

  void updatePowerLevels(Map<String, Object?> content) {
    var stateDefault = content["state_default"] as int;
    for (int i = 0; i < permissions.length; i++) {
      var perm = permissions[i];

      dynamic c = content;
      if (perm.keyParent != null) {
        var parent = c[perm.keyParent];
        if (parent != null) {
          c = c[perm.keyParent];
        }
      }

      var powerLevel = c[perm.key];
      if (powerLevel != null) {
        perm.powerLevel = powerLevel;
        perm.originalPowerLevel = powerLevel;
      } else {
        perm.powerLevel = stateDefault;
        perm.originalPowerLevel = stateDefault;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    var canEdit = widget.room.canChangeStateEvent("m.room.power_levels");
    return MatrixRoomPermissionsView(
      permissions,
      roles,
      setPermissions: setPermissions,
      canEdit: canEdit,
    );
  }

  Future<void> setPermissions(
    List<MatrixRoomPermissionEntry> permissions,
  ) async {
    var mxRoom = widget.room;
    var event = mxRoom.states["m.room.power_levels"]?[""];
    var content = event?.content ?? {};

    for (var perm in permissions) {
      if (perm.powerLevel == perm.originalPowerLevel) {
        continue;
      }

      var map = content;
      if (perm.keyParent != null) {
        map = map[perm.keyParent]! as Map<String, dynamic>;
      }

      map[perm.key] = perm.powerLevel;
    }

    await mxRoom.client.setRoomStateWithKey(
      mxRoom.id,
      "m.room.power_levels",
      "",
      content,
    );
  }
}
