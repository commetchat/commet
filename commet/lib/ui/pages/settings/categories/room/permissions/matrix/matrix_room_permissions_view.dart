import 'dart:ui';

import 'package:commet/config/build_config.dart';
import 'package:commet/ui/pages/settings/categories/room/permissions/matrix/matrix_room_permissions_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class MatrixRoomPermissionsView extends StatefulWidget {
  const MatrixRoomPermissionsView(this.permissions, this.powerLevels,
      {super.key, this.setPermissions, this.canEdit = false});
  final List<MatrixRoomPermissionEntry> permissions;
  final List<MatrixRoomRoleEntry> powerLevels;
  final bool canEdit;
  final Future<void> Function(List<MatrixRoomPermissionEntry> permissions)?
      setPermissions;

  @override
  State<MatrixRoomPermissionsView> createState() =>
      _MatrixRoomPermissionsViewState();
}

class _MatrixRoomPermissionsViewState extends State<MatrixRoomPermissionsView> {
  late List<dynamic> entries = List.empty(growable: true);
  bool isEdited = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    entries.addAll(widget.permissions);
    entries.addAll(widget.powerLevels);

    entries.sort(sortFunction);
  }

  int sortFunction(dynamic a, dynamic b) {
    if (a is MatrixRoomPermissionEntry && b is MatrixRoomPermissionEntry) {
      return -a.powerLevel.compareTo(b.powerLevel);
    }

    if (a is MatrixRoomRoleEntry && b is MatrixRoomRoleEntry) {
      return -a.powerlevel.compareTo(b.powerlevel);
    }

    if (a is MatrixRoomRoleEntry && b is MatrixRoomPermissionEntry) {
      if (a.powerlevel != b.powerLevel) {
        return -a.powerlevel.compareTo(b.powerLevel);
      } else {
        return -1;
      }
    }

    if (a is MatrixRoomPermissionEntry && b is MatrixRoomRoleEntry) {
      if (a.powerLevel != b.powerlevel) {
        return -a.powerLevel.compareTo(b.powerlevel);
      } else {
        return 1;
      }
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ReorderableList(
          itemBuilder: (context, index) {
            var key = Key('$index');
            var enabled =
                widget.canEdit && entries[index] is MatrixRoomPermissionEntry;
            if (BuildConfig.MOBILE) {
              return ReorderableDelayedDragStartListener(
                key: key,
                enabled: enabled,
                index: index,
                child: itemBuilder(context, index),
              );
            } else {
              return ReorderableDragStartListener(
                key: key,
                enabled: enabled,
                index: index,
                child: itemBuilder(context, index),
              );
            }
          },
          onReorderStart: (index) => HapticFeedback.mediumImpact(),
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (BuildContext context, Widget? child) {
                final double animValue =
                    Curves.easeInCubic.transform(animation.value);
                final double scale = lerpDouble(1, 1.02, animValue)!;
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: child,
            );
          },
          shrinkWrap: true,
          itemCount: entries.length,
          onReorder: onReorder),
      floatingActionButton: isEdited
          ? FloatingActionButton(
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    )
                  : const Icon(Icons.check),
              onPressed: () => applySettings())
          : null,
    );
  }

  Widget itemBuilder(BuildContext context, int index) {
    var item = entries[index];
    if (item is MatrixRoomRoleEntry) {
      return buildRole(item);
    }

    if (item is MatrixRoomPermissionEntry) {
      return buildPermission(item, context);
    }

    return const Placeholder();
  }

  Widget buildRole(MatrixRoomRoleEntry item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Align(
        alignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Tile.low2(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.icon != null) Icon(item.icon),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                    child: tiamat.Text.labelEmphasised(item.name),
                  ),
                  tiamat.Text.tiny('${item.powerlevel}')
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPermission(MatrixRoomPermissionEntry item, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Tile.low1(
          child: MouseRegion(
            cursor: widget.canEdit
                ? MaterialStateMouseCursor.clickable
                : MouseCursor.defer,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 30, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                      child: Row(
                        children: [
                          if (item.icon != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 12, 0),
                              child: Icon(item.icon),
                            ),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                tiamat.Text.labelEmphasised(item.title),
                                tiamat.Text.labelLow(item.description)
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: item.powerLevel != item.originalPowerLevel
                              ? Icon(
                                  Icons.edit,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 15,
                                )
                              : null,
                        ),
                      ),
                      tiamat.Text.tiny(item.powerLevel.toString()),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      if (oldIndex == 0 || newIndex == 0) {
        return;
      }

      var items = List.from(entries);

      final dynamic item = items.removeAt(oldIndex);
      items.insert(newIndex, item);

      if (isListValid(items)) {
        entries = items;
        determinePowerLevels();
      }
    });
  }

  bool isListValid(List<dynamic> items) {
    MatrixRoomRoleEntry? currentRole;
    for (var item in items) {
      if (item is MatrixRoomRoleEntry) {
        if (currentRole != null) {
          if (currentRole.powerlevel < item.powerlevel) {
            return false;
          }
        }

        currentRole = item;
      }
    }

    return true;
  }

  void determinePowerLevels() {
    MatrixRoomRoleEntry? currentRole;
    isEdited = false;

    for (int i = 0; i < entries.length; i++) {
      var item = entries[i];

      if (item is MatrixRoomRoleEntry) {
        currentRole = item;
        continue;
      }

      if (currentRole == null) {
        continue;
      }

      if (item is MatrixRoomPermissionEntry) {
        MatrixRoomRoleEntry? nextRole;

        for (int j = i + 1; j < entries.length; j++) {
          var nextItem = entries[j];
          if (nextItem is MatrixRoomRoleEntry) {
            nextRole = nextItem;
            break;
          }
        }

        if (item.originalPowerLevel <= currentRole.powerlevel) {
          item.powerLevel = item.originalPowerLevel;
        }

        if (item.powerLevel > currentRole.powerlevel) {
          item.powerLevel = currentRole.powerlevel;
        }

        if (nextRole != null && item.powerLevel <= nextRole.powerlevel) {
          item.powerLevel = currentRole.powerlevel;
        }

        if (item.powerLevel != item.originalPowerLevel) {
          isEdited = true;
        }
      }
    }
  }

  applySettings() async {
    setState(() {
      isLoading = true;
    });

    var perms = entries
        .whereType<MatrixRoomPermissionEntry>()
        .cast<MatrixRoomPermissionEntry>()
        .toList();

    await widget.setPermissions?.call(perms);

    setState(() {
      isLoading = false;
      isEdited = false;

      // Reset power levels so they arent marked edited anymore
      for (var entry in entries) {
        if (entry is MatrixRoomPermissionEntry) {
          entry.originalPowerLevel = entry.powerLevel;
        }
      }
    });
  }
}
