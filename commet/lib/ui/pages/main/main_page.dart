import 'dart:async';
import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/navigation/navigation_signals.dart';
import 'package:commet/ui/navigation/navigation_utils.dart';
import 'package:commet/ui/pages/main/main_page_view_desktop.dart';
import 'package:commet/ui/pages/main/main_page_view_mobile.dart';
import 'package:commet/ui/pages/settings/room_settings_page.dart';
import 'package:commet/utils/notification/notification_manager.dart';
import 'package:commet/utils/orientation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class MainPage extends StatefulWidget {
  const MainPage(this.clientManager, {super.key});
  final ClientManager clientManager;

  @override
  State<MainPage> createState() => MainPageState();
}

enum MainPageSubView {
  space,
  home,
}

class MainPageState extends State<MainPage> {
  Space? _currentSpace;
  Room? _currentRoom;
  Room? _previousRoom;
  Space? _previousSpace;
  MainPageSubView _currentView = MainPageSubView.home;

  StreamSubscription? onSpaceUpdateSubscription;
  StreamSubscription? onRoomUpdateSubscription;

  MainPageSubView get currentView => _currentView;

  ClientManager get clientManager => widget.clientManager;

  Peer get currentUser => getCurrentUser();
  Space? get currentSpace => _currentSpace;
  Room? get currentRoom => _currentRoom;

  @override
  void initState() {
    super.initState();
    notificationManager.addModifier(dontNotifySelectedRooms);

    NavigationSignals.openRoom.stream.listen(onOpenRoomSignal);
  }

  @override
  void dispose() {
    notificationManager.removeModifier(dontNotifySelectedRooms);
    super.dispose();
  }

  Future<NotificationContent?> dontNotifySelectedRooms(
      NotificationContent content) async {
    if (BuildConfig.DESKTOP && !await windowManager.isFocused()) {
      return content;
    }

    if (content.sentFrom != null &&
        content.sentFrom!.identifier == currentRoom?.identifier) {
      return null;
    }

    return content;
  }

  Peer getCurrentUser() {
    if (currentRoom != null) return currentRoom!.client.self!;

    if (currentSpace != null) return currentSpace!.client.self!;

    if (_previousRoom != null) return _previousRoom!.client.self!;

    if (_previousSpace != null) return _previousSpace!.client.self!;

    return clientManager.clients.first.self!;
  }

  @override
  Widget build(BuildContext context) {
    if (BuildConfig.DESKTOP) return MainPageViewDesktop(this);
    if (BuildConfig.MOBILE) return MainPageViewMobile(this);

    if (BuildConfig.WEB) {
      if (OrientationUtils.getCurrentOrientation(context) ==
          Orientation.landscape) {
        return MainPageViewDesktop(this);
      } else {
        return MainPageViewMobile(this);
      }
    }

    throw Exception("Unknown build config");
  }

  void selectSpace(Space? space) {
    if (space == currentSpace) return;

    if (space != null && !space.fullyLoaded) space.loadExtra();
    clearRoomSelection();

    onSpaceUpdateSubscription?.cancel();
    onSpaceUpdateSubscription = space?.onUpdate.listen(onSpaceUpdated);
    setState(() {
      _previousSpace = _currentSpace;
      _currentSpace = space;
      _currentView = MainPageSubView.space;
    });
  }

  void selectRoom(Room room) {
    if (room == currentRoom) return;

    onRoomUpdateSubscription?.cancel();
    onRoomUpdateSubscription = room.onUpdate.listen(onRoomUpdated);

    setState(() {
      _previousRoom = currentRoom;
      _currentRoom = room;
    });
  }

  void clearRoomSelection() {
    onRoomUpdateSubscription?.cancel();
    setState(() {
      if (currentRoom != null) {
        _previousRoom = currentRoom;
      }
      _currentRoom = null;
    });
  }

  void clearSpaceSelection() {
    setState(() {
      clearRoomSelection();

      if (currentSpace != null) {
        _previousSpace = currentSpace;
      }

      _currentSpace = null;
      _currentView = MainPageSubView.home;
    });
  }

  void selectHome() {
    setState(() {
      _currentView = MainPageSubView.home;
      clearSpaceSelection();
    });
  }

  void onSpaceUpdated(void _) {
    setState(() {});
  }

  void onRoomUpdated(void _) {
    setState(() {});
  }

  void onOpenRoomSignal(String roomId) {
    for (var client in clientManager.clients) {
      if (client.hasRoom(roomId)) {
        var room = client.getRoom(roomId);

        if (room != null) {
          var spacesWithRoom =
              client.spaces.where((element) => element.containsRoom(roomId));

          if (spacesWithRoom.isNotEmpty) {
            selectSpace(spacesWithRoom.first);
          }

          selectRoom(room);
          break;
        }
      }
    }
  }

  void navigateRoomSettings() {
    if (currentRoom != null) {
      NavigationUtils.navigateTo(
          context,
          RoomSettingsPage(
            room: currentRoom!,
          ));
    }
  }
}
