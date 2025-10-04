import 'dart:async';

import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip_room/voip_room_component.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/ui/atoms/shimmer_loading.dart';
import 'package:commet/ui/layout/bento.dart';
import 'package:commet/ui/organisms/call_view/call.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class VoipRoomView extends StatefulWidget {
  final VoipRoomComponent voip;
  const VoipRoomView(this.voip, {super.key});

  @override
  State<VoipRoomView> createState() => _VoipRoomViewState();
}

class _VoipRoomViewState extends State<VoipRoomView> {
  VoipSession? currentSession;
  String? callServerUrl;
  late List<String> participants;

  StreamSubscription? sub;

  @override
  void initState() {
    currentSession = widget.voip.currentSession;
    participants = widget.voip.getCurrentParticipants();

    sub = widget.voip.onParticipantsChanged.listen((_) {
      // when the participant list changes, the resolved focus may change
      updateCallUrl();

      setState(() {
        participants = widget.voip.getCurrentParticipants();
      });
    });

    updateCallUrl();
    super.initState();
  }

  void updateCallUrl() {
    widget.voip.getCallServerUrl().then((url) {
      if (mounted) print("Call url: ${url}");
      setState(() {
        callServerUrl = url;
      });
    });
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var color = Theme.of(context).colorScheme.surfaceContainer;

    if (currentSession == null) return unjoinedView(color);

    return CallWidget(currentSession!);
  }

  Column unjoinedView(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: widget.voip.room.isE2EE && BuildConfig.RELEASE
              ? e2eeUnsupportedView()
              : joinCallView(),
        ),
        Align(
          alignment: AlignmentGeometry.bottomLeft,
          child: tiamat.Tooltip(
            text: widget.voip.room.isE2EE
                ? "This room is encrypted, your call is secure and private"
                : "This room is not encrypted, your call may be accessible by the server operator",
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.voip.room.isE2EE)
                    Icon(Icons.lock, color: Colors.greenAccent),
                  if (!widget.voip.room.isE2EE)
                    Icon(Icons.lock_open, color: Colors.red),
                  SizedBox(
                    width: 3,
                  ),
                  Shimmer(
                    child: ShimmerLoading(
                        isLoading: callServerUrl == null,
                        child: callServerUrl == null
                            ? Container(
                                height: 16,
                                width: 150,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: color),
                              )
                            : tiamat.Text.labelLow(callServerUrl!)),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Column joinCallView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (participants.isNotEmpty)
          Expanded(
              child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: BentoLayout(participants.map((item) {
              final member = widget.voip.room.getMemberOrFallback(item);
              return Container(
                clipBehavior: Clip.antiAlias,
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(8)),
                child: tiamat.Tile.low(
                  child: Center(
                      child: tiamat.Avatar(
                          radius: 50,
                          image: member.avatar,
                          placeholderColor: member.defaultColor,
                          placeholderText: member.displayName)),
                ),
              );
            }).toList()),
          )),
        if (widget.voip.room.isE2EE)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: tiamat.Text.error(
                "End-to-end encrypted calls are still under development, and may contain bugs or security issues. Use at your own risk."),
          ),
        if (participants.isEmpty)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(8)),
                  child: tiamat.Tile.surfaceContainer(
                      child: Center(
                          child: tiamat.Text.labelLow("No one's here...")))),
            ),
          ),
        if (widget.voip.canJoinCall)
          Center(
            child: tiamat.Button(
              text: CommonStrings.promptJoin,
              onTap: joinRoomCall,
            ),
          ),
        if (!widget.voip.canJoinCall)
          Center(
              child: tiamat.Text.labelLow(
                  "You do not have permission to join this call"))
      ],
    );
  }

  joinRoomCall() async {
    final session = await widget.voip.joinCall();
    if (session != null) {
      setState(() {
        currentSession = session;
      });
    }
  }

  e2eeUnsupportedView() {
    return Center(
        child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: tiamat.Text.label(
          "Sorry, End-to-end encrypted voice rooms are not yet supported."),
    ));
  }
}
