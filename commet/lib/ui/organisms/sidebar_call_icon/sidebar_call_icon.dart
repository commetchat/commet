import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/ui/organisms/sidebar_call_icon/sidebar_call_icon_view.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';

class SidebarCallIconEntry extends StatefulWidget {
  const SidebarCallIconEntry(this.session, this.width,
      {this.updateSelection, this.onUnhovered, super.key});
  final double width;
  final VoipSession session;

  final Function(LayerLink link, VoipSession session, bool showWhileUnhovered)?
      updateSelection;

  final Function()? onUnhovered;

  @override
  State<SidebarCallIconEntry> createState() => _SidebarCallIconEntryState();
}

class _SidebarCallIconEntryState extends State<SidebarCallIconEntry>
    with TickerProviderStateMixin {
  Room? room;
  final LayerLink link = LayerLink();
  StreamSubscription? stateChangeSub;
  VoipStream? stream;
  Timer? statUpdateTimer;
  late AnimationController audioLevel;

  @override
  void initState() {
    room = widget.session.client.getRoom(widget.session.roomId);
    stream = widget.session.remoteUserMediaStream;
    audioLevel = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    statUpdateTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      widget.session.updateStats();

      audioLevel.animateTo(stream?.audiolevel ?? 0);
    });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.updateSelection?.call(
          link, widget.session, widget.session.state == VoipState.incoming);
    });

    stateChangeSub = widget.session.onStateChanged.listen((event) {
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    stateChangeSub?.cancel();
    statUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) => widget.updateSelection?.call(
          link, widget.session, widget.session.state == VoipState.incoming),
      onExit: (_) => widget.onUnhovered?.call(),
      child: CompositedTransformTarget(
        link: link,
        child: AnimatedBuilder(
            animation: audioLevel,
            builder: (context, child) {
              return SidebarCallIconView(widget.session.state,
                  width: widget.width,
                  roomName: room?.displayName,
                  color: room?.defaultColor,
                  avatar: room?.avatar,
                  audioLevel: audioLevel.value,
                  onTap: () => EventBus.openRoom.add((
                        widget.session.roomId,
                        widget.session.client.identifier
                      )));
            }),
      ),
    );
  }
}
