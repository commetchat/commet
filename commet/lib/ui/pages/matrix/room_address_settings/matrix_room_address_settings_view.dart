import 'dart:async';

import 'package:commet/config/layout_config.dart';
import 'package:commet/ui/atoms/tiny_pill.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/pages/matrix/room_address_settings/matrix_room_add_local_alias_view.dart';
import 'package:commet/widgetbook.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import 'package:isar/isar.dart';
import 'package:matrix/matrix.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class MatrixRoomAddressSettingsView extends StatefulWidget {
  const MatrixRoomAddressSettingsView(this.knownAliases,
      {this.mainAlias,
      this.userHomeserver,
      required this.mainAliasChangedStream,
      required this.isAliasAvailable,
      required this.canChangeMainAlias,
      required this.canAddLocalAlias,
      required this.createAlias,
      required this.deleteAlias,
      required this.setMainAlias,
      required this.publishAlias,
      required this.unpublishAlias,
      required this.publishedAliases,
      super.key});
  final List<String> knownAliases;
  final List<String> publishedAliases;
  final String? mainAlias;
  final String? userHomeserver;
  final bool canChangeMainAlias;
  final bool canAddLocalAlias;
  final Stream<String?> mainAliasChangedStream;
  final Future<bool> Function(String alias) setMainAlias;
  final Future<bool> Function(String alias) deleteAlias;
  final Future<bool> Function(String alias) isAliasAvailable;
  final Future<String?> Function(String alias) createAlias;
  final Future<void> Function(String alias) publishAlias;
  final Future<void> Function(String alias) unpublishAlias;
  @override
  State<MatrixRoomAddressSettingsView> createState() =>
      _MatrixRoomAddressSettingsViewState();
}

class _MatrixRoomAddressSettingsViewState
    extends State<MatrixRoomAddressSettingsView> {
  int? mainAliasIndex;
  String? errorMessage;
  StreamSubscription? subscription;
  GlobalKey<DropdownSelectorState> stateKey = GlobalKey();

  @override
  void initState() {
    if (widget.mainAlias != null) {
      mainAliasIndex = widget.knownAliases.indexOf(widget.mainAlias!);
      if (mainAliasIndex == -1) {
        mainAliasIndex = null;
      }
    }
    subscription = widget.mainAliasChangedStream.listen(onMainAliasChanged);

    super.initState();
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  void onMainAliasChanged(String? value) {
    stateKey.currentState?.setState(() {
      stateKey.currentState?.value = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      header: "Room Addresses",
      mode: TileType.surfaceLow2,
      child: Column(
        children: [
          if (widget.knownAliases.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
              child: mainAliasSelector(),
            ),
          aliasList(),
        ],
      ),
    );
  }

  Widget aliasList() {
    double boxSize = Layout.mobile ? 40 : 30;
    double iconSize = Layout.mobile ? 25 : 20;
    return Panel(
      mode: TileType.surfaceLow1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tiamat.Text.labelLow("Other Addresses:"),
          if (widget.knownAliases.isEmpty)
            SizedBox(
              height: 50,
              child: Center(
                child: tiamat.Text.labelLow(
                    "This room does not currently have any local Addresses"),
              ),
            ),
          ImplicitlyAnimatedList(
            shrinkWrap: true,
            itemData: widget.knownAliases,
            itemBuilder: (context, data) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IgnorePointer(
                        ignoring: isEditable(data) == false,
                        child: SizedBox(
                            width: boxSize,
                            height: boxSize,
                            child: tiamat.Tooltip(
                              text: isPublished(data)
                                  ? "Unpublish Address"
                                  : "Publish Address",
                              child: tiamat.IconToggle(
                                icon: Icons.public,
                                size: iconSize,
                                state: isPublished(data),
                                onPressed: (newState) {
                                  if (newState) {
                                    widget.publishAlias(data);
                                  } else {
                                    widget.unpublishAlias(data);
                                  }
                                },
                              ),
                            )),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: tiamat.Text.label(data),
                        ),
                      ),
                      if (data == widget.mainAlias) TinyPill("Main"),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: boxSize,
                      height: boxSize,
                      child: isEditable(data)
                          ? tiamat.Tooltip(
                              text: "Delete local address",
                              child: tiamat.IconButton(
                                icon: Icons.close,
                                size: iconSize,
                                onPressed: () => deleteAlias(data),
                                iconColor: Theme.of(context).colorScheme.error,
                              ),
                            )
                          : Container(),
                    ),
                  ),
                ],
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              errorMessage == null
                  ? Container()
                  : tiamat.Text.error(errorMessage!),
              SizedBox(
                width: 40,
                height: 40,
                child: tiamat.Tooltip(
                  preferredDirection: AxisDirection.left,
                  text: "Add local address",
                  child: tiamat.CircleButton(
                    icon: Icons.add,
                    onPressed: showAddAliasDialog,
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  void showAddAliasDialog() {
    AdaptiveDialog.show(
      context,
      title: "Add Local Address",
      builder: (context) {
        return MatrixRoomAddLocalAliasView(widget.userHomeserver!,
            widget.isAliasAvailable, widget.createAlias);
      },
    );
  }

  Widget mainAliasSelector() {
    return IgnorePointer(
      ignoring: widget.canChangeMainAlias == false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tiamat.DropdownSelector(
            key: stateKey,
            items: widget.knownAliases,
            defaultIndex: mainAliasIndex,
            itemHeight: 60,
            hint: tiamat.Text.labelLow(widget.canChangeMainAlias
                ? "Select a main room address"
                : "This room does not have a set main alias"),
            onItemSelected: (item) => widget.setMainAlias(item),
            itemBuilder: (item) {
              return Row(
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: tiamat.Text.label(item),
                    ),
                  ),
                  if (item == widget.mainAlias) TinyPill("Main"),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> deleteAlias(String item) async {
    var confirmation = await AdaptiveDialog.confirmation(context,
        prompt: "Are you sure you want to delete the address '$item'");

    if (confirmation != true) {
      return;
    }

    var result = await widget.deleteAlias(item);

    if (result == false) {
      setState(() {
        errorMessage = "You do not have permission to delete '$item'";
      });
    }
  }

  bool isEditable(String item) {
    if (item.split(":").last == widget.userHomeserver) {
      return true;
    }

    return false;
  }

  bool isPublished(String item) {
    return widget.publishedAliases.contains(item);
  }
}
