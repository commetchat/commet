import 'dart:async';

import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/room.dart';
import 'package:commet/ui/organisms/mini_call_menu/mini_call_menu_connected.dart';
import 'package:commet/ui/organisms/mini_call_menu/mini_call_menu_incoming.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class MiniCallMenu extends StatefulWidget {
  const MiniCallMenu(this.session, {super.key});
  final VoipSession session;

  @override
  State<MiniCallMenu> createState() => _MiniCallMenuState();
}

class _MiniCallMenuState extends State<MiniCallMenu> {
  StreamSubscription? sub;
  late Room room;

  @override
  void initState() {
    sub = widget.session.onStateChanged.listen((event) {
      setState(() {});
    });
    room = widget.session.client.getRoom(widget.session.roomId)!;
    super.initState();
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.session.state) {
      case VoipState.incoming:
        return MiniCallMenuIncoming(
          callingUserName: widget.session.remoteUserName ?? "Unknown User",
          roomDisplayName: widget.session.roomName,
          isRoomDirectMessage: widget.session.client
                  .getComponent<DirectMessagesComponent>()
                  ?.isRoomDirectMessage(room) ??
              false,
          onAccept: () => widget.session.acceptCall(),
          onDecline: () => widget.session.declineCall(),
        );
      case VoipState.connected:
        return MiniCallMenuConnected(
          roomDisplayName: widget.session.roomName,
          isMicrophoneMuted: widget.session.isMicrophoneMuted,
          onHangUp: () {
            widget.session.hangUpCall();
          },
          onToggleMute: () async {
            await widget.session
                .setMicrophoneMute(!widget.session.isMicrophoneMuted);
            setState(() {});
          },
        );
      case VoipState.connecting:
        return const SizedBox(
            width: 20, height: 20, child: CircularProgressIndicator());
      default:
        return tiamat.Text.body(widget.session.state.name);
    }
  }
}
