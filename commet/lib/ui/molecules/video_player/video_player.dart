import 'dart:async';

import 'package:commet/cache/file_provider.dart';
import 'package:commet/client/components/video_embed/video_capabilities.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/molecules/video_player/video_player_implementation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../atoms/gradient_background.dart';
import '../../atoms/icon_button.dart' as i;
import 'video_player_controller.dart';

class VideoPlayer extends StatefulWidget {
  const VideoPlayer(
    this.videoFile, {
    this.thumbnail,
    this.fileName,
    super.key,
    this.canGoFullscreen = true,
    this.onFullscreen,
    this.streamUrl,
    this.httpHeaders = const {},
    this.decodeFirstFrame = false,
    this.autoplay = false,
    this.controller,
    this.doThumbnail = true,
    this.showProgressBar = true,
    this.capabilities = VideoCapabilities.native,
    this.isFullscreen = false,
    this.onOpenInBrowser,
  });

  final FileProvider videoFile;
  final ImageProvider? thumbnail;
  final Uri? streamUrl;
  final Map<String, String> httpHeaders;
  final bool showProgressBar;
  final bool canGoFullscreen;
  final bool doThumbnail;
  final bool decodeFirstFrame;
  final bool autoplay;
  final String? fileName;
  final Function? onFullscreen;
  final VideoPlayerController? controller;
  final VideoCapabilities capabilities;

  /// Whether the host is currently presenting this player fullscreen. Only
  /// affects which fullscreen icon is shown; the host owns the transition
  /// through [onFullscreen].
  final bool isFullscreen;

  /// Offered next to Retry when playback fails.
  final VoidCallback? onOpenInBrowser;

  @override
  State<VideoPlayer> createState() => VideoPlayerState();
}

class VideoPlayerState extends State<VideoPlayer> {
  late VideoPlayerController controller;
  bool inited = false;
  bool buffering = false;
  DownloadProgress? downloadProgress;
  late bool showThumbnail;
  bool shouldShowControls = true;
  bool isCompleted = false;
  double videoProgress = 0;
  Duration position = Duration.zero;
  Duration length = Duration.zero;
  bool updateSlider = true;
  Timer? uiHideTimer;
  String? playbackError;
  int playerRevision = 0;

  late List<StreamSubscription> subscriptions;

  @override
  void initState() {
    showThumbnail = widget.doThumbnail && !widget.autoplay;

    final initialVolume = preferences.videoPlayerVolume.value;

    controller = widget.controller ??
        VideoPlayerController(
          initialSettings: VideoPlayerSettings(
            volume: initialVolume,
            lastNonZeroVolume: initialVolume > 0 ? initialVolume : 100.0,
            capabilities: widget.capabilities,
          ),
        );

    subscriptions = [
      controller.isBuffering.listen((isBuffering) {
        setState(() {
          buffering = isBuffering;
          if (!isBuffering) {
            showThumbnail = false;
          }
        });
      }),
      controller.isCompleted.listen((event) {
        setState(() {
          isCompleted = event;
          if (isCompleted) shouldShowControls = true;
        });
      }),
      controller.onDownloadProgressed.listen((event) {
        setState(() {
          downloadProgress = event;
        });
      }),
      controller.onError.listen((error) {
        setState(() {
          playbackError = error;
          buffering = false;
        });
      }),
      controller.onProgressed.listen((event) async {
        final total = await controller.getLength();
        if (!mounted) return;
        setState(() {
          position = event;
          length = total;
          if (updateSlider && total.inMilliseconds > 0) {
            videoProgress = clampDouble(
              event.inMilliseconds.toDouble() / total.inMilliseconds.toDouble(),
              0,
              1,
            );
          }
        });
      }),
    ];

    if (widget.autoplay) {
      inited = true;
    }

    super.initState();
  }

