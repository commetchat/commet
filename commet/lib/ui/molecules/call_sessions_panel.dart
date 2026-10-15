import 'dart:async';

import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/room.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/organisms/call_view/call_view.dart';
import 'package:commet/utils/animation/ring_shaker.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class CallSessionsPanel extends StatefulWidget {
  const CallSessionsPanel({this.height = 50, super.key});
  final double height;
  @override
  State<CallSessionsPanel> createState() => _CallSessionsPanelState();
}

class _CallSessionsPanelState extends State<CallSessionsPanel> {
  StreamSubscription? sub;

  @override
  void initState() {
    sub = clientManager!.callManager.currentSessions.onListUpdated.listen((_) {
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: ColorScheme.of(context).surfaceTint.withAlpha(10),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          for (var entry in clientManager!.callManager.currentSessions)
            ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(8),
              child: CallSessionPanel(
                session: entry,
                height: widget.height,
              ),
            ),
        ],
      ),
    );
  }
}

class CallSessionPanel extends StatefulWidget {
  const CallSessionPanel({required this.session, this.height = 40, super.key});
  final VoipSession session;
  final double height;
  @override
  State<CallSessionPanel> createState() => _CallSessionPanelState();
}

class _CallSessionPanelState extends State<CallSessionPanel>
    with TickerProviderStateMixin {
  late List<StreamSubscription> subs;
  Timer? statUpdateTimer;
  late AnimationController audioLevel;
  Room? room;

  @override
  void initState() {
    room = widget.session.client.getRoom(widget.session.roomId);

    audioLevel = AnimationController(
        vsync: this, duration: CallView.volumeAnimationDuration);

    subs = [
      widget.session.onStateChanged.listen((event) {
        setState(() {});
      }),
      widget.session.onUpdateVolumeVisualizers.listen((_) async {
        await widget.session.updateStats();
        audioLevel.animateTo(widget.session.generalAudioLevel);
      })
    ];

    super.initState();
  }

  @override
  void dispose() {
    for (var sub in subs) {
      sub.cancel();
    }
    statUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          EventBus.doOpenRoom(widget.session.roomId,
              clientId: widget.session.client.identifier);
        },
        child: SizedBox(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  pickAnimation(
                      entry: widget.session,
                      child: SizedBox(
                        height: widget.height,
                        width: widget.height,
                        child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: AnimatedBuilder(
                              animation: audioLevel,
                              builder: (context, child) {
                                return Container(
                                  child: Icon(
                                    Icons.volume_up_rounded,
                                    color: Color.lerp(
                                        ColorScheme.of(context).onSurface,
                                        ColorScheme.of(context).inversePrimary,
                                        audioLevel.value),
                                    size: 16,
                                  ),
                                );
                              },
                            )),
                      )),
                  tiamat.Text(widget.session.roomName),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: widget.height,
                    height: widget.height,
                    child: AspectRatio(
                        aspectRatio: 1.0,
                        child: tiamat.IconButton(
                            onPressed: () {
                              if (widget.session.isMicrophoneMuted) {
                                clientManager!.callManager.unmute();
                              } else {
                                clientManager!.callManager.mute();
                              }
                            },
                            icon: widget.session.isMicrophoneMuted
                                ? Icons.mic_off_rounded
                                : Icons.mic_rounded)),
                  ),
                  SizedBox(
                    width: widget.height,
                    height: widget.height,
                    child: AspectRatio(
                        aspectRatio: 1.0,
                        child: tiamat.IconButton(
                            onPressed: () {
                              widget.session.hangUpCall();
                            },
                            iconColor: ColorScheme.of(context).error,
                            icon: Icons.call_end_rounded)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget pickAnimation({required VoipSession entry, required Widget child}) {
    if (entry.state == VoipState.incoming) {
      return RingShakerAnimation(child: child);
    }

    return child;
  }
}
