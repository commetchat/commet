import 'package:commet/client/call_manager.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/ui/organisms/sidebar_call_icon/sidebar_call_icon.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/gestures/events.dart';
import 'package:flutter/widgets.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import 'package:tiamat/atoms/shader_background.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

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

  late OverlayEntry overlay;

  VoipSession? selectedSession;
  LayerLink? link;

  NotifyingList<VoipSession> get sessions => widget.callManager.currentSessions;

  @override
  void initState() {
    count = widget.callManager.currentSessions.length;

    sessions.onListUpdated.listen((event) {
      setState(() {});
    });

    sessions.onRemove.listen((event) {
      if (sessions[event].sessionId == selectedSession?.sessionId) {
        setState(() {
          selectedSession = null;
          link = null;
          overlay.markNeedsBuild();
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
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      child: SidebarCallIconEntry(
        data,
        widget.width,
        updateSelection: onSelectionUpdate,
      ),
    );
  }

  addOverlay() {
    overlay = OverlayEntry(builder: buildOverlay);
    Overlay.of(context).insert(overlay);
  }

  Widget buildOverlay(BuildContext context) {
    if (link == null || selectedSession == null) {
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
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Tile.low3(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        tiamat.Text.labelEmphasised("Incoming call!"),
                        tiamat.Text.label(selectedSession!.roomId),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            tiamat.Button(
                              text: "Accept",
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            tiamat.Button.secondary(
                              text: "Decline",
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  onSelectionUpdate(LayerLink link, VoipSession session) {
    setState(() {
      this.link = link;
      selectedSession = session;
    });
    overlay.markNeedsBuild();
  }
}