  @override
  void dispose() {
    for (final sub in subscriptions) {
      sub.cancel();
    }
    subscriptions.clear();
    uiHideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.decodeFirstFrame || inited) pickPlayer(),
        if (showThumbnail) thumbnail(),
        if (buffering && playbackError == null) bufferingWidget(),
        if (playbackError != null) errorWidget(),
        if (playbackError == null) controls(),
      ],
    );
  }

  Widget bufferingWidget() {
    double? progress;
    final download = downloadProgress;

    if (download != null && download.total > 0) {
      progress = download.downloaded.toDouble() / download.total.toDouble();
    }

    return Container(
      alignment: Alignment.center,
      color: Colors.black26,
      child: Container(
        width: 90,
        height: 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.black45,
        ),
        clipBehavior: Clip.antiAlias,
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
      ),
    );
  }

  Widget errorWidget() {
    return ColoredBox(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 36,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to play this video',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: retry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                  if (widget.onOpenInBrowser != null)
                    OutlinedButton.icon(
                      onPressed: widget.onOpenInBrowser,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Open in Browser'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget controls() {
    return GestureDetector(
      onTap: () {
        if (!shouldShowControls) {
          showControls();
        } else {
          hideControls();
        }
      },
      child: MouseRegion(
        onHover: (_) => showControls(),
        onExit: (_) {
          if (!BuildConfig.MOBILE) hideControls();
        },
        child: StreamBuilder<VideoPlayerSettings>(
          stream: controller.onSettingsChanged,
          initialData: controller.settings,
          builder: (context, snapshot) {
            final settings = snapshot.data ?? controller.settings;

            return Stack(
              fit: StackFit.expand,
              children: [
                if (widget.fileName != null) titleOverlay(),
                Align(
                  alignment: Alignment.center,
                  child: AnimatedScale(
                    scale: shouldShowControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: i.IconButton(
                        icon: isCompleted
                            ? Icons.replay_rounded
                            : (settings.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded),
                        size: 48,
                        onPressed: togglePlayback,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedSlide(
                    offset: shouldShowControls
                        ? const Offset(0, 0)
                        : const Offset(0, 1),
                    duration: const Duration(milliseconds: 150),
                    child: bottomBar(settings),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Title strip along the top edge. Kept out of the bottom bar so long
  /// titles (tweet text, file names) never fight the seek bar for space.
  Widget titleOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedSlide(
        offset: shouldShowControls ? const Offset(0, 0) : const Offset(0, -1),
        duration: const Duration(milliseconds: 150),
        child: GradientBackground(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          backgroundColor: Colors.black87,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 56, 22),
            child: Text(
              widget.fileName!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget bottomBar(VideoPlayerSettings settings) {
    final capabilities = widget.capabilities;
    final showSeekBar = widget.showProgressBar && capabilities.supportsSeeking;
    final showTime = length > Duration.zero;

    return GradientBackground(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      backgroundColor: Colors.black87,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 18, 8, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSeekBar)
              SliderTheme(
                data: compactSliderTheme(context),
                child: Slider(
                  key: const ValueKey('video-seek-slider'),
                  value: videoProgress,
                  onChangeEnd: (value) {
                    updateSlider = true;
                    seekPercent(value);
                  },
                  onChanged: (value) {
                    setState(() {
                      videoProgress = value;
                      if (length > Duration.zero) position = length * value;
                    });
                  },
                  onChangeStart: (_) {
                    updateSlider = false;
                  },
                ),
              ),
            Row(
              children: [
                i.IconButton(
                  icon: isCompleted
                      ? Icons.replay_rounded
                      : (settings.playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded),
                  size: 22,
                  onPressed: togglePlayback,
                ),
                if (showTime)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '${formatDuration(position)} / ${formatDuration(length)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                const Spacer(),
                if (capabilities.supportsVolume) volumeControl(settings),
                if (capabilities.supportsPlaybackRate ||
                    (capabilities.supportsQualitySelection &&
                        settings.qualities.length > 1) ||
                    (capabilities.supportsCaptions &&
                        settings.subtitles.isNotEmpty))
                  i.IconButton(
                    icon: Icons.settings_rounded,
                    size: 22,
                    onPressed: _showPlaybackSettings,
                  ),
                if (widget.canGoFullscreen && capabilities.supportsFullscreen)
                  i.IconButton(
                    icon: widget.isFullscreen
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    size: 24,
                    onPressed: () async {
                      if (widget.onFullscreen != null) {
                        widget.onFullscreen?.call();
                      } else if (widget.isFullscreen) {
                        await controller.exitFullscreen();
                      } else {
                        await controller.enterFullscreen();
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Mute toggle plus, on desktop, an inline slider so the level can be set
  /// without opening the settings sheet. Mobile keeps the toggle only; the
  /// slider lives in the sheet where there is room for a finger.
  Widget volumeControl(VideoPlayerSettings settings) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        i.IconButton(
          icon: settings.isMuted
              ? Icons.volume_off_rounded
              : (settings.volume < 50
                  ? Icons.volume_down_rounded
                  : Icons.volume_up_rounded),
          size: 22,
          onPressed: () {
            controller.toggleMute();
            preferences.videoPlayerVolume.set(controller.settings.volume);
          },
        ),
        if (!BuildConfig.MOBILE)
          SizedBox(
            width: 90,
            child: SliderTheme(
              data: compactSliderTheme(context),
              child: Slider(
                key: const ValueKey('video-inline-volume-slider'),
                value: settings.volume.clamp(0.0, 100.0),
                min: 0,
                max: 100,
                onChanged: (vol) {
                  controller.setVolume(vol);
                },
                onChangeEnd: (vol) {
                  preferences.videoPlayerVolume.set(vol);
                },
              ),
            ),
          ),
      ],
    );
  }

  static SliderThemeData compactSliderTheme(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SliderTheme.of(context).copyWith(
      trackHeight: 3,
      activeTrackColor: scheme.primary,
      inactiveTrackColor: Colors.white30,
      thumbColor: scheme.primary,
      overlayColor: scheme.primary.withValues(alpha: 0.2),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
      padding: EdgeInsets.zero,
    );
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    final mm = minutes.toString().padLeft(hours > 0 ? 2 : 1, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
  }

  void togglePlayback() {
    if (isCompleted) {
      replay();
    } else if (controller.settings.playing) {
      pause();
    } else {
      play();
    }
  }

  Widget thumbnail() {
    return InkWell(
      onTap: play,
      child: widget.thumbnail != null
          ? Image(
              image: widget.thumbnail!,
              fit: BoxFit.contain,
            )
          : Container(color: Colors.black),
    );
  }

  void pause() async {
    controller.pause();
  }

  void play() async {
    setState(() {
      inited = true;
      shouldShowControls = false;
    });
    controller.play();
    if (BuildConfig.MOBILE) hideControls();
  }

  void replay() async {
    setState(() {
      shouldShowControls = false;
    });
    controller.replay();
    if (BuildConfig.MOBILE) hideControls();
  }

  void showControls() {
    setState(() {
      shouldShowControls = true;
    });

    if (BuildConfig.MOBILE) {
      uiHideTimer?.cancel();
      uiHideTimer = Timer(const Duration(seconds: 3), hideControls);
    }
  }

  void hideControls() {
    setState(() {
      shouldShowControls = false;
    });
    uiHideTimer?.cancel();
  }

  void seekPercent(double percent) async {
    final length = await controller.getLength();
    controller.seekTo(length * percent);
    setState(() {
      videoProgress = percent;
    });
  }

  Widget pickPlayer() {
    return VideoPlayerImplementation(
      key: ValueKey(playerRevision),
      controller: controller,
      videoFile: widget.videoFile,
      decodeFirstFrame: widget.decodeFirstFrame,
      autoPlay: widget.autoplay || inited,
      streamUrl: widget.streamUrl,
      httpHeaders: widget.httpHeaders,
    );
  }

  void retry() {
    setState(() {
      playbackError = null;
      isCompleted = false;
      inited = true;
      playerRevision += 1;
    });
  }

  void _showPlaybackSettings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _VideoPlaybackSettingsSheet(
        controller: controller,
        capabilities: widget.capabilities,
      ),
    );
  }
}

class _VideoPlaybackSettingsSheet extends StatelessWidget {
  const _VideoPlaybackSettingsSheet({
    required this.controller,
    required this.capabilities,
  });

  static const playbackRates = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
  ];

  final VideoPlayerController controller;
  final VideoCapabilities capabilities;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<VideoPlayerSettings>(
      stream: controller.onSettingsChanged,
      initialData: controller.settings,
      builder: (context, snapshot) {
        final settings = snapshot.data ?? controller.settings;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (capabilities.supportsVolume) ...[
                  Text(
                    'Volume',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: settings.isMuted ? 'Unmute' : 'Mute',
                        onPressed: () {
                          controller.toggleMute();
                          preferences.videoPlayerVolume
                              .set(controller.settings.volume);
                        },
                        icon: Icon(
                          settings.isMuted
                              ? Icons.volume_off_rounded
                              : (settings.volume < 50
                                  ? Icons.volume_down_rounded
                                  : Icons.volume_up_rounded),
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          key: const ValueKey('video-volume-slider'),
                          value: settings.volume.clamp(0.0, 100.0),
                          min: 0,
                          max: 100,
                          onChanged: (vol) {
                            controller.setVolume(vol);
                            preferences.videoPlayerVolume.set(vol);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (capabilities.supportsPlaybackRate) ...[
                  Text(
                    'Playback speed',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final rate in playbackRates)
                        ChoiceChip(
                          label: Text('${rate.toStringAsPlaybackRate()}x'),
                          selected: settings.rate == rate,
                          onSelected: (_) => controller.setRate(rate),
                        ),
                    ],
                  ),
                ],
                if (capabilities.supportsQualitySelection &&
                    settings.qualities.length > 1) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Quality',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final quality in settings.qualities)
                        ChoiceChip(
                          label: Text(quality.label),
                          selected: settings.selectedQualityId == quality.id,
                          onSelected: (_) =>
                              controller.selectVideoTrack(quality.id),
                        ),
                    ],
                  ),
                ],
                if (capabilities.supportsCaptions &&
                    settings.subtitles.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Subtitles',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  RadioGroup<String>(
                    groupValue: settings.selectedSubtitleId,
                    onChanged: (value) {
                      if (value != null) {
                        controller.selectSubtitleTrack(value);
                      }
                    },
                    child: Column(
                      children: [
                        const RadioListTile<String>(
                          value: 'no',
                          title: Text('Off'),
                        ),
                        for (final subtitle in settings.subtitles)
                          RadioListTile<String>(
                            value: subtitle.id,
                            title: Text(subtitle.label),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

extension on double {
  String toStringAsPlaybackRate() =>
      this == roundToDouble() ? toInt().toString() : toString();
}
