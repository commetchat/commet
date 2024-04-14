import 'dart:async';

import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/ui/atoms/lightbox.dart';
import 'package:commet/ui/layout/bento.dart';
import 'package:commet/ui/organisms/call_view/voip_stream_view.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class CallView extends StatefulWidget {
  const CallView(
    this.currentSession, {
    this.setMicrophoneMute,
    this.pickScreenshareSource,
    this.stopScreenshare,
    this.pickCamera,
    this.disableCamera,
    this.hangUp,
    super.key,
  });
  final VoipSession currentSession;

  final Future<void> Function(bool)? setMicrophoneMute;
  final Future<void> Function()? pickScreenshareSource;
  final Future<void> Function()? stopScreenshare;
  final Future<void> Function()? pickCamera;
  final Future<void> Function()? disableCamera;
  final Future<void> Function()? hangUp;

  @override
  State<CallView> createState() => _CallViewState();
}

class _CallViewState extends State<CallView> {
  Timer? statTimer;
  StreamSubscription? sub;
  bool isMouseHovering = false;
  VoipStream? mainStream;

  @override
  void initState() {
    super.initState();
    sub = widget.currentSession.onStateChanged.listen((event) {
      setState(() {});
    });

    //mainStream = widget.currentSession.remoteUserMediaStream;

    statTimer = Timer.periodic(const Duration(milliseconds: 200), timer);
  }

  @override
  void dispose() {
    statTimer?.cancel();
    sub?.cancel();
    super.dispose();
  }

  void timer(Timer timer) async {
    await widget.currentSession.updateStats();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.currentSession.state) {
      case VoipState.connected:
        return callConnectedView();

      default:
        return const Placeholder();
    }
  }

  Widget callConnectedView() {
    return MouseRegion(
      onEnter: (event) {
        setState(() {
          isMouseHovering = true;
        });
      },
      onExit: (event) {
        setState(() {
          isMouseHovering = false;
        });
      },
      child: tiamat.Tile.low4(
          child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              var ratio = constraints.maxWidth / constraints.maxHeight;

              if (ratio > 1) {
                return Row(children: generateLayout());
              } else {
                return Column(children: generateLayout());
              }
            },
          ),
          AnimatedOpacity(
            opacity: isMouseHovering ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 5,
                children: [
                  tiamat.CircleButton(
                      icon: Icons.screen_share_outlined,
                      onPressed: widget.pickScreenshareSource),
                  if (widget.currentSession.isSharingScreen)
                    tiamat.CircleButton(
                      icon: Icons.stop_screen_share,
                      onPressed: widget.stopScreenshare,
                    ),
                  tiamat.CircleButton(
                    icon: widget.currentSession.isMicrophoneMuted
                        ? Icons.mic_off
                        : Icons.mic,
                    onPressed: () async {
                      await widget.setMicrophoneMute
                          ?.call(!widget.currentSession.isMicrophoneMuted);
                      setState(() {});
                    },
                  ),
                  tiamat.CircleButton(
                    icon: widget.currentSession.isCameraEnabled
                        ? Icons.camera_alt
                        : Icons.camera_alt_outlined,
                    onPressed: widget.currentSession.isCameraEnabled
                        ? widget.disableCamera
                        : widget.pickCamera,
                  ),
                  tiamat.CircleButton(
                    icon: Icons.call_end,
                    onPressed: () async {
                      await widget.hangUp?.call();
                      setState(() {});
                    },
                  )
                ],
              ),
            ),
          )
        ],
      )),
    );
  }

  List<Widget> generateLayout() {
    return [
      if (mainStream != null)
        Flexible(
          flex: 100,
          fit: FlexFit.tight,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    mainStream = null;
                  });
                },
                child: VoipStreamView(
                  mainStream!,
                  widget.currentSession,
                  borderColor: Colors.white,
                  onFullscreen: () {
                    Lightbox.show(context,
                        aspectRatio: mainStream!.aspectRatio,
                        customWidget:
                            VoipStreamView(mainStream!, widget.currentSession));
                  },
                  fit: BoxFit.contain,
                  key: ValueKey(
                      "callView_mainStreamView_${mainStream!.streamId}"),
                ),
              ),
            ),
          ),
        ),
      Flexible(
        fit: FlexFit.tight,
        flex: 75,
        child: Center(
          child: BentoLayout(widget.currentSession.streams
              .where((element) => element != mainStream)
              .map((e) => GestureDetector(
                  onTap: () {
                    setState(() {
                      mainStream = e;
                    });
                  },
                  child: VoipStreamView(
                    key: ValueKey("callView__${e.streamId}"),
                    e,
                    widget.currentSession,
                    onFullscreen: () {
                      Lightbox.show(context,
                          aspectRatio: e.aspectRatio,
                          customWidget:
                              VoipStreamView(e, widget.currentSession));
                    },
                  )))
              .toList()),
        ),
      )
    ];
  }
}
