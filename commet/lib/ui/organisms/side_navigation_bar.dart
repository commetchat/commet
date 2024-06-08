import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/profile.dart';
import 'package:commet/ui/atoms/dot_indicator.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/pages/add_space_or_room/add_space_or_room.dart';
import 'package:commet/ui/pages/settings/app_settings_page.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import '../molecules/space_selector.dart';
import '../navigation/navigation_utils.dart';

class SideNavigationBar extends StatefulWidget {
  const SideNavigationBar(
      {super.key,
      required this.currentUser,
      this.onSpaceSelected,
      this.onDirectMessagesSelected,
      this.onSettingsSelected,
      this.onHomeSelected,
      this.clearSpaceSelection});

  static ValueKey settingsKey =
      const ValueKey("SIDE_NAVIGATION_SETTINGS_BUTTON");

  final Profile currentUser;
  final void Function(int index)? onSpaceSelected;
  final void Function()? clearSpaceSelection;
  final void Function()? onDirectMessagesSelected;
  final void Function()? onHomeSelected;
  final void Function()? onSettingsSelected;

  @override
  State<SideNavigationBar> createState() => _SideNavigationBarState();

  static Widget tooltip(String text, Widget child, BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: JustTheTooltip(
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: tiamat.Text(text),
          ),
          preferredDirection: AxisDirection.right,
          offset: 5,
          tailLength: 5,
          tailBaseWidth: 5,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: child),
    );
  }
}

class _SideNavigationBarState extends State<SideNavigationBar> {
  late ClientManager _clientManager;
  StreamSubscription? onSpaceUpdated;
  StreamSubscription? onSpaceChildUpdated;
  StreamSubscription? onDirectMessageUpdatedSubscription;

  String get promptAddSpace => Intl.message("Add Space",
      name: "promptAddSpace", desc: "Prompt to add a new space");

  @override
  void initState() {
    _clientManager = Provider.of<ClientManager>(context, listen: false);
    onSpaceChildUpdated = _clientManager.onSpaceChildUpdated.stream
        .listen((_) => onSpaceUpdate());

    onSpaceUpdated =
        _clientManager.onSpaceUpdated.stream.listen((_) => onSpaceUpdate());

    onDirectMessageUpdatedSubscription = _clientManager
        .onDirectMessageRoomUpdated.stream
        .listen(onDirectMessageUpdated);
    super.initState();
  }

  void onSpaceUpdate() {
    setState(() {});
  }

  void onDirectMessageUpdated(Room room) {
    setState(() {});
  }

  @override
  void dispose() {
    onSpaceUpdated?.cancel();
    onSpaceChildUpdated?.cancel();
    onDirectMessageUpdatedSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 70.0,
        child: Column(
          children: [
            Padding(
              padding: SpaceSelector.padding,
              child: SideNavigationBar.tooltip(
                  CommonStrings.promptSettings,
                  ImageButton(
                    size: 70,
                    image: widget.currentUser.avatar,
                    placeholderColor: widget.currentUser.defaultColor,
                    placeholderText: widget.currentUser.displayName,
                    key: SideNavigationBar.settingsKey,
                    onTap: () {
                      NavigationUtils.navigateTo(
                          context, const AppSettingsPage());
                    },
                  ),
                  context),
            ),
            const SizedBox(
              height: 4,
            ),
            Expanded(
              child: SpaceSelector(
                _clientManager.spaces,
                width: 70,
                onSpaceInsert: _clientManager.onSpaceAdded,
                onSpaceRemoved: _clientManager.onSpaceRemoved,
                clearSelection: widget.clearSpaceSelection,
                shouldShowAvatarForSpace: shouldShowAvatarForSpace,
                header: Column(
                  children: [
                    SideNavigationBar.tooltip(
                        CommonStrings.promptHome,
                        Stack(
                          children: [
                            ImageButton(
                              size: 70,
                              icon: Icons.home,
                              onTap: () {
                                widget.onHomeSelected?.call();
                              },
                            ),
                            if (_clientManager.directMessagesNotificationCount >
                                0)
                              const DotIndicator()
                          ],
                        ),
                        context),
                  ],
                ),
                footer: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
                      child: SideNavigationBar.tooltip(
                          promptAddSpace,
                          ImageButton(
                            size: 70,
                            icon: Icons.add,
                            onTap: () {
                              AdaptiveDialog.show(context,
                                  builder: (_) => AddSpaceOrRoom(
                                        clients: _clientManager.clients,
                                        createSpace: (client, name, visibility,
                                            enableE2EE) async {
                                          await client.createSpace(
                                              name, visibility);
                                        },
                                        joinSpace: (client, address) async {
                                          await client.joinSpace(address);
                                        },
                                      ),
                                  title: promptAddSpace);
                            },
                          ),
                          context),
                    ),
                  ],
                ),
                onSelected: (index) {
                  widget.onSpaceSelected?.call(index);
                },
              ),
            ),
          ],
        ));
  }

  bool shouldShowAvatarForSpace(Space space) {
    var spaces = _clientManager.spaces
        .where((element) => element.identifier == space.identifier);
    return spaces.length > 1;
  }
}
