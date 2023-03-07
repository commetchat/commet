import 'package:commet/config/build_config.dart';
import 'package:commet/ui/pages/chat/desktop_chat_page.dart';
import 'package:commet/ui/pages/chat/mobile_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: pickChatView());
  }

  Widget pickChatView() {
    if (BuildConfig.DESKTOP) return DesktopChatPage();
    if (BuildConfig.MOBILE) return MobileChatPage();
    throw Exception("Unknown build config");
  }
}
