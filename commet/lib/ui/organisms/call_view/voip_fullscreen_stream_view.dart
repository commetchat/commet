import 'dart:async';

import 'package:commet/client/components/rtc_screen_share_annotation/rtc_screen_share_annotation_component.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/organisms/call_view/call_grid_tiles.dart';
import 'package:commet/ui/organisms/call_view/voip_stream_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:media_kit_video/media_kit_video.dart'
    show defaultEnterNativeFullscreen, defaultExitNativeFullscreen;
import 'package:window_manager/window_manager.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

/// A call stream covering the whole screen: the app window goes fullscreen
/// (the browser tab on web) and the stream fills it edge to edge.
class VoipFullscreenStreamView extends StatefulWidget {
  const VoipFullscreenStreamView(
      {required this.stream, required this.session, super.key});
  final VoipStream stream;
  final VoipSession session;

  static Future<void> show(BuildContext context,
      {required VoipStream stream, required VoipSession session}) {
    // Before the route is pushed: browsers only grant fullscreen while the
    // click that asked for it is still being handled.
    final fullscreen = _NativeFullscreen.enter();
    return Navigator.of(context, rootNavigator: true)
        .push(PageRouteBuilder(
          opaque: true,
          barrierColor: Colors.black,
          transitionDuration: const Duration(milliseconds: 150),
          reverseTransitionDuration: const Duration(milliseconds: 150),
          pageBuilder: (_, __, ___) =>
              VoipFullscreenStreamView(stream: stream, session: session),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ))
        .whenComplete(fullscreen.exit);
  }

  @override
  State<VoipFullscreenStreamView> createState() =>
      _VoipFullscreenStreamViewState();
}

class _VoipFullscreenStreamViewState extends State<VoipFullscreenStreamView> {
  static String get labelStreamEnded => Intl.message("This stream has ended",
      name: "labelStreamEnded",
      desc: "Shown in fullscreen when the stream being watched stops");

  static String labelUserStoppedSharingScreen(String user) =>
      Intl.message("$user stopped sharing their screen",
          name: "labelUserStoppedSharingScreen",
          args: [user],
          desc: "Shown in fullscreen when the screen share being watched ends");

  static String get labelExitFullscreen => Intl.message("Exit fullscreen",
      name: "labelExitFullscreen",
      desc: "Button that leaves the fullscreen view of a call stream");

  static const _controlsTimeout = Duration(milliseconds: 2500);

  RTCScreenShareAnnotationSession? annotationSession;
  RTCScreenShareAnnotationComponent? component;
  StreamSubscription? sub;

  bool showControls = true;
  Timer? hideControlsTimer;

  @override
  void initState() {
    component =
        widget.session.client.getComponent<RTCScreenShareAnnotationComponent>();

    annotationSession = component?.getExistingSession(widget.session);
    // Screen share audio can be published after the fullscreen view opened,
    // and the stream can end while it is open.
    sub = widget.session.onStateChanged.listen((_) {
      if (mounted) setState(() {});
    });
    wakeControls();
    super.initState();
  }

  @override
  void dispose() {
    sub?.cancel();
    hideControlsTimer?.cancel();
    super.dispose();
  }

  /// Shows the controls and the cursor, then hides them again once the
  /// pointer rests, so they don't sit on top of the stream.
  void wakeControls() {
    hideControlsTimer?.cancel();
    hideControlsTimer = Timer(_controlsTimeout, () {
      if (mounted) setState(() => showControls = false);
    });
    if (!showControls) setState(() => showControls = true);
  }

  void close() => Navigator.of(context).maybePop();

  KeyEventResult onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      close();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // By id, not the stream we were opened with: the session replaces the
    // stream object of a publication when its video is muted and unmuted, or
    // after a reconnect, and the old one is disposed (issue #47).
    final tile = callGridTiles(widget.session.streams)
        .where((tile) => tile.stream.streamId == widget.stream.streamId)
        .firstOrNull;
    final stream = tile?.stream;

