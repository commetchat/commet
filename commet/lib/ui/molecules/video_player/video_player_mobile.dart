import 'dart:io';

import 'package:commet/cache/file_provider.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart' as video_player;

import 'video_player_controller.dart';

class VideoPlayerMobile extends StatefulWidget {
  const VideoPlayerMobile(
      {required this.videoFile, required this.controller, super.key});
  final FileProvider videoFile;
  final VideoPlayerController controller;

  @override
  State<VideoPlayerMobile> createState() => _VideoPlayerMobileState();
}

class _VideoPlayerMobileState extends State<VideoPlayerMobile> {
  video_player.VideoPlayerController? _controller;
  bool loaded = false;
  bool finished = false;

  @override
  void initState() {
    super.initState();

    widget.controller.attach(
        pause: pause,
        play: play,
        replay: replay,
        seekTo: seekTo,
        getLength: getLength);
    loadVideo();
  }

  @override
  void dispose() {
    _controller?.removeListener(onUpdate);
    super.dispose();
  }

  void loadVideo() async {
    _controller = video_player.VideoPlayerController.file(
        File.fromUri(await widget.videoFile.resolve()))
      ..initialize().then((value) {
        widget.controller.setBuffering(false);
        _controller!.play();

        setState(() {
          loaded = true;
        });

        _controller!.addListener(onUpdate);
      });
  }

  Future<void> onUpdate() async {
    var pos = await _controller!.position;

    if (pos == _controller!.value.duration) {
      if (!finished) {
        finished = true;
        widget.controller.setCompleted(true);
        _controller!.removeListener(onUpdate);
      }
    } else {
      if (finished) {
        finished = false;
        widget.controller.setCompleted(false);
      }
    }

    widget.controller.setProgress(pos!);
  }

  @override
  Widget build(BuildContext context) {
    return _controller != null && _controller!.value.isInitialized && loaded
        ? video_player.VideoPlayer(_controller!)
        : const Placeholder();
  }

  Future<void> pause() async {
    _controller?.pause();
  }

  Future<void> play() async {
    _controller?.play();
    _controller!.addListener(onUpdate);
  }

  Future<void> replay() async {
    _controller?.seekTo(Duration.zero);
    _controller!.addListener(onUpdate);

    widget.controller.setCompleted(false);
    play();
  }

  Future<void> seekTo(Duration duration) async {
    await _controller?.seekTo(duration);
  }

  Future<Duration> getLength() async {
    if (_controller == null) return Duration.zero;
    return _controller!.value.duration;
  }

  bool isLoaded() {
    return loaded;
  }
}
