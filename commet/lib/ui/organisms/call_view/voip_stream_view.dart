import 'dart:async';

import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/member.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/adaptive_context_menu.dart';
import 'package:commet/ui/atoms/speaking_indicator.dart';
import 'package:commet/ui/organisms/soundboard/soundboard_emoji_overlay.dart';
import 'package:commet/ui/organisms/soundboard/soundboard_overlay_registry.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class VoipStreamView extends StatefulWidget {
  const VoipStreamView(this.stream, this.session,
      {super.key,
      this.audioStream,
      this.fit = BoxFit.cover,
      this.borderColor,
      this.canFullscreen = true,
      this.onFullscreen});
  final VoipStream stream;
  final VoipSession session;

  /// Audio that plays along with [stream] but has no tile of its own (screen
  /// share audio). When set, the tile's volume control drives it.
  final VoipStream? audioStream;
  final BoxFit fit;
  final Function()? onFullscreen;
  final Color? borderColor;
  final bool canFullscreen;

  @override
  State<VoipStreamView> createState() => _VoipStreamViewState();
}

class _VoipStreamViewState extends State<VoipStreamView> {
  late Member user;

  bool speaking = false;
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

    super.initState();
  }

  @override
  void dispose() {
    for (var sub in subs) sub.cancel();
    super.dispose();
  }

  void timer() {
    final value = widget.stream.audiolevel > 0.5;
    if (value != speaking) setState(() => speaking = value);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          AdaptiveContextMenu(
            items: streamContextMenuItems(widget.stream, user,
                audioStream: widget.audioStream),
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
          if (preferences.developerMode.value)
            Align(
              alignment: AlignmentGeometry.topLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: ColorScheme.of(context).surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: tiamat.Text.labelLow(widget.stream.stats),
                ),
              ),
            ),
          if (widget.canFullscreen &&
                  widget.stream.type == VoipStreamType.video ||
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
  }

  static List<tiamat.ContextMenuItem> streamContextMenuItems(
      VoipStream stream, Member user,
      {VoipStream? audioStream}) {
    // Screen share audio has no tile of its own, so its volume lives on the
    // screen share tile. Discord does the same: the stream's volume is
    // separate from the person's mic volume.
    final volumeStream = audioStream ?? stream;
    return [
      if (stream.direction == VoipStreamDirection.incoming) ...[
        tiamat.ContextMenuItem(
          text: "User",
          customBuilder: (context, onClicked, {closeMenu}) {
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
          customBuilder: (context, onClicked, {closeMenu}) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
              child: StreamVolumeSlider(volumeStream),
            );
          },
        )
      ]
    ];
  }

  Widget buildDefault() {
    final showBadge = widget.stream.isMuted || widget.stream.isDeafened;
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
                  opacity: showBadge ? 0.5 : 1.0,
                  duration: Duration(milliseconds: 200),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SpeakingIndicator(
                        speaking: speaking && !showBadge,
                        radius: 50,
                        child: tiamat.Avatar(
                            radius: 50,
                            image: user.avatar,
                            placeholderColor: user.defaultColor,
                            placeholderText: user.displayName),
                      ),
                      // Soundboard emoji burst: overlay only on the sender's
                      // avatar, timed by the real sound duration.
                      ListenableBuilder(
                        listenable: SoundboardOverlayRegistry.instance,
                        builder: (context, _) {
                          final entry = SoundboardOverlayRegistry.instance
                              .entryFor(user.identifier);
                          if (entry == null) {
                            return const SizedBox.shrink();
                          }
                          return Positioned(
                            top: 0,
                            right: 0,
                            child: SoundboardEmojiOverlay(
                              key: ValueKey(
                                  'sb_${entry.soundId}_${entry.expiresAtMs}'),
                              emoji: entry.emoji,
                              image: entry.image,
                              durationMs: entry.overlayMs,
                              onDone: () => SoundboardOverlayRegistry.instance
                                  .clearUser(user.identifier),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedScale(
                scale: showBadge ? 1.0 : 0.0,
                curve: showBadge ? Curves.bounceOut : Curves.easeInExpo,
                duration: Duration(milliseconds: showBadge ? 500 : 200),
                child: Container(
                  decoration: BoxDecoration(
                      color: widget.stream.isDeafened
                          ? ColorScheme.of(context).error
                          : ColorScheme.of(context).primary,
                      borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      widget.stream.isDeafened
                          ? Icons.headset_off_rounded
                          : Icons.mic_off_rounded,
                      size: 18,
                      color: widget.stream.isDeafened
                          ? ColorScheme.of(context).onError
                          : ColorScheme.of(context).onPrimary,
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

      case VoipStreamType.screenshareAudio:
        // Never a tile of its own: the call grid folds it into the screen
        // share tile (see callGridTiles).
        return const SizedBox.shrink();
    }
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
