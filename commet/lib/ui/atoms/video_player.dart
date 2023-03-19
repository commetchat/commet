import 'package:commet/cache/cache_file_provider.dart';
import 'package:commet/cache/file_provider.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/ui/atoms/video_player_desktop.dart';
import 'package:commet/ui/atoms/video_player_mobile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:tiamat/tiamat.dart';

class VideoPlayerController {
  void pause() {
    onPause?.call();
  }

  void play() {
    onPlay?.call();
  }

  void Function()? onPause;

  void Function()? onPlay;
}

class VideoPlayer extends StatefulWidget {
  const VideoPlayer(this.videoFile, {this.thumbnail, super.key});
  final FileProvider videoFile;
  final ImageProvider? thumbnail;

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  VideoPlayerController controller = VideoPlayerController();
  bool playing = false;
  bool loaded = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Stack(
        fit: StackFit.loose,
        children: [
          SizedBox(
              child: loaded
                  ? pickPlayer()
                  : widget.thumbnail != null
                      ? Image(
                          image: widget.thumbnail!,
                        )
                      : null),
          Row(
            children: [
              Button.secondary(
                text: "Play",
                onTap: play,
              ),
              Button.secondary(
                text: "Pause",
                onTap: pause,
              ),
            ],
          )
        ],
      ),
    );
  }

  void pause() {
    setState(() {
      playing = false;
    });

    controller.pause();
  }

  void play() {
    setState(() {
      playing = true;
      loaded = true;
      controller.play();
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
