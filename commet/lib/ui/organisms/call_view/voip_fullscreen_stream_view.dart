import 'dart:async';

import 'package:commet/client/components/rtc_screen_share_annotation/rtc_screen_share_annotation_component.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/ui/organisms/call_view/call_grid_tiles.dart';
import 'package:commet/ui/organisms/call_view/voip_stream_view.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class VoipFullscreenStreamView extends StatefulWidget {
  const VoipFullscreenStreamView(
      {required this.stream, required this.session, super.key});
  final VoipStream stream;
  final VoipSession session;

  @override
  State<VoipFullscreenStreamView> createState() =>
      _VoipFullscreenStreamViewState();
}

class _VoipFullscreenStreamViewState extends State<VoipFullscreenStreamView> {
  RTCScreenShareAnnotationSession? annotationSession;
  RTCScreenShareAnnotationComponent? component;
  StreamSubscription? sub;

  @override
  void initState() {
    component =
        widget.session.client.getComponent<RTCScreenShareAnnotationComponent>();

    annotationSession = component?.getExistingSession(widget.session);
    // Screen share audio can be published after the fullscreen view opened.
    sub = widget.session.onStateChanged.listen((_) => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioStream = callGridTiles(widget.session.streams)
        .where((tile) => tile.stream == widget.stream)
        .firstOrNull
        ?.audioStream;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return MouseRegion(
              child: VoipStreamView(
                widget.stream,
                widget.session,
                audioStream: audioStream,
                canFullscreen: false,
              ),
              onHover: (event) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                final x = event.localPosition.dx / width;
                final y = event.localPosition.dy / height;

                if (annotationSession != null) {
                  annotationSession?.setCursorPosition(
                      streamId: widget.stream.streamId, x: x, y: y);
                }
              },
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(spacing: 5, children: [
            if (component != null)
              tiamat.CircleButton(
                icon: Icons.mouse,
                onPressed: () async {
                  var session =
                      await component?.getOrCreateSession(widget.session);
                  setState(() {
                    annotationSession = session;
                  });
                },
              )
          ]),
        )
      ],
    );
  }
}
