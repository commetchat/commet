import 'dart:async';

import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/member.dart';
import 'package:commet/debug/log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class VoipStreamView extends StatefulWidget {
  const VoipStreamView(this.stream, this.session,
      {super.key,
      this.fit = BoxFit.cover,
      this.borderColor,
      this.onFullscreen});
  final VoipStream stream;
  final VoipSession session;
  final BoxFit fit;
  final Function()? onFullscreen;
  final Color? borderColor;

  @override
  State<VoipStreamView> createState() => _VoipStreamViewState();
}

class _VoipStreamViewState extends State<VoipStreamView>
    with TickerProviderStateMixin {
  late Member user;

  late AnimationController audioLevel;

  late GlobalKey rendererKey = GlobalKey();

  @override
  void initState() {
    Log.d("Initializing stream view!");
    Timer.periodic(const Duration(milliseconds: 200), timer);
    var room = widget.session.client.getRoom(widget.session.roomId)!;
    user = room.getMemberOrFallback(widget.stream.streamUserId);
    audioLevel = AnimationController(vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    audioLevel.stop();
    super.dispose();
  }

  void timer(Timer timer) async {
    audioLevel.animateTo(widget.stream.audiolevel,
        duration: const Duration(milliseconds: 200));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: audioLevel,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                  clipBehavior: Clip.antiAlias,
                  foregroundDecoration: widget.borderColor != null
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: widget.borderColor!,
                              width: 2,
                              strokeAlign: BorderSide.strokeAlignCenter))
                      : null,
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(8)),
                  child: buildDefault()),
              if (widget.stream.type == VoipStreamType.video ||
                  widget.stream.type == VoipStreamType.screenshare)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: tiamat.IconButton(
                    icon: Icons.fullscreen,
                    size: 20,
                    onPressed: widget.onFullscreen,
                  ),
                )
            ],
          );
        });
  }

  Widget buildDefault() {
    switch (widget.stream.type) {
      case VoipStreamType.audio:
        return tiamat.Tile.low(
          child: Center(
              child: tiamat.Avatar(
                  border: Border.all(
                      strokeAlign: BorderSide.strokeAlignOutside,
                      color: getBorderColor(context),
                      width: clampDouble(audioLevel.value * 15, 0, 5)),
                  radius: 50,
                  image: user.avatar,
                  placeholderText: user.displayName)),
        );

      case VoipStreamType.video:
      case VoipStreamType.screenshare:
        return widget.stream.buildVideoRenderer(widget.fit, rendererKey) ??
            const Placeholder();
    }
  }

  Color getBorderColor(BuildContext context) {
    return Color.lerp(Theme.of(context).primaryColor,
        Theme.of(context).colorScheme.primary, audioLevel.value)!;
  }
}
