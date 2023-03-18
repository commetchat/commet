import 'package:commet/config/build_config.dart';
import 'package:commet/ui/atoms/video_player_desktop.dart';
import 'package:commet/ui/atoms/video_player_mobile.dart';
import 'package:dart_vlc/dart_vlc.dart';
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
  const VideoPlayer(this.videoUrl, {super.key});
  final String videoUrl;

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  VideoPlayerController controller = VideoPlayerController();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Stack(
        fit: StackFit.loose,
        children: [
          SizedBox(child: pickPlayer()),
          Row(
            children: [
              Button.secondary(
                text: "Play",
                onTap: controller.play,
              ),
              Button.secondary(
                text: "Pause",
                onTap: controller.pause,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget pickPlayer() {
    if (BuildConfig.ANDROID || BuildConfig.IOS || BuildConfig.WEB)
      return VideoPlayerMobile(
        controller: controller,
        videoUrl: widget.videoUrl,
      );
    return VideoPlayerDesktop(controller: controller, videoUrl: widget.videoUrl);
  }
}
