import 'dart:io';

import 'package:commet/cache/cache_file_provider.dart';
import 'package:commet/cache/file_provider.dart';
import 'package:commet/ui/atoms/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:video_player/video_player.dart' as video_player;

class VideoPlayerMobile extends StatefulWidget {
  const VideoPlayerMobile({required this.videoFile, required this.controller, super.key});
  final FileProvider videoFile;
  final VideoPlayerController controller;

  @override
  State<VideoPlayerMobile> createState() => _VideoPlayerMobileState();
}

class _VideoPlayerMobileState extends State<VideoPlayerMobile> {
  late video_player.VideoPlayerController _controller;
  bool loaded = false;

  @override
  void initState() {
    super.initState();

    widget.controller.onPause = pause;
    widget.controller.onPlay = play;

    loadVideo();
  }

  void loadVideo() async {
    _controller = video_player.VideoPlayerController.file(File.fromUri(await widget.videoFile.resolve()))
      ..initialize().then((value) {
        setState(() {
          loaded = true;
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized && loaded ? video_player.VideoPlayer(_controller) : Placeholder();
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
