import 'package:commet/client/call_manager.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/ui/organisms/mini_call_menu/mini_call_menu.dart';
import 'package:commet/ui/organisms/sidebar_call_icon/sidebar_call_icon.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import 'package:tiamat/atoms/tile.dart';

class SidebarCallsList extends StatefulWidget {
  const SidebarCallsList(this.callManager, this.width, {super.key});
  final CallManager callManager;
  final double width;

  @override
  State<SidebarCallsList> createState() => _SidebarCallsListState();
}

class _SidebarCallsListState extends State<SidebarCallsList> {
  int count = 0;
  final GlobalKey listKey = GlobalKey();

  late OverlayEntry? overlay;

  VoipSession? selectedSession;
  LayerLink? link;

  NotifyingList<VoipSession> get sessions => widget.callManager.currentSessions;

  bool isHovered = false;
  bool showWhileUnhovered = false;

  @override
  void initState() {
    count = widget.callManager.currentSessions.length;

    sessions.onListUpdated.listen((event) {
      setState(() {});
    });

    sessions.onRemove.listen((event) {
      if (sessions[event] == selectedSession) {
        setState(() {
          selectedSession = null;
          link = null;
          overlay?.markNeedsBuild();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => addOverlay());

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ImplicitlyAnimatedList(
      key: listKey,
      shrinkWrap: true,
      itemData: widget.callManager.currentSessions,
      itemBuilder: (context, data) {
        return buildItem(data);
      },
    );
  }

  Widget buildItem(VoipSession data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: SidebarCallIconEntry(
        data,
        widget.width,
        updateSelection: onSelectionUpdate,
        onUnhovered: onUnhovered,
      ),
    );
  }

  void addOverlay() {
    overlay = OverlayEntry(builder: buildOverlay);
    Overlay.of(context).insert(overlay!);
  }

  Widget buildOverlay(BuildContext context) {
    if (Layout.mobile) {
      return Container();
    }

    if (link == null || selectedSession == null) {
      return Container();
    }

    if (showWhileUnhovered == false && isHovered == false) {
      return Container();
    }

    return CompositedTransformFollower(
        link: link!,
        targetAnchor: Alignment.bottomRight,
        followerAnchor: Alignment.bottomLeft,
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MouseRegion(
                onExit: (event) {
                  updateHover(false);
                },
                onEnter: (event) {
                  updateHover(true);
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 0, 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Tile.lowest(
                      child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: MiniCallMenu(selectedSession!)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  void updateHover(bool hovered) {
    setState(() {
      isHovered = hovered;
      showWhileUnhovered = selectedSession?.state == VoipState.incoming ||
          selectedSession?.state == VoipState.connecting;
      overlay?.markNeedsBuild();
    });
  }

  void onUnhovered() {
    updateHover(false);
  }

  void onSelectionUpdate(
      LayerLink link, VoipSession session, bool showWhileUnhovered) {
    setState(() {
      this.link = link;
      selectedSession = session;
    });
    updateHover(true);
  }
}
