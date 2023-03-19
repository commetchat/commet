import 'package:commet/cache/cache_file_provider.dart';
import 'package:commet/cache/file_provider.dart';
import 'package:commet/ui/atoms/video_player.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerDesktop extends StatefulWidget {
  const VideoPlayerDesktop(
      {required this.controller, required this.videoFile, this.width = 640, this.height = 340, super.key});
  final FileProvider videoFile;
  final int width;
  final int height;
  final VideoPlayerController controller;
  @override
  State<VideoPlayerDesktop> createState() => _VideoPlayerDesktopState();
}

class _VideoPlayerDesktopState extends State<VideoPlayerDesktop> {
  final Player player = Player();
  VideoController? controller;
  bool loaded = false;

  @override
  void initState() {
    super.initState();

    widget.controller.onPause = pause;
    widget.controller.onPlay = play;

    Future.microtask(() async {
      controller = await VideoController.create(player.handle);
      var file = await widget.videoFile.resolve();
      print("Loading video");
      print(file.toString());
      setState(() {
        loaded = true;
      });
      await player.open(Playlist([Media(file.toString())]));
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
    if (loaded)
      return Video(
        controller: controller,
      );
    return Placeholder();
  }
}
