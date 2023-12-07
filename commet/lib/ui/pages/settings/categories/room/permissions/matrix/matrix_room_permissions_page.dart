import 'package:commet/ui/pages/settings/categories/room/permissions/matrix/matrix_room_permissions_view.dart';
import 'package:flutter/material.dart';
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
  const MatrixRoomPermissionsPage(this.room, {super.key});
  final matrix.Room room;

  @override
  State<MatrixRoomPermissionsPage> createState() =>
      _MatrixRoomPermissionsPageState();
}

class _MatrixRoomPermissionsPageState extends State<MatrixRoomPermissionsPage> {
  late List<MatrixRoomRoleEntry> roles;
  late List<MatrixRoomPermissionEntry> permissions;
  bool loading = false;

  void initPermissions() {
    roles = [
      // MatrixRoomRoleEntry(
      //     name: "Founder", powerlevel: 101, icon: Icons.star_rounded),
      MatrixRoomRoleEntry(name: "Admin", powerlevel: 100, icon: Icons.security),
      MatrixRoomRoleEntry(
          name: "Moderator", powerlevel: 50, icon: Icons.shield_rounded),
      MatrixRoomRoleEntry(
          name: "Room Member", powerlevel: 0, icon: Icons.groups)
    ];

    permissions = List.empty(growable: true);

    if (widget.room.isSpace) {
      permissions.addAll([
        MatrixRoomPermissionEntry(
            key: "m.space.child",
            keyParent: "events",
            title: "Manage Children",
            description:
                "Allows the user to manage which rooms are part of this space",
            powerLevel: 50,
            icon: Icons.list)
      ]);
    } else {
      permissions.addAll([
        MatrixRoomPermissionEntry(
            key: "redact",
            title: "Delete Messages",
            description: "Allows the user to delete messages sent by others",
            powerLevel: 50,
            icon: Icons.delete),
        MatrixRoomPermissionEntry(
            key: "events_default",
            title: "Send Messages",
            description: "Allows a user to send messages in this room",
            powerLevel: 0,
            icon: Icons.message),
        MatrixRoomPermissionEntry(
            key: "m.reaction",
            keyParent: "events",
            title: "Add Reactions",
            description: "Add reactions to messages",
            icon: Icons.favorite,
            powerLevel: 0),
        MatrixRoomPermissionEntry(
            key: "m.room.history_visibility",
            keyParent: "events",
            title: "History Visibility",
            description:
                "Allows the user to change the visibility of chat history in this room",
            powerLevel: 50,
            icon: Icons.history),
      ]);
    }

    permissions.addAll([
      MatrixRoomPermissionEntry(
          key: "m.room.avatar",
          keyParent: "events",
          title: "Set Room Avatar",
          description: "Change the room avatar",
          icon: Icons.image,
          powerLevel: 50),
      MatrixRoomPermissionEntry(
          key: "m.room.power_levels",
          keyParent: "events",
          title: "Change permissions",
          description: "Allows the user to change permission settings",
          powerLevel: 50,
          icon: Icons.admin_panel_settings),
      MatrixRoomPermissionEntry(
          key: "m.room.name",
          keyParent: "events",
          title: "Change room name",
          description: "Allows the user to change the name of this room",
          powerLevel: 50,
          icon: Icons.edit),
      MatrixRoomPermissionEntry(
          key: "m.room.topic",
          keyParent: "events",
          title: "Change topic",
          description: "Allows the user to change the topic of this room",
          icon: Icons.edit_note_rounded,
          powerLevel: 50),
      MatrixRoomPermissionEntry(
          key: "kick",
          title: "Kick Users",
          description: "Kick other users out of the room",
          powerLevel: 50,
          icon: Icons.gavel),
      MatrixRoomPermissionEntry(
          key: "ban",
          title: "Ban",
          description: "Ban other users from the room",
          powerLevel: 100,
          icon: Icons.gavel),
    ]);
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
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
      List<MatrixRoomPermissionEntry> permissions) async {
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

    await mxRoom.client
        .setRoomStateWithKey(mxRoom.id, "m.room.power_levels", "", content);
  }
}
