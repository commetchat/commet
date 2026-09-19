import 'dart:async';
import 'dart:typed_data';

import 'package:commet/cache/file_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'video_player_controller.dart';

class VideoPlayerImplementation extends StatefulWidget {
  const VideoPlayerImplementation({
    required this.controller,
    required this.videoFile,
    this.decodeFirstFrame = false,
    this.autoPlay = false,
    this.streamUrl,
    this.httpHeaders = const {},
    this.width = 640,
    this.height = 340,
    super.key,
  });

  final FileProvider videoFile;
  final Uri? streamUrl;
  final int width;
  final int height;
  final bool decodeFirstFrame;
  final bool autoPlay;
  final Map<String, String> httpHeaders;
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
  final GlobalKey<VideoState> videoKey = GlobalKey<VideoState>();
  final List<StreamSubscription> _subscriptions = [];

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
      getLength: getLength,
      setVolume: player.setVolume,
      setRate: player.setRate,
      selectVideoTrack: selectVideoTrack,
      selectSubtitleTrack: selectSubtitleTrack,
      enterFullscreen: enterFullscreen,
      exitFullscreen: exitFullscreen,
    );

    _subscriptions.addAll([
      player.stream.position.listen((event) {
        widget.controller.setProgress(event);
      }),
      player.stream.playing.listen((playing) {
        widget.controller.updateSettings(playing: playing);
      }),
      player.stream.error.listen(widget.controller.setError),
      player.stream.completed.listen((completed) {
        widget.controller.setCompleted(completed);
      }),
      player.stream.buffering.listen(widget.controller.setBuffering),
      player.stream.volume.listen((volume) {
        widget.controller.updateSettings(volume: volume);
      }),
      player.stream.rate.listen((rate) {
        widget.controller.updateSettings(rate: rate);
      }),
      player.stream.tracks.listen((_) => _updateTrackSettings()),
      player.stream.track.listen((_) => _updateTrackSettings()),
    ]);

    controller = VideoController(player);

    Future.microtask(_openMedia);
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loaded) {
      return Video(
        key: videoKey,
        fit: BoxFit.contain,
        controller: controller!,
        controls: null,
      );
    }
    return Container();
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> play() async {
    await player.play();
  }

  Future<Uint8List?> screenshot() async {
    return player.screenshot();
  }

  Future<void> replay() async {
    await player.seek(Duration.zero);
    await player.play();
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
      player.state.width!.toDouble(),
      player.state.height!.toDouble(),
    );
  }

  Future<void> enterFullscreen() async {
    await videoKey.currentState?.enterFullscreen();
  }

  Future<void> exitFullscreen() async {
    await videoKey.currentState?.exitFullscreen();
  }

  Future<void> selectVideoTrack(String id) async {
    final track =
        player.state.tracks.video.where((item) => item.id == id).firstOrNull;
    if (track != null) {
      await player.setVideoTrack(track);
    }
  }

  Future<void> selectSubtitleTrack(String id) async {
    if (id == 'no') {
      await player.setSubtitleTrack(SubtitleTrack.no());
      return;
    }
    final track =
        player.state.tracks.subtitle.where((item) => item.id == id).firstOrNull;
    if (track != null) {
      await player.setSubtitleTrack(track);
    }
  }

  void _updateTrackSettings() {
    final qualities = player.state.tracks.video
        .where((track) => track.id != 'no')
        .map(
          (track) => VideoQualityOption(
            id: track.id,
            label: track.id == 'auto'
                ? 'Auto'
                : track.title ??
                    (track.h == null ? 'Track ${track.id}' : '${track.h}p'),
          ),
        )
        .toList();

    final subtitles = player.state.tracks.subtitle
        .where((track) => track.id != 'no')
        .map(
          (track) => VideoSubtitleOption(
            id: track.id,
            label: track.id == 'auto'
                ? 'Auto'
                : track.title ?? track.language ?? 'Subtitle ${track.id}',
            language: track.language,
          ),
        )
        .toList();

    widget.controller.updateSettings(
      qualities: qualities,
      subtitles: subtitles,
      selectedQualityId: player.state.track.video.id,
      selectedSubtitleId: player.state.track.subtitle.id,
    );
  }

  Future<void> _openMedia() async {
    StreamSubscription<DownloadProgress>? downloadSubscription;
    widget.controller.setBuffering(true);
    try {
      final Uri? mediaUri;
      if (widget.streamUrl != null) {
        mediaUri = widget.streamUrl;
      } else {
        downloadSubscription =
            widget.videoFile.onProgressChanged?.listen((data) {
          widget.controller.setBufferingProgress(data);
        });
        mediaUri = await widget.videoFile.resolve();
        file = mediaUri;
      }

      if (mediaUri == null) {
        widget.controller.setError('Could not resolve video file');
        return;
      }

      final shouldPlay =
          widget.autoPlay || (!widget.decodeFirstFrame && !widget.autoPlay);

      // A YouTube page (Linux, see VideoPlaybackDialog.canPlayYouTubeNatively)
      // is resolved by mpv through yt-dlp, which picks the best stream there
      // is: 4K and often AV1, more than many machines decode smoothly. 1080p
      // is plenty here. Only pages go through yt-dlp; direct media ignores it.
      final platform = player.platform;
      if (platform is NativePlayer) {
        await platform.setProperty('ytdl-format',
            'bestvideo[height<=?1080][vcodec!^=av01]+bestaudio/best[height<=?1080]/best');
      }

      await player.open(
        Playlist([
          Media(mediaUri.toString(), httpHeaders: widget.httpHeaders),
        ]),
        play: shouldPlay,
      );
      _updateTrackSettings();
      if (mounted) setState(() => loaded = true);
    } catch (error) {
      widget.controller.setError(error.toString());
    } finally {
      await downloadSubscription?.cancel();
      widget.controller.setBuffering(false);
    }
  }
}
