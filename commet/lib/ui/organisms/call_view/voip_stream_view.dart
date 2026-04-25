import 'dart:async';

import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/member.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/atoms/adaptive_context_menu.dart';
import 'package:commet/ui/organisms/call_view/call_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class VoipStreamView extends StatefulWidget {
  const VoipStreamView(this.stream, this.session,
      {super.key,
      this.fit = BoxFit.cover,
      this.borderColor,
      this.canFullscreen = true,
      this.onFullscreen});
  final VoipStream stream;
  final VoipSession session;
  final BoxFit fit;
  final Function()? onFullscreen;
  final Color? borderColor;
  final bool canFullscreen;

  @override
  State<VoipStreamView> createState() => _VoipStreamViewState();
}

class _VoipStreamViewState extends State<VoipStreamView>
    with TickerProviderStateMixin {
  late Member user;

  late AnimationController audioLevel;
  late List<StreamSubscription> subs;

  late GlobalKey rendererKey = GlobalKey();

  @override
  void initState() {
    Log.d("Initializing stream view!");
    var room = widget.session.client.getRoom(widget.session.roomId)!;
    subs = [
      widget.stream.onStreamChanged.listen(onStreamChanged),
      widget.session.onUpdateVolumeVisualizers.listen((_) => timer()),
    ];
    user = room.getMemberOrFallback(widget.stream.streamUserId);

    audioLevel = AnimationController(
        vsync: this, duration: CallView.volumeAnimationDuration);
    super.initState();
  }

  @override
  void dispose() {
    audioLevel.stop();
    for (var sub in subs) sub.cancel();
    super.dispose();
  }

  void timer() {
    audioLevel.animateTo(widget.stream.audiolevel);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: audioLevel,
        builder: (context, child) {
          return Material(
            color: Colors.transparent,
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                AdaptiveContextMenu(
                  items: streamContextMenuItems(widget.stream, user),
                  child: Container(
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
                ),
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
            ),
          );
        });
  }

  static List<tiamat.ContextMenuItem> streamContextMenuItems(
      VoipStream stream, Member user) {
    return [
      if (stream.direction == VoipStreamDirection.incoming) ...[
        tiamat.ContextMenuItem(
          text: "User",
          customBuilder: (context, onClicked) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 0, 0),
              child: Row(
                spacing: 12,
                children: [
                  tiamat.Avatar(
                      radius: 15,
                      image: user.avatar,
                      placeholderColor: user.defaultColor,
                      placeholderText: user.displayName),
                  tiamat.Text.name(
                    user.displayName,
                    color: user.defaultColor,
                  )
                ],
              ),
            );
          },
        ),
        tiamat.ContextMenuItem(
          text: "Volume",
          customBuilder: (context, onClicked) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
              child: StreamVolumeSlider(stream),
            );
          },
        )
      ]
    ];
  }

  Widget buildDefault() {
    switch (widget.stream.type) {
      case VoipStreamType.audio:
        return tiamat.Tile.low(
          child: Center(
              child: Stack(
            alignment: AlignmentGeometry.bottomRight,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: AnimatedOpacity(
                  opacity: widget.stream.isMuted ? 0.5 : 1.0,
                  duration: Duration(milliseconds: 200),
                  child: tiamat.Avatar(
                      border: Border.all(
                          strokeAlign: 0.5,
                          color: getBorderColor(context),
                          width: clampDouble(audioLevel.value * 15, 0, 5)),
                      radius: 50,
                      image: user.avatar,
                      placeholderColor: user.defaultColor,
                      placeholderText: user.displayName),
                ),
              ),
              AnimatedScale(
                scale: widget.stream.isMuted ? 1.0 : 0.0,
                curve: widget.stream.isMuted
                    ? Curves.bounceOut
                    : Curves.easeInExpo,
                duration:
                    Duration(milliseconds: widget.stream.isMuted ? 500 : 200),
                child: Container(
                  decoration: BoxDecoration(
                      color: ColorScheme.of(context).primary,
                      borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.mic_off_rounded,
                      size: 18,
                      color: ColorScheme.of(context).onPrimary,
                    ),
                  ),
                ),
              )
            ],
          )),
        );

      case VoipStreamType.video:
      case VoipStreamType.screenshare:
        return Center(
          child: widget.stream.buildVideoRenderer(widget.fit, rendererKey) ??
              const CircularProgressIndicator(),
        );
    }
  }

  Color getBorderColor(BuildContext context) {
    return Color.lerp(Theme.of(context).primaryColor,
        Theme.of(context).colorScheme.primary, audioLevel.value)!;
  }

  void onStreamChanged(void event) {
    print("Stream state changed!");
    setState(() {});
  }
}

class StreamVolumeSlider extends StatefulWidget {
  const StreamVolumeSlider(this.stream, {super.key});

  final VoipStream stream;
  @override
  State<StreamVolumeSlider> createState() => _StreamVolumeSliderState();
}

class _StreamVolumeSliderState extends State<StreamVolumeSlider> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        tiamat.Text.labelLow("${(widget.stream.volume * 100).toInt()}%"),
        Expanded(
          child: tiamat.Slider(
            min: 0.0,
            max: 2.5,
            value: widget.stream.volume,
            onChanged: (value) {
              print(value);
              setState(() {
                widget.stream.setVolume(value);
              });
            },
          ),
        ),
      ],
    );
  }
}
