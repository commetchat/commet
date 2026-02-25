import 'package:commet/client/client.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/pages/get_or_create_room/room_creator.dart';
import 'package:commet/utils/error_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/atoms/tile.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class RoomSecuritySettingsPage extends StatefulWidget {
  const RoomSecuritySettingsPage({
    required this.room,
    this.contextSpace,
    this.showEncryptionToggle = true,
    super.key,
  });
  final Room room;
  final Space? contextSpace;
  final bool showEncryptionToggle;

  @override
  State<RoomSecuritySettingsPage> createState() =>
      _RoomSecuritySettingsPageState();
}

class _RoomSecuritySettingsPageState extends State<RoomSecuritySettingsPage> {
  late bool isE2EEEnabled;
  late RoomVisibility visibility;

  String get promptEnableEncryptionRoomSettings =>
      Intl.message("Enable Encryption",
          name: "promptEnableEncryptionRoomSettings",
          desc: "Short prompt to enable encryption for a room");

  String get encryptionCannotBeDisabledExplanationRoomSettings =>
      Intl.message("If enabled, encryption cannot be disabled later",
          name: "encryptionCannotBeDisabledExplanationRoomSettings",
          desc: "Explains that encryption cannot be disabled once enabled");

  @override
  void initState() {
    isE2EEEnabled = widget.room.isE2EE;
    visibility = widget.room.visibility;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        if (widget.room.client.supportsE2EE && widget.showEncryptionToggle)
          buildE2EEToggle(),
        buildRoomVisibility(),
      ],
    );
  }

  Widget buildE2EEToggle() {
    return tiamat.Panel(
      mode: tiamat.TileType.surfaceContainerLow,
      child: Opacity(
        opacity: widget.room.permissions.canEnableE2EE ? 1 : 0.5,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tiamat.Text.labelEmphasised(
                      promptEnableEncryptionRoomSettings),
                  tiamat.Text.labelLow(
                      encryptionCannotBeDisabledExplanationRoomSettings)
                ]),
            IgnorePointer(
              ignoring: isE2EEEnabled || !widget.room.permissions.canEnableE2EE,
              child: tiamat.Switch(
                state: isE2EEEnabled,
                onChanged: (value) {
                  if (value != true) return;
                  setState(() {
                    isE2EEEnabled = true;
                    widget.room.enableE2EE();
                  });
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildRoomVisibility() {
    return IgnorePointer(
      ignoring: !widget.room.permissions.canChangeVisibility,
      child: tiamat.Panel(
        header: "Room Visibility",
        mode: TileType.surfaceContainerLow,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              List<String> spaces = List.empty(growable: true);
              if (widget.room.visibility
                  case RoomVisibilityRestricted restricted) {
                spaces.addAll(restricted.spaces);
              }

              if (widget.contextSpace != null &&
                  !spaces.contains(widget.contextSpace?.identifier)) {
                spaces.add(widget.contextSpace!.identifier);
              }

              if (spaces.isEmpty) {
                var parents = widget.room.client.spaces.where((i) => i.subspaces
                    .any((i) => i.identifier == widget.room.identifier));

                for (var p in parents) {
                  spaces.add(p.identifier);
                }
              }

              var items = [
                if (spaces.isNotEmpty) RoomVisibilityRestricted(spaces),
                RoomVisibilityPrivate(),
                RoomVisibilityPublic(),
              ];

              var newVisibility = await AdaptiveDialog.pickOne(
                title: "Set Visibility",
                context,
                items: items,
                itemBuilder: (context, item, callback) {
                  return Material(
                    borderRadius: BorderRadius.circular(8),
                    clipBehavior: Clip.antiAlias,
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: callback,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: RoomFieldVisibility.buildRoomVisibility(
                            widget.room.client, item),
                      ),
                    ),
                  );
                },
              );

              if (newVisibility != null) {
                ErrorUtils.tryRun(context, () async {
                  await widget.room.setVisibility(newVisibility);

                  setState(() {
                    visibility = newVisibility;
                  });
                });
              }
            },
            child: RoomFieldVisibility.buildRoomVisibility(
                widget.room.client, visibility),
          ),
        ),
      ),
    );
  }
}
