import 'dart:async';
import 'dart:math';

import 'package:commet/cache/cache_file_provider.dart';
import 'package:commet/cache/file_provider.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/ui/molecules/video_player/video_player_desktop.dart';
import 'package:commet/ui/molecules/video_player/video_player_mobile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import '../../atoms/gradient_background.dart';
import 'video_player_controller.dart';

class VideoPlayer extends StatefulWidget {
  const VideoPlayer(this.videoFile, {this.thumbnail, this.fileName, super.key, this.showProgressBar = true});
  final FileProvider videoFile;
  final ImageProvider? thumbnail;
  final bool showProgressBar;
  final String? fileName;

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
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
          videoProgress = clampDouble(event.inMilliseconds.toDouble() / length.inMilliseconds.toDouble(), 0, 1);
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
      children: [if (inited) pickPlayer(), if (showThumbnail) thumbnail(), controls()],
    );
  }

  Widget thumbnail() {
    return Image(
      fit: BoxFit.cover,
      image: widget.thumbnail!,
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
          duration: Duration(milliseconds: 300),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              widget.fileName != null
                  ? GradientBackground(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      backgroundColor: Theme.of(context).extension<ExtraColors>()!.surfaceLow1.withAlpha(200),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                        child: tiamat.Text.body(widget.fileName!),
                      ))
                  : const SizedBox(
                      height: 20,
                    ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
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
              widget.showProgressBar
                  ? GradientBackground(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      backgroundColor: Theme.of(context).extension<ExtraColors>()!.surfaceLow4.withAlpha(200),
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
                    )
                  : const SizedBox(
                      height: 30,
                    ),
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
      uiHideTimer = Timer(Duration(seconds: 3), hideControls);
    }
  }

  void hideControls() {
    setState(() {
      shouldShowControls = false;
    });
    uiHideTimer?.cancel();
  }

  void seekPercent(double percent) async {
    print("Trying to seek percent");
    controller.seekTo(await controller.getLength() * percent);
    setState(() {
      videoProgress = percent;
    });
  }

  Widget pickPlayer() {
    if (BuildConfig.ANDROID || BuildConfig.IOS || BuildConfig.WEB) {
      return VideoPlayerMobile(
        controller: controller,
        videoFile: widget.videoFile,
      );
    }
    return VideoPlayerDesktop(controller: controller, videoFile: widget.videoFile);
  }
}
