import 'package:commet/ui/atoms/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:video_player/video_player.dart' as video_player;

class VideoPlayerMobile extends StatefulWidget {
  const VideoPlayerMobile({required this.videoUrl, required this.controller, super.key});
  final String videoUrl;
  final VideoPlayerController controller;

  @override
  State<VideoPlayerMobile> createState() => _VideoPlayerMobileState();
}

class _VideoPlayerMobileState extends State<VideoPlayerMobile> {
  late video_player.VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = video_player.VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });

    widget.controller.onPause = pause;
    widget.controller.onPlay = play;
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized ? video_player.VideoPlayer(_controller) : Placeholder();
  }

  @override
  void pause() {
    _controller.pause();
  }

  @override
  void play() {
    _controller.play();
  }
}
