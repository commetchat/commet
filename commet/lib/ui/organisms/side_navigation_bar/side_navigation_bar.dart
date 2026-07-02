import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/profile/profile_component.dart';
import 'package:commet/client/components/sidebar_component/sidebar_entries_component.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/dot_indicator.dart';
import 'package:commet/ui/atoms/notification_badge.dart';
import 'package:commet/ui/molecules/space_selector.dart';
import 'package:commet/ui/organisms/home_screen/home_screen_view.dart';
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
      this.onRoomsViewSelected,
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
  final void Function()? onRoomsViewSelected;

  @override
  State<SideNavigationBar> createState() => _SideNavigationBarState();

  static Widget tooltip(String text, Widget child, BuildContext context) {
    if (MediaQuery.of(context).mobile) {
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

  late List<SidebarEntry> items;

  Client? filterClient;

  int notificationCount = 0;
  int highlightedNotificationCount = 0;

  @override
  void initState() {
    _clientManager = Provider.of<ClientManager>(context, listen: false);

    void setFilterClient(Client? event) {
      setState(() {
        filterClient = event;

        getSpaces();
      });
    }

    // showRoomsInSidebar = preferences.showRoomsInSidebar.v

    subs = [
      _clientManager.onSpaceChildUpdated.stream.listen((_) => onSpaceUpdate()),
      _clientManager.onSpaceUpdated.stream.listen((_) => onSpaceUpdate()),
      _clientManager.onSpaceRemoved.listen((_) => onSpaceUpdate()),
      _clientManager.onSpaceAdded.listen((_) => onSpaceUpdate()),
      _clientManager.onClientRemoved.stream.listen((_) => onSpaceUpdate()),
      _clientManager.onDirectMessageRoomUpdated.stream
          .listen(onDirectMessageUpdated),
      _clientManager.onRoomUpdated.stream.listen((_) => setState(() {
            updateNotificationCounts();
          })),
      EventBus.setFilterClient.stream.listen(setFilterClient),
      SidebarEntriesComponent.onOrderChanged.listen((_) => onSpaceUpdate()),
      preferences.showRoomsInSidebar.onChanged.listen((_) => setState(() {
            updateNotificationCounts();
          })),
    ];

    getSpaces();

    super.initState();
  }

  void updateNotificationCounts() {
    highlightedNotificationCount = 0;
    notificationCount = 0;
    for (var room in clientManager!.singleRooms(filterClient: filterClient)) {
      notificationCount += room.displayNotificationCount;
      highlightedNotificationCount += room.displayHighlightedNotificationCount;
    }
  }

  void getSpaces() {
    if (filterClient != null) {
      var entries =
          filterClient!.getComponent<SidebarEntriesComponent>()!.getEntries();

      items = entries;
    } else {
      _clientManager = Provider.of<ClientManager>(context, listen: false);
      items = _clientManager.clients.fold(List.empty(growable: true), (v, c) {
        var entries = c.getComponent<SidebarEntriesComponent>()!.getEntries();
        v.addAll(entries);
        return v;
      });

      Map<String, SpaceGroupSidebarEntry> mergedFolders = {};

      List<SidebarEntry> finalEntries = List.empty(growable: true);

      for (var item in items) {
        if (item is SpaceGroupSidebarEntry) {
          if (mergedFolders.containsKey(item.id)) {
            mergedFolders[item.id]!.spaces.addAll(item.spaces);
          } else {
            mergedFolders[item.id] = item;
          }
        } else {
          finalEntries.add(item);
        }
      }

      finalEntries.addAll(mergedFolders.values);
      items = finalEntries;
    }

    items.sort(
      (a, b) => a.order.compareTo(b.order),
    );
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
                items,
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
                    if (preferences.showRoomsInSidebar.value) ...[
                      SizedBox(
                        height: 4,
                      ),
                      SideNavigationBar.tooltip(
                          HomeScreenView.labelHomeRoomsList,
                          Stack(
                            children: [
                              ImageButton(
                                size: 70,
                                icon: Icons.tag,
                                onTap: () {
                                  widget.onRoomsViewSelected?.call();
                                },
                              ),
                              if (notificationCount > 0)
                                Align(
                                    alignment: AlignmentGeometry.xy(-1.55, 0),
                                    child: DotIndicator()),
                              if (highlightedNotificationCount > 0)
                                Align(
                                  alignment: AlignmentGeometry.topRight,
                                  child: NotificationBadge(
                                      highlightedNotificationCount),
                                )
                            ],
                          ),
                          context),
                    ],
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
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height / 2,
                    )
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
        .where((element) => element.identifier == space.identifier);
    return spaces.length > 1;
  }
}
