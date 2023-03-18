import 'package:commet/client/client_manager.dart';
import 'package:commet/ui/pages/chat/desktop_chat_page.dart';
import 'package:commet/ui/pages/chat/mobile_chat_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/widgets.dart';

import '../../../client/client.dart';
import '../../../config/build_config.dart';
import '../../molecules/timeline_viewer.dart';

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
  late GlobalKey<TimelineViewerState> timelineKey = GlobalKey<TimelineViewerState>();
  late Map<String, GlobalKey<TimelineViewerState>> timelines = {};

  void selectHomePage() {
    homePageSelected = true;
  }

  void selectSpace(Space space) {
    setState(() {
      selectedSpace = space;
      homePageSelected = false;
    });
  }

  void clearRoomSelection() {
    setState(() {
      selectedRoom = null;
    });
  }

  void selectHome() {
    setState(() {
      homePageSelected = true;
    });
  }

  void selectRoom(Room room) {
    if (room == selectedRoom) return;

    if (!timelines.containsKey(room.identifier)) {
      timelines[room.identifier] = GlobalKey<TimelineViewerState>();
    }

    if (kDebugMode) {
      // Weird hacky work around mentioned in #2
      timelines[selectedRoom?.identifier]?.currentState!.prepareForDisposal();
      WidgetsBinding.instance.addPostFrameCallback((_) => _setSelectedRoom(room));
    } else {
      _setSelectedRoom(room);
    }
  }

  void _setSelectedRoom(Room room) {
    setState(() {
      selectedRoom = room;
      WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) {
          timelines[selectedRoom?.identifier]?.currentState!.forceToBottom();
        },
      );
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
        child: pickChatView());
  }

  Widget pickChatView() {
    if (BuildConfig.DESKTOP) return DesktopChatPageView(state: this);
    if (BuildConfig.MOBILE) return MobileChatPageView(state: this);
    throw Exception("Unknown build config");
  }
}
