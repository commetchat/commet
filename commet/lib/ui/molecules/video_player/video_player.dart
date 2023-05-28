import 'dart:async';

import 'package:commet/cache/file_provider.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/ui/molecules/video_player/video_player_implementation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import '../../atoms/gradient_background.dart';
import 'video_player_controller.dart';

import '../../atoms/icon_button.dart' as i;

class VideoPlayer extends StatefulWidget {
  const VideoPlayer(this.videoFile,
      {this.thumbnail,
      this.fileName,
      super.key,
      this.canGoFullscreen = false,
      this.onFullscreen,
      this.showProgressBar = true});
  final FileProvider videoFile;
  final ImageProvider? thumbnail;
  final bool showProgressBar;
  final bool canGoFullscreen;
  final String? fileName;
  final Function? onFullscreen;

  @override
  State<VideoPlayer> createState() => VideoPlayerState();
}

class VideoPlayerState extends State<VideoPlayer> {
  VideoPlayerController controller = VideoPlayerController();
  bool playing = false;
  bool inited = false;
  bool buffering = false;
  bool showThumbnail = true;
  bool shouldShowControls = true;
  bool isCompleted = false;
  double videoProgress = 0;
  bool updateSlider = true;
  Timer? uiHideTimer;

  StreamSubscription? bufferingListener;
  StreamSubscription? completedListener;
  StreamSubscription? progressListener;

  @override
  void initState() {
    bufferingListener = controller.isBuffering.listen((isBuffering) {
      setState(() {
        buffering = isBuffering;

        if (!isBuffering) {
          showThumbnail = false;
        }
      });
    });

    completedListener = controller.isCompleted.listen((event) {
      setState(() {
        isCompleted = event;
        if (isCompleted) shouldShowControls = true;
      });
    });

    progressListener = controller.onProgressed.listen((event) async {
      var length = await controller.getLength();
      if (updateSlider) {
        setState(() {
          videoProgress = clampDouble(
              event.inMilliseconds.toDouble() /
                  length.inMilliseconds.toDouble(),
              0,
              1);
        });
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    bufferingListener?.cancel();
    completedListener?.cancel();
    progressListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (inited) pickPlayer(),
        if (showThumbnail) thumbnail(),
        controls()
      ],
    );
  }

  Widget thumbnail() {
    return widget.thumbnail != null
        ? Image(
            fit: BoxFit.cover,
            image: widget.thumbnail!,
          )
        : Container(
            color: Colors.black,
          );
  }

  Widget controls() {
    return GestureDetector(
      onTap: showControls,
      child: MouseRegion(
        onEnter: (_) {
          showControls();
        },
        onExit: (_) {
          hideControls();
        },
        child: AnimatedOpacity(
          opacity: shouldShowControls ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: 0.9,
                      child: tiamat.CircleButton(
                        radius: 30,
                        icon: isCompleted
                            ? Icons.replay
                            : playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                        onPressed: () {
                          if (isCompleted) return replay();
                          if (playing) return pause();
                          play();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.canGoFullscreen || widget.showProgressBar)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: 50,
                    child: GradientBackground(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      backgroundColor: Theme.of(context)
                          .extension<ExtraColors>()!
                          .surfaceLow4
                          .withAlpha(200),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (widget.showProgressBar)
                            Expanded(
                              child: tiamat.Slider(
                                value: videoProgress,
                                min: 0,
                                max: 1,
                                onChangeEnd: (value) {
                                  updateSlider = true;
                                  seekPercent(value);
                                },
                                onChanged: (value) {
                                  setState(() {
                                    videoProgress = value;
                                  });
                                },
                                onChangeStart: (value) {
                                  updateSlider = false;
                                },
                              ),
                            ),
                          if (widget.canGoFullscreen)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                              child: i.IconButton(
                                icon: Icons.fullscreen_rounded,
                                size: 24,
                                onPressed: () {
                                  pause();
                                  widget.onFullscreen?.call();
                                },
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  void pause() async {
    setState(() {
      playing = false;
    });

    controller.pause();
  }

  void play() async {
    setState(() {
      inited = true;
      playing = true;
      controller.play();
      if (BuildConfig.MOBILE) hideControls();
    });
  }

  void replay() async {
    setState(() {
      playing = true;
      controller.replay();
      if (BuildConfig.MOBILE) hideControls();
    });
  }

  void showControls() {
    setState(() {
      shouldShowControls = true;
    });

    if (BuildConfig.MOBILE) {
      uiHideTimer?.cancel();
      uiHideTimer = Timer(const Duration(seconds: 3), hideControls);
    }
  }

  void hideControls() {
    setState(() {
      shouldShowControls = false;
    });
    uiHideTimer?.cancel();
  }

  void seekPercent(double percent) async {
    controller.seekTo(await controller.getLength() * percent);
    setState(() {
      videoProgress = percent;
    });
  }

  Widget pickPlayer() {
    return VideoPlayerImplementation(
        controller: controller, videoFile: widget.videoFile);
  }
}
