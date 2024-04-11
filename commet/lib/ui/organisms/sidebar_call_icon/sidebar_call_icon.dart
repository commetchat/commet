import 'package:commet/client/client.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/organisms/sidebar_call_icon/sidebar_call_icon_view.dart';
import 'package:flutter/material.dart';

class SidebarCallIconEntry extends StatefulWidget {
  const SidebarCallIconEntry(this.session, this.width,
      {this.updateSelection, super.key});
  final double width;
  final VoipSession session;

  final Function(LayerLink link, VoipSession session)? updateSelection;

  @override
  State<SidebarCallIconEntry> createState() => _SidebarCallIconEntryState();
}

class _SidebarCallIconEntryState extends State<SidebarCallIconEntry> {
  Room? room;
  final LayerLink link = LayerLink();
  @override
  void initState() {
    room = widget.session.client.getRoom(widget.session.roomId);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.updateSelection?.call(link, widget.session);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) => widget.updateSelection?.call(link, widget.session),
      child: CompositedTransformTarget(
        link: link,
        child: SidebarCallIconView(
          width: widget.width,
          color: room?.defaultColor,
          avatar: room?.avatar,
        ),
      ),
    );
  }
}
