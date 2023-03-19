import 'package:commet/ui/atoms/video_player.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerDesktop extends StatefulWidget {
  const VideoPlayerDesktop(
      {required this.controller, required this.videoUrl, this.width = 640, this.height = 340, super.key});
  final String videoUrl;
  final int width;
  final int height;
  final VideoPlayerController controller;
  @override
  State<VideoPlayerDesktop> createState() => _VideoPlayerDesktopState();
}

class _VideoPlayerDesktopState extends State<VideoPlayerDesktop> {
  final Player player = Player();
  VideoController? controller;

  @override
  void initState() {
    super.initState();

    widget.controller.onPause = pause;
    widget.controller.onPlay = play;

    Future.microtask(() async {
      controller = await VideoController.create(player.handle);
      player.open(Playlist([Media(widget.videoUrl)]));
      player.streams.error.listen(
        (event) {
          print("THERE WAS AN ERRORR BIATCH");
        },
      );
    });
  }

  void pause() {
    player.pause();
  }

  void play() {
    player.play();
  }

  @override
  Widget build(BuildContext context) {
    return Video(
      controller: controller,
    );
  }
}
