import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/profile/profile_component.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/ui/molecules/space_selector.dart';
import 'package:commet/ui/organisms/side_navigation_bar/side_navigation_bar_direct_messages.dart';
import 'package:commet/ui/pages/get_or_create_room/get_or_create_room.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class SideNavigationBar extends StatefulWidget {
  const SideNavigationBar(
      {super.key,
      this.currentUser,
      this.onSpaceSelected,
      this.onDirectMessageSelected,
      this.onSettingsSelected,
      this.onHomeSelected,
      this.extraEntryBuilders,
      this.clearSpaceSelection});

  static ValueKey settingsKey =
      const ValueKey("SIDE_NAVIGATION_SETTINGS_BUTTON");

  final List<Widget Function(double width)>? extraEntryBuilders;

  final Profile? currentUser;
  final void Function(Space space)? onSpaceSelected;
  final void Function()? clearSpaceSelection;
  final void Function(Room room)? onDirectMessageSelected;
  final void Function()? onHomeSelected;
  final void Function()? onSettingsSelected;

  @override
  State<SideNavigationBar> createState() => _SideNavigationBarState();

  static Widget tooltip(String text, Widget child, BuildContext context) {
    if (Layout.mobile) {
      return AspectRatio(
        aspectRatio: 1.0,
        child: child,
      );
    }

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

  late List<StreamSubscription> subs;

  String get promptAddSpace => Intl.message("Add Space",
      name: "promptAddSpace", desc: "Prompt to add a new space");

  late List<Space> topLevelSpaces;

  Client? filterClient;

  @override
  void initState() {
    _clientManager = Provider.of<ClientManager>(context, listen: false);

    void setFilterClient(Client? event) {
      setState(() {
        filterClient = event;

        getSpaces();
      });
    }

    subs = [
      _clientManager.onSpaceChildUpdated.stream.listen((_) => onSpaceUpdate()),
      _clientManager.onSpaceUpdated.stream.listen((_) => onSpaceUpdate()),
      _clientManager.onSpaceRemoved.listen((_) => onSpaceUpdate()),
      _clientManager.onSpaceAdded.listen((_) => onSpaceUpdate()),
      _clientManager.onClientRemoved.stream.listen((_) => onSpaceUpdate()),
      _clientManager.onDirectMessageRoomUpdated.stream
          .listen(onDirectMessageUpdated),
      EventBus.setFilterClient.stream.listen(setFilterClient),
    ];

    getSpaces();

    super.initState();
  }

  void getSpaces() {
    if (filterClient != null) {
      topLevelSpaces = filterClient!.spaces.where((e) => e.isTopLevel).toList();
    } else {
      _clientManager = Provider.of<ClientManager>(context, listen: false);

      topLevelSpaces =
          _clientManager.spaces.where((e) => e.isTopLevel).toList();
    }
  }

  void onSpaceUpdate() {
    setState(() {
      getSpaces();
    });
  }

  void onDirectMessageUpdated(Room room) {
    setState(() {});
  }

  @override
  void dispose() {
    for (var sub in subs) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 70.0,
        child: Column(
          children: [
            Expanded(
              child: SpaceSelector(
                topLevelSpaces,
                width: 70,
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
                          ],
                        ),
                        context),
                    SideNavigationBarDirectMessages(
                      _clientManager.directMessages,
                      onRoomTapped: widget.onDirectMessageSelected,
                    ),
                  ],
                ),
                footer: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 2, 0, 4),
                      child: SideNavigationBar.tooltip(
                          promptAddSpace,
                          ImageButton(
                            size: 70,
                            icon: Icons.add,
                            onTap: () {
                              GetOrCreateRoom.show(null, context,
                                  pickExisting: false, createSpace: true);
                            },
                          ),
                          context),
                    ),
                  ],
                ),
                onSelected: (space) {
                  widget.onSpaceSelected?.call(space);
                },
              ),
            ),
            if (widget.extraEntryBuilders != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children:
                    widget.extraEntryBuilders!.map((e) => e(70.0)).toList(),
              ),
          ],
        ));
  }

  bool shouldShowAvatarForSpace(Space space) {
    var spaces = _clientManager.spaces
        .where((element) => element.roomId == space.roomId);
    return spaces.length > 1;
  }
}
