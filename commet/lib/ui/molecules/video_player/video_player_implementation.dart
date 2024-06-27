import 'dart:typed_data';

import 'package:commet/cache/file_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'video_player_controller.dart';

class VideoPlayerImplementation extends StatefulWidget {
  const VideoPlayerImplementation(
      {required this.controller,
      required this.videoFile,
      this.decodeFirstFrame = false,
      this.width = 640,
      this.height = 340,
      super.key});
  final FileProvider videoFile;
  final int width;
  final int height;
  final bool decodeFirstFrame;
  final VideoPlayerController controller;
  @override
  State<VideoPlayerImplementation> createState() =>
      _VideoPlayerImplementationState();
}

class _VideoPlayerImplementationState extends State<VideoPlayerImplementation> {
  late Player player;
  VideoController? controller;
  bool loaded = false;
  Uri? file;

  @override
  void initState() {
    super.initState();

    player = Player();

    widget.controller.attach(
        pause: pause,
        play: play,
        replay: replay,
        screenshot: screenshot,
        getSize: getSize,
        seekTo: seekTo,
        getLength: getLength);

    player.stream.position.listen((event) {
      widget.controller.setProgress(event);
    });

    player.stream.completed.listen(
      (completed) {
        widget.controller.setCompleted(completed);
      },
    );

    controller = VideoController(player);

    Future.microtask(() async {
      file = await widget.videoFile.resolve();
      await player.open(Playlist([Media(file.toString())]),
          play: !widget.decodeFirstFrame);
      widget.controller.setBuffering(false);

      setState(() {
        loaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loaded) {
      return Video(
        fit: BoxFit.cover,
        controller: controller!,
      );
    }
    return Container();
  }

  Future<void> pause() async {
    player.pause();
  }

  Future<void> play() async {
    player.play();
  }

  Future<Uint8List?> screenshot() async {
    return player.screenshot();
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

  Future<Size?> getSize() async {
    if (player.state.height == null || player.state.width == null) {
      return null;
    }

    return Size(
        player.state.height!.toDouble(), player.state.width!.toDouble());
  }
}