    return Focus(
      autofocus: true,
      onKeyEvent: onKeyEvent,
      child: Material(
        color: Colors.black,
        // The share ended or the sharer left. Kept open rather than closed
        // under the user: a stream that comes back with the same id (a
        // reconnect) shows up here again.
        child: stream == null
            ? buildEnded()
            : buildStream(stream, tile?.audioStream),
      ),
    );
  }

  Widget buildStream(VoipStream stream, VoipStream? audioStream) {
    return MouseRegion(
      cursor: showControls ? MouseCursor.defer : SystemMouseCursors.none,
      onHover: (_) => wakeControls(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: wakeControls,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return MouseRegion(
                    child: VoipStreamView(
                      stream,
                      widget.session,
                      audioStream: audioStream,
                      canFullscreen: false,
                      fit: BoxFit.contain,
                    ),
                    onHover: (event) {
                      final x = event.localPosition.dx / constraints.maxWidth;
                      final y = event.localPosition.dy / constraints.maxHeight;

                      annotationSession?.setCursorPosition(
                          streamId: widget.stream.streamId, x: x, y: y);
                    },
                  );
                },
              ),
            ),
            SafeArea(
              child: IgnorePointer(
                ignoring: !showControls,
                child: AnimatedOpacity(
                  opacity: showControls ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Wrap(spacing: 5, children: [
                      if (component != null)
                        tiamat.CircleButton(
                          icon: Icons.mouse,
                          onPressed: () async {
                            var session = await component
                                ?.getOrCreateSession(widget.session);
                            if (!mounted) return;
                            setState(() {
                              annotationSession = session;
                            });
                          },
                        ),
                      Tooltip(
                        message: labelExitFullscreen,
                        child: tiamat.CircleButton(
                          icon: Icons.fullscreen_exit,
                          onPressed: close,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEnded() {
    final user = widget.session.client
        .getRoom(widget.session.roomId)
        ?.getMemberOrFallback(widget.stream.streamUserId);
    final isScreenShare = widget.stream.type == VoipStreamType.screenshare;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              if (user != null)
                tiamat.Avatar(
                    radius: 32,
                    image: user.avatar,
                    placeholderColor: user.defaultColor,
                    placeholderText: user.displayName),
              // Always light: the background is black whatever the theme.
              Text(labelStreamEnded,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white)),
              if (user != null && isScreenShare)
                tiamat.Text.labelLow(
                    labelUserStoppedSharingScreen(user.displayName),
                    color: Colors.white70),
              const SizedBox(height: 4),
              tiamat.Button(
                text: labelExitFullscreen,
                onTap: close,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Puts the app window (the browser tab on web, the whole display on mobile)
/// into fullscreen, and gives back what it found when done.
class _NativeFullscreen {
  _NativeFullscreen._(this._entered);

  final Future<bool> _entered;

  static _NativeFullscreen enter() => _NativeFullscreen._(_enter());

  /// Whether this call switched fullscreen on, and so should switch it off.
  static Future<bool> _enter() async {
    try {
      if (PlatformUtils.isLinux || PlatformUtils.isWindows) {
        // Already fullscreen (F11): leave it that way when the view closes.
        if (await windowManager.isFullScreen()) return false;
        await windowManager.setFullScreen(true);
        return true;
      }
      if (PlatformUtils.isWeb) {
        await defaultEnterNativeFullscreen();
        return true;
      }
      if (PlatformUtils.isAndroid) {
        // Immersive only: no orientation lock, a camera stream can be
        // portrait.
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        return true;
      }
    } catch (e, s) {
      Log.onError(e, s, content: "Failed to enter fullscreen");
    }
    return false;
  }

  Future<void> exit() async {
    if (!await _entered) return;
    try {
      if (PlatformUtils.isLinux || PlatformUtils.isWindows) {
        await windowManager.setFullScreen(false);
      } else if (PlatformUtils.isWeb) {
        await defaultExitNativeFullscreen();
      } else if (PlatformUtils.isAndroid) {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    } catch (e, s) {
      Log.onError(e, s, content: "Failed to leave fullscreen");
    }
  }
}
