import 'dart:async';
import 'dart:math';

import 'package:commet/client/client_manager.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/navigation/navigation_signals.dart';
import 'package:commet/ui/pages/chat/desktop_chat_page.dart';
import 'package:commet/ui/pages/chat/mobile_chat_page.dart';
import 'package:commet/ui/pages/settings/room_settings_page.dart';
import 'package:commet/utils/debounce.dart';
import 'package:commet/utils/notification/notification_manager.dart';
import 'package:commet/utils/orientation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:window_manager/window_manager.dart';
import '../../../client/attachment.dart';
import '../../../client/client.dart';
import '../../../config/build_config.dart';
import '../../molecules/timeline_viewer.dart';
import '../../navigation/navigation_utils.dart';

enum EventInteractionType {
  reply,
  edit,
}

enum SubView {
  space,
  directMessages,
  home,
}

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

  SubView selectedView = SubView.space;

  late GlobalKey<TimelineViewerState> timelineKey =
      GlobalKey<TimelineViewerState>();
  late Map<String, GlobalKey<TimelineViewerState>> timelines = {};
  double height = -1;

  bool processing = false;

  List<PendingFileAttachment> attachments = List.empty(growable: true);

  DateTime lastSetTyping = DateTime.fromMicrosecondsSinceEpoch(0);

  Debouncer typingStatusDebouncer =
      Debouncer(delay: const Duration(seconds: 5));

  EventInteractionType? interactionType;
  TimelineEvent? interactingEvent;

  StreamController<Room> onRoomSelectionChanged = StreamController.broadcast();

  StreamController<void> onFocusMessageInput = StreamController.broadcast();
  StreamController<String> setMessageInputText = StreamController.broadcast();

  StreamSubscription? onSpaceUpdateSubscription;
  StreamSubscription? onRoomUpdateSubscription;

  StreamSubscription? onOpenRoomSubscription;

  String? get relatedEventSenderName => interactingEvent == null
      ? null
      : selectedRoom?.client
              .fetchPeer(interactingEvent!.senderId)
              .displayName ??
          interactingEvent!.senderId;

  Color? get relatedEventSenderColor => interactingEvent == null
      ? null
      : selectedRoom?.getColorOfUser(interactingEvent!.senderId);

  void onInputTextUpdated(String currentText) {
    if (currentText.isEmpty) {
      stopTyping();
      typingStatusDebouncer.cancel();
      lastSetTyping = DateTime.fromMicrosecondsSinceEpoch(0);
    } else {
      if ((DateTime.now().difference(lastSetTyping)).inSeconds > 3) {
        selectedRoom?.setTypingStatus(true);
        lastSetTyping = DateTime.now();
      }
      typingStatusDebouncer.run(stopTyping);
    }
  }

  void stopTyping() {
    selectedRoom?.setTypingStatus(false);
  }

  void clearRelatedEvents() {
    setState(() {
      interactingEvent = null;
    });
  }

  void editLastMessage() {
    if (!selectedRoom!.permissions.canUserEditMessages) return;
    if (interactionType != null) return;

    for (int i = 0; i < min(20, selectedRoom!.timeline!.events.length); i++) {
      var event = selectedRoom!.timeline!.events[i];

      if (event.senderId != selectedRoom!.client.user!.identifier) continue;

      if (event.type != EventType.message) continue;

      setInteractingEvent(event, type: EventInteractionType.edit);
      break;
    }
  }

  void setInteractingEvent(TimelineEvent? event, {EventInteractionType? type}) {
    setState(() {
      if (event == null) {
        interactingEvent = null;
        interactionType = null;
        return;
      }
      interactingEvent = event;
      interactionType = type;

      switch (type) {
        case EventInteractionType.reply:
          onFocusMessageInput.add(null);
          break;
        case EventInteractionType.edit:
          if (event.body != null) {
            setMessageInputText.add(event.body!);
          }
          onFocusMessageInput.add(null);
          break;
        default:
          break;
      }
    });
  }

  void addAttachment(PendingFileAttachment attachment) {
    if (selectedRoom!.client.maxFileSize != null) {
      if (attachment.size != null &&
          attachment.size! > selectedRoom!.client.maxFileSize!) {
        AdaptiveDialog.show(context, builder: (_) {
          return const SizedBox(
              height: 100,
              child: Center(
                  child:
                      tiamat.Text.label("This file is too large to upload!")));
        }, title: "Max file size exceeded");

        return;
      }
    }

    setState(() {
      attachments.add(attachment);
    });
  }

  void removeAttachment(PendingFileAttachment attachment) {
    setState(() {
      attachments.remove(attachment);
    });
  }

  void clearAttachments() {
    setState(() {
      attachments.clear();
    });
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

  void selectDirectMessages() {
    onRoomUpdateSubscription?.cancel();
    if (kDebugMode) {
      // Weird hacky work around mentioned in #2
      timelines[selectedRoom?.localId]?.currentState!.prepareForDisposal();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          selectedView = SubView.directMessages;
          selectedSpace = null;
        });
      });
    } else {
      setState(() {
        selectedView = SubView.directMessages;
        selectedSpace = null;
      });
    }
  }

  void selectHome() {
    onRoomUpdateSubscription?.cancel();
    if (kDebugMode) {
      // Weird hacky work around mentioned in #2
      timelines[selectedRoom?.localId]?.currentState!.prepareForDisposal();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          selectedView = SubView.home;
          selectedSpace = null;
        });
      });
    } else {
      setState(() {
        selectedView = SubView.home;
        selectedSpace = null;
      });
    }
  }

  void selectRoom(Room room) {
    if (room == selectedRoom) return;

    if (!timelines.containsKey(room.localId)) {
      timelines[room.localId] = GlobalKey<TimelineViewerState>();
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
      interactingEvent = null;
      clearAttachments();

      if (room.timeline!.events.length < 50) {
        room.timeline!.loadMoreHistory();
      }
    });
  }

  void _setSelectedSpace(Space? space) {
    setState(() {
      selectedSpace = space;
      selectedView = SubView.space;
      interactingEvent = null;
      clearAttachments();
    });
  }

  void _clearRoomSelection() {
    setState(() {
      interactingEvent = null;
      selectedRoom = null;
      clearAttachments();
    });
  }

  @override
  void initState() {
    super.initState();
    notificationManager.addModifier(onlyNotifyNonSelectedRooms);
    onOpenRoomSubscription =
        NavigationSignals.openRoom.stream.listen(onOpenRoomSignal);
  }

  void onOpenRoomSignal(String roomId) {
    for (var client in clientManager.clients) {
      if (client.roomExists(roomId)) {
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

  @override
  void dispose() {
    onSpaceUpdateSubscription?.cancel();
    onRoomUpdateSubscription?.cancel();

    notificationManager.removeModifier(onlyNotifyNonSelectedRooms);
    onOpenRoomSubscription?.cancel();
    super.dispose();
  }

  Future<NotificationContent?> onlyNotifyNonSelectedRooms(
      NotificationContent content) async {
    // Always show notification if the window does not have focus
    if (BuildConfig.DESKTOP) {
      if (!(await windowManager.isFocused())) {
        return content;
      }
    }

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

  void sendMessage(String message) async {
    setState(() {
      processing = true;
    });

    var processedAttachments =
        await selectedRoom!.processAttachments(attachments);

    setState(() {
      processing = false;
    });

    selectedRoom!.sendMessage(
        message: message,
        inReplyTo: interactionType == EventInteractionType.reply
            ? interactingEvent
            : null,
        replaceEvent: interactionType == EventInteractionType.edit
            ? interactingEvent
            : null,
        processedAttachments: processedAttachments);

    selectedRoom?.setTypingStatus(false);

    setInteractingEvent(null);
    clearAttachments();
    setMessageInputText.add("");
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

    if (BuildConfig.WEB) {
      if (OrientationUtils.getCurrentOrientation(context) ==
          Orientation.landscape) {
        return DesktopChatPageView(state: this);
      } else {
        return MobileChatPageView(state: this);
      }
    }

    throw Exception("Unknown build config");
  }
}
