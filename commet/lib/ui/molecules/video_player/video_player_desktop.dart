import 'package:commet/cache/cache_file_provider.dart';
import 'package:commet/cache/file_provider.dart';
import 'package:commet/ui/molecules/video_player/video_player.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'video_player_controller.dart';

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
  Uri? file;

  @override
  void initState() {
    super.initState();

    widget.controller.attach(pause: pause, play: play, replay: replay, seekTo: seekTo, getLength: getLength);

    player.streams.position.listen((event) {
      widget.controller.setProgress(event);
    });

    player.streams.isCompleted.listen(
      (completed) {
        widget.controller.setCompleted(completed);
      },
    );

    Future.microtask(() async {
      controller = await VideoController.create(player.handle);
      file = await widget.videoFile.resolve();

      await player.open(Playlist([Media(file.toString())]));

      widget.controller.setBuffering(false);

      setState(() {
        loaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loaded)
      return Video(
        controller: controller,
      );
    return Placeholder();
  }

  Future<void> pause() async {
    player.pause();
  }

  Future<void> play() async {
    player.play();
  }

  Future<void> replay() async {
    await player.open(Playlist([Media(file.toString())]));
  }

  Future<void> seekTo(Duration duration) async {
    await player.seek(duration);
  }

  Future<Duration> getLength() async {
    return player.state.duration;
  }
}
