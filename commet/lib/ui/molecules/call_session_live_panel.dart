import 'dart:async';

import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

/// The "you are live" section of the voice panel: a red LIVE pill saying
/// what is live, a small 16:9 preview of every outgoing screen share / camera
/// stream (side by side when both are on), and a stop button on each preview.
/// Renders nothing while the session isn't sharing anything, so the panel
/// shrinks back on its own.
class CallSessionLivePanel extends StatefulWidget {
  const CallSessionLivePanel(
      {required this.session, this.onOpenRoom, super.key});
  final VoipSession session;

  /// Called when the user taps a preview; the caller opens the voice channel.
  final VoidCallback? onOpenRoom;

  @override
  State<CallSessionLivePanel> createState() => _CallSessionLivePanelState();
}

class _CallSessionLivePanelState extends State<CallSessionLivePanel> {
  StreamSubscription? _sub;

  String get labelLive => Intl.message("LIVE",
      name: "labelLive", desc: "Badge shown while sharing screen or camera");

  String get labelLiveScreen => Intl.message("Screen",
      name: "labelLiveScreen",
      desc: "Shown next to the LIVE badge while sharing the screen");

  String get labelLiveCamera => Intl.message("Camera",
      name: "labelLiveCamera",
      desc: "Shown next to the LIVE badge while the camera is on");

  String get labelLiveScreenAndCamera => Intl.message("Screen + Camera",
      name: "labelLiveScreenAndCamera",
      desc:
          "Shown next to the LIVE badge while sharing screen and camera together");

  String get tooltipStopScreenshare => Intl.message("Stop sharing",
      name: "tooltipStopScreenshare",
      desc: "Tooltip of the button that stops the screen share");

  String get tooltipStopCamera => Intl.message("Turn off camera",
      name: "tooltipStopCamera",
      desc: "Tooltip of the button that turns the camera off");

  @override
  void initState() {
    _sub = widget.session.onStateChanged.listen((_) => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<VoipStream> get _previews => widget.session.streams
      .where((s) =>
          s.direction == VoipStreamDirection.outgoing &&
          (s.type == VoipStreamType.screenshare ||
              s.type == VoipStreamType.video))
      .toList();

  String _whatIsLive(List<VoipStream> previews) {
    final screen = previews.any((s) => s.type == VoipStreamType.screenshare);
    final camera = previews.any((s) => s.type == VoipStreamType.video);
    if (screen && camera) return labelLiveScreenAndCamera;
    if (camera) return labelLiveCamera;
    return labelLiveScreen;
  }

  @override
  Widget build(BuildContext context) {
    final previews = _previews;
    if (previews.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Row(
            spacing: 8,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: ColorScheme.of(context).error,
                    borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                child: tiamat.Text.labelEmphasised(labelLive,
                    color: ColorScheme.of(context).onError),
              ),
              Flexible(
                child: tiamat.Text.labelLow(_whatIsLive(previews),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          Row(
            spacing: 6,
            children: [
              for (final stream in previews)
                Expanded(
                  child: _LivePreview(
                    key: ValueKey("live-preview-${stream.streamId}"),
                    stream: stream,
                    onTap: widget.onOpenRoom,
                    stop: _stopControlFor(stream),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  _StopControl _stopControlFor(VoipStream stream) {
    switch (stream.type) {
      case VoipStreamType.screenshare:
      case VoipStreamType.screenshareAudio:
        return _StopControl(
          key: const ValueKey("live-stop-screenshare"),
          tooltip: tooltipStopScreenshare,
          icon: Icons.stop_screen_share_rounded,
          onPressed: widget.session.stopScreenshare,
        );
      case VoipStreamType.video:
      case VoipStreamType.audio:
        return _StopControl(
          key: const ValueKey("live-stop-video"),
          tooltip: tooltipStopCamera,
          icon: Icons.videocam_off_rounded,
          onPressed: widget.session.stopCamera,
        );
    }
  }
}

class _StopControl {
  const _StopControl(
      {required this.key,
      required this.tooltip,
      required this.icon,
      required this.onPressed});
  final Key key;
  final String tooltip;
  final IconData icon;
  final Future<void> Function() onPressed;
}

/// One 16:9 thumbnail. Listens to the stream itself because the legacy 1:1
/// path initialises its renderer asynchronously and only reports that on
/// [VoipStream.onStreamChanged], not on the session.
class _LivePreview extends StatefulWidget {
  const _LivePreview(
      {required this.stream, required this.stop, this.onTap, super.key});
  final VoipStream stream;
  final _StopControl stop;
  final VoidCallback? onTap;

  @override
  State<_LivePreview> createState() => _LivePreviewState();
}

class _LivePreviewState extends State<_LivePreview> {
  StreamSubscription? _sub;
  final GlobalKey _rendererKey = GlobalKey();

  @override
  void initState() {
    _sub = widget.stream.onStreamChanged.listen((_) => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: ColorScheme.of(context).surfaceContainerLowest),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              child: widget.stream
                      .buildVideoRenderer(BoxFit.cover, _rendererKey) ??
                  const SizedBox.shrink(),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: BoxDecoration(
                      color: ColorScheme.of(context).surface.withAlpha(200),
                      borderRadius: BorderRadius.circular(6)),
                  child: Tooltip(
                    message: widget.stop.tooltip,
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: tiamat.IconButton(
                        key: widget.stop.key,
                        size: 16,
                        iconColor: ColorScheme.of(context).error,
                        icon: widget.stop.icon,
                        onPressed: widget.stop.onPressed,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
