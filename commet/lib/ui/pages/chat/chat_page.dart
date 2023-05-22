import 'dart:async';

import 'package:commet/client/client_manager.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/chat/desktop_chat_page.dart';
import 'package:commet/ui/pages/chat/mobile_chat_page.dart';
import 'package:commet/ui/pages/settings/room_settings_page.dart';
import 'package:commet/utils/notification/notification_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../client/client.dart';
import '../../../config/build_config.dart';
import '../../molecules/split_timeline_viewer.dart';
import '../../navigation/navigation_utils.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({required this.clientManager, super.key});
  final ClientManager clientManager;
  @override
  State<ChatPage> createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  ClientManager get clientManager => widget.clientManager;
  Space? selectedSpace;
  Room? selectedRoom;
  late bool homePageSelected = false;
  late GlobalKey<SplitTimelineViewerState> timelineKey =
      GlobalKey<SplitTimelineViewerState>();
  late Map<String, GlobalKey<SplitTimelineViewerState>> timelines = {};
  double height = -1;

  TimelineEvent? replyingToEvent;

  StreamController<Room> onRoomSelectionChanged = StreamController.broadcast();
  StreamController<void> onFocusMessageInput = StreamController.broadcast();

  StreamSubscription? onSpaceUpdateSubscription;
  StreamSubscription? onRoomUpdateSubscription;

  void selectHomePage() {
    homePageSelected = true;
  }

  void setReplyingEvent(TimelineEvent? event) {
    setState(() {
      replyingToEvent = event;
    });
    onFocusMessageInput.add(null);
  }

  void selectSpace(Space? space) {
    if (space == selectedSpace) return;

    if (space != null && !space.loaded) space.loadExtra();

    onSpaceUpdateSubscription?.cancel();
    onSpaceUpdateSubscription = space?.onUpdate.stream.listen(onSpaceUpdated);

    clearRoomSelection();
    if (kDebugMode) {
      // Weird hacky work around mentioned in #2
      timelines[selectedRoom?.localId]?.currentState?.prepareForDisposal();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _setSelectedSpace(space));
    } else {
      _setSelectedSpace(space);
    }
  }

  void onEventDoubleTap(TimelineEvent event) {
    setReplyingEvent(event);
  }

  void onEventLongPress(TimelineEvent event) {
    print("event long pressed");
  }

  void clearSpaceSelection() {
    onSpaceUpdateSubscription?.cancel();
    clearRoomSelection();
    selectSpace(null);
  }

  void clearRoomSelection() {
    onRoomUpdateSubscription?.cancel();

    if (kDebugMode) {
      // Weird hacky work around mentioned in #2
      timelines[selectedRoom?.localId]?.currentState!.prepareForDisposal();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _clearRoomSelection());
    } else {
      _clearRoomSelection();
    }
  }

  void selectHome() {
    onRoomUpdateSubscription?.cancel();
    if (kDebugMode) {
      // Weird hacky work around mentioned in #2
      timelines[selectedRoom?.localId]?.currentState!.prepareForDisposal();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          homePageSelected = true;
          selectedSpace = null;
        });
      });
    } else {
      setState(() {
        homePageSelected = true;
        selectedSpace = null;
      });
    }
  }

  void selectRoom(Room room) {
    if (room == selectedRoom) return;

    if (!timelines.containsKey(room.localId)) {
      timelines[room.localId] = GlobalKey<SplitTimelineViewerState>();
    }

    onRoomUpdateSubscription?.cancel();
    onRoomUpdateSubscription = room.onUpdate.stream.listen(onRoomUpdated);

    onRoomSelectionChanged.add(room);

    if (kDebugMode) {
      // Weird hacky work around mentioned in #2
      timelines[selectedRoom?.localId]?.currentState?.prepareForDisposal();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _setSelectedRoom(room));
    } else {
      _setSelectedRoom(room);
    }
  }

  void _setSelectedRoom(Room room) {
    setState(() {
      selectedRoom = room;
      replyingToEvent = null;
    });
  }

  void _setSelectedSpace(Space? space) {
    setState(() {
      selectedSpace = space;
      homePageSelected = false;
      replyingToEvent = null;
    });
  }

  void _clearRoomSelection() {
    setState(() {
      replyingToEvent = null;
      selectedRoom = null;
    });
  }

  @override
  void initState() {
    super.initState();
    notificationManager.addModifier(onlyNotifyNonSelectedRooms);
  }

  @override
  void dispose() {
    onSpaceUpdateSubscription?.cancel();
    onRoomUpdateSubscription?.cancel();

    notificationManager.removeModifier(onlyNotifyNonSelectedRooms);
    super.dispose();
  }

  NotificationContent? onlyNotifyNonSelectedRooms(NotificationContent content) {
    if (content.sentFrom == selectedRoom) {
      return null;
    }
    return content;
  }

  void onSpaceUpdated(void _) {
    setState(() {});
  }

  void onRoomUpdated(void _) {
    setState(() {});
  }

  void sendMessage(String message) {
    selectedRoom!.sendMessage(message, inReplyTo: replyingToEvent);
    setReplyingEvent(null);
  }

  void navigateRoomSettings() {
    if (selectedRoom != null) {
      NavigationUtils.navigateTo(
          context,
          RoomSettingsPage(
            room: selectedRoom!,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          return false;
        },
        // Listen to size change and offset the scroll view, so that we maintain timeline position when window changes size
        child: NotificationListener(
            onNotification: (SizeChangedLayoutNotification notification) {
              var prevHeight = height;
              height = MediaQuery.of(context).size.height;
              if (prevHeight == -1) return true;

              var diff = prevHeight - height;
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                var state = timelines[selectedRoom?.localId]?.currentState;
                if (state != null) {
                  state.controller.jumpTo(state.controller.offset + diff);
                }
              });

              return true;
            },
            child: SizeChangedLayoutNotifier(child: pickChatView())));
  }

  Widget pickChatView() {
    if (BuildConfig.DESKTOP) return DesktopChatPageView(state: this);
    if (BuildConfig.MOBILE) return MobileChatPageView(state: this);
    throw Exception("Unknown build config");
  }
}
