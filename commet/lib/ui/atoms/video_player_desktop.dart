import 'package:commet/ui/atoms/video_player.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class VideoPlayerDesktop extends StatefulWidget {
  const VideoPlayerDesktop({required this.controller, required this.videoUrl, super.key});
  final String videoUrl;
  final VideoPlayerController controller;
  @override
  State<VideoPlayerDesktop> createState() => _VideoPlayerDesktopState();
}

class _VideoPlayerDesktopState extends State<VideoPlayerDesktop> {
  Player player = Player(id: 0, videoDimensions: const VideoDimensions(640, 340));
  MediaType mediaType = MediaType.network;
  CurrentState current = CurrentState();
  PositionState position = PositionState();
  PlaybackState playback = PlaybackState();
  GeneralState general = GeneralState();
  VideoDimensions videoDimensions = VideoDimensions(0, 0);
  late Media media;

  @override
  void initState() {
    media = Media.network(widget.videoUrl);
    widget.controller.onPlay = play;
    widget.controller.onPause = pause;
    player.open(media, autoStart: false);
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
