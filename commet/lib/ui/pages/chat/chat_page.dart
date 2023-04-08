import 'package:commet/client/client_manager.dart';
import 'package:commet/ui/pages/chat/desktop_chat_page.dart';
import 'package:commet/ui/pages/chat/mobile_chat_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/widgets.dart';

import '../../../client/client.dart';
import '../../../config/build_config.dart';
import '../../molecules/split_timeline_viewer.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({required this.clientManager, super.key});
  final ClientManager clientManager;
  @override
  State<ChatPage> createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  ClientManager get clientManager => widget.clientManager;
  late Space? selectedSpace = null;
  late Room? selectedRoom = null;
  late bool homePageSelected = false;
  late GlobalKey<SplitTimelineViewerState> timelineKey =
      GlobalKey<SplitTimelineViewerState>();
  late Map<String, GlobalKey<SplitTimelineViewerState>> timelines = {};
  double height = -1;

  void selectHomePage() {
    homePageSelected = true;
  }

  void selectSpace(Space space) {
    if (kDebugMode) {
      // Weird hacky work around mentioned in #2
      timelines[selectedRoom?.identifier]?.currentState?.prepareForDisposal();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _setSelectedSpace(space));
    } else {
      _setSelectedSpace(space);
    }
  }

  void clearRoomSelection() {
    if (kDebugMode) {
      // Weird hacky work around mentioned in #2
      timelines[selectedRoom?.identifier]?.currentState!.prepareForDisposal();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _clearRoomSelection());
    } else {
      _clearRoomSelection();
    }
  }

  void selectHome() {
    setState(() {
      homePageSelected = true;
    });
  }

  void selectRoom(Room room) {
    if (room == selectedRoom) return;

    if (!timelines.containsKey(room.identifier)) {
      timelines[room.identifier] = GlobalKey<SplitTimelineViewerState>();
    }

    if (kDebugMode) {
      // Weird hacky work around mentioned in #2
      timelines[selectedRoom?.identifier]?.currentState?.prepareForDisposal();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _setSelectedRoom(room));
    } else {
      _setSelectedRoom(room);
    }
  }

  void _setSelectedRoom(Room room) {
    setState(() {
      selectedRoom = room;
      WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) {
          // timelines[selectedRoom?.identifier]?.currentState?.forceToBottom();
        },
      );
    });
  }

  void _setSelectedSpace(Space space) {
    setState(() {
      selectedSpace = space;
      homePageSelected = false;
    });
  }

  void _clearRoomSelection() {
    setState(() {
      selectedRoom = null;
    });
  }

  @override
  void initState() {
    super.initState();
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
              print("Size Changed");
              var prevHeight = height;
              height = MediaQuery.of(context).size.height;
              if (prevHeight == -1) return true;

              var diff = prevHeight - height;
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                var state = timelines[selectedRoom?.identifier]?.currentState;
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
