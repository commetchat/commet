import 'dart:async';
import 'dart:math';

import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/room.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/anchored_popover.dart';
import 'package:commet/ui/atoms/speaking_indicator.dart';
import 'package:commet/ui/molecules/call_session_live_panel.dart';
import 'package:commet/ui/organisms/call_view/call_view.dart';
import 'package:commet/ui/organisms/soundboard/soundboard_button.dart';
import 'package:commet/ui/organisms/soundboard/soundboard_call_controller.dart';
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
  /// The control buttons sit in boxes the height of the whole row, so
  /// tiamat's 15px default left them looking lost in all that space.
  static const double iconSize = 20;

  late List<StreamSubscription> subs;
  Timer? statUpdateTimer;
  late AnimationController audioLevel;
  Room? room;
  late final SoundboardCallController soundboard;

  @override
  void initState() {
    room = widget.session.client.getRoom(widget.session.roomId);
    soundboard = SoundboardCallController.acquire(widget.session);

    audioLevel = AnimationController(
        vsync: this, duration: CallView.volumeAnimationDuration);

    subs = [
      widget.session.onStateChanged.listen((event) {
        setState(() {});
      }),
      widget.session.onUpdateVolumeVisualizers.listen((_) async {
        await widget.session.updateStats();
        audioLevel.animateTo(localAudioLevel);
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
    soundboard.release();
    super.dispose();
  }

  /// How loud we are in the call: only our own outgoing media, so the
  /// indicator shows whether we are being heard rather than whether anyone
  /// is talking. Screen share audio is not us talking. A legacy call carries
  /// the microphone in a stream typed video while the camera is on, so the
  /// camera stream counts too.
  double get localAudioLevel => widget.session.streams
      .where((stream) =>
          stream.direction == VoipStreamDirection.outgoing &&
          stream.type != VoipStreamType.screenshare &&
          stream.type != VoipStreamType.screenshareAudio)
      .fold(0.0, (level, stream) => max(level, stream.audiolevel));

  void openRoom() {
    EventBus.doOpenRoom(widget.session.roomId,
        clientId: widget.session.client.identifier);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildControlsRow(context),
          // Grows the panel below the button row while sharing screen /
          // camera; renders nothing otherwise.
          CallSessionLivePanel(session: widget.session, onOpenRoom: openRoom),
        ],
      ),
    );
  }

  Widget buildControlsRow(BuildContext context) {
    return InkWell(
        onTap: openRoom,
        child: SizedBox(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    pickAnimation(
                        entry: widget.session,
                        child: SizedBox(
                          height: widget.height,
                          width: widget.height,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: buildActivityIndicator(context),
                          ),
                        )),
                    Flexible(
                      child: tiamat.Text(widget.session.roomName,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
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
                            size: iconSize,
                            iconColor: widget.session.isMicrophoneMuted
                                ? ColorScheme.of(context).error
                                : null,
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
                              if (widget.session.isDeafened) {
                                clientManager!.callManager.undeafen();
                              } else {
                                clientManager!.callManager.deafen();
                              }
                            },
                            size: iconSize,
                            iconColor: widget.session.isDeafened
                                ? ColorScheme.of(context).error
                                : null,
                            icon: widget.session.isDeafened
                                ? Icons.headset_off_rounded
                                : Icons.headset_rounded)),
                  ),
                  SizedBox(
                    width: widget.height,
                    height: widget.height,
                    child: SoundboardButton(
                      controller: soundboard,
                      deafened: widget.session.isDeafened,
                      alignment: PopoverAlignment.start,
                      builder: (context, onPressed) => tiamat.IconButton(
                        onPressed: onPressed,
                        size: iconSize,
                        iconColor: onPressed == null
                            ? Theme.of(context).disabledColor
                            : null,
                        icon: Icons.surround_sound_rounded,
                      ),
                    ),
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
                            size: iconSize,
                            iconColor: ColorScheme.of(context).error,
                            icon: Icons.call_end_rounded)),
                  ),
                ],
              ),
            ],
          ),
        ));
  }

  /// Crossed out and red while we are not transmitting, and then static:
  /// lighting up for voice activity would suggest the microphone is live.
  Widget buildActivityIndicator(BuildContext context) {
    final silenced =
        widget.session.isMicrophoneMuted || widget.session.isDeafened;

    if (silenced) {
      return Icon(
        Icons.volume_off_rounded,
        color: ColorScheme.of(context).error,
        size: iconSize,
      );
    }

    return AnimatedBuilder(
      animation: audioLevel,
      builder: (context, child) {
        return Icon(
          Icons.volume_up_rounded,
          color: Color.lerp(
            ColorScheme.of(context).onSurface,
            SpeakingIndicator.color,
            audioLevel.value,
          ),
          size: iconSize,
        );
      },
    );
  }

  Widget pickAnimation({required VoipSession entry, required Widget child}) {
    if (entry.state == VoipState.incoming) {
      return RingShakerAnimation(child: child);
    }

    return child;
  }
}
