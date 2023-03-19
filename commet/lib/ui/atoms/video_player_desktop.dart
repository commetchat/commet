import 'package:commet/ui/atoms/video_player.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

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
  late Player player;
  MediaType mediaType = MediaType.network;
  CurrentState current = CurrentState();
  PositionState position = PositionState();
  PlaybackState playback = PlaybackState();
  GeneralState general = GeneralState();
  late Media media;
  static int id = 0;

  @override
  void initState() {
    player = Player(id: id++, videoDimensions: VideoDimensions(widget.width, widget.height));
    media = Media.network(widget.videoUrl);
    widget.controller.onPlay = play;
    widget.controller.onPause = pause;
    player.open(media, autoStart: true);
    super.initState();
  }

  void play() {
    player.play();
  }

  void pause() {
    player.pause();
  }

  @override
  Widget build(BuildContext context) {
    return Video(
      player: player,
      showControls: false,
    );
  }
}
