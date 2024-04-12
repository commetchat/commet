import 'dart:async';

import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/matrix/components/voip/matrix_voip_session.dart';
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

  @override
  void initState() {
    sub = widget.session.onStateChanged.listen((event) {
      setState(() {});
    });
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
          roomDisplayName: widget.session.roomName,
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
        return CircularProgressIndicator();
      default:
        return tiamat.Text.body(widget.session.state.name);
    }
  }
}
