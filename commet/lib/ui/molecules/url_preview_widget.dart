import 'dart:math';

import 'package:commet/client/components/url_preview/url_preview_component.dart';
import 'package:commet/client/components/video_embed/composite_video_provider.dart';
import 'package:commet/client/components/video_embed/video_embed_info.dart';
import 'package:commet/client/components/video_embed/video_playback_source.dart';
import 'package:commet/ui/atoms/lightbox.dart';
import 'package:commet/ui/atoms/message_attachment.dart';
import 'package:commet/ui/atoms/shimmer_loading.dart';
import 'package:commet/ui/molecules/video_player/video_playback_dialog.dart';
import 'package:commet/utils/links/link_utils.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

typedef VideoPreviewOpener = Future<void> Function(
  BuildContext context,
  VideoEmbedInfo video,
  bool autoplay,
);

class UrlPreviewWidget extends StatefulWidget {
  const UrlPreviewWidget(
    this.data, {
    super.key,
    this.onOpenLink,
    this.onOpenVideo,
    this.provider,
    this.supportsOfficialEmbeds,
  });

  final UrlPreviewData? data;
  final void Function()? onOpenLink;
  final VideoPreviewOpener? onOpenVideo;
  final CompositeVideoProvider? provider;

  /// Overrides [VideoPlaybackDialog.supportsOfficialEmbeds], for tests.
  final bool? supportsOfficialEmbeds;

  @override
  State<UrlPreviewWidget> createState() => _UrlPreviewWidgetState();
}

class _UrlPreviewWidgetState extends State<UrlPreviewWidget> {
  double titleWidth = 0;
  double bodyWidth1 = 0;
  double bodyWidth2 = 0;

  bool isLoadingPlayback = false;

  @override
  void initState() {
    final rng = Random();
    titleWidth = (rng.nextDouble() * 50) + 50;
    bodyWidth1 = (rng.nextDouble() * 200) + 100;
    bodyWidth2 = (rng.nextDouble() * 200) + 100;

    super.initState();
  }

  @override
  void didChangeDependencies() {
    setState(() {});
    super.didChangeDependencies();
  }

  CompositeVideoProvider get provider =>
      widget.provider ?? CompositeVideoProvider.instance;

  bool get supportsOfficialEmbeds =>
      widget.supportsOfficialEmbeds ??
      VideoPlaybackDialog.supportsOfficialEmbeds;

  bool get isVideo {
    final uri = widget.data?.uri;
    return widget.data?.type == UrlDestinationType.video ||
        widget.data?.videoEmbedInfo != null ||
        (uri != null && provider.canHandle(uri));
  }

  bool get isShortForm => widget.data?.videoEmbedInfo?.isShortForm ?? false;

  Future<void> _openVideo({required bool autoplay}) async {
    setState(() {
      isLoadingPlayback = true;
    });

    try {
      final uri = widget.data?.uri;
      if (uri != null) {
        final resolved = await _resolvePlayback(uri);
        // Nothing here can play it: either no provider knows the link (an
        // og:video that is an HTML player page), or there is no web view to
        // host the provider's player (issue #19). Hand it to the browser.
        if (resolved == null ||
            (resolved.playbackSource is OfficialVideoEmbedSource &&
                !supportsOfficialEmbeds)) {
          if (mounted) {
            setState(() => isLoadingPlayback = false);
            _openLink();
          }
          return;
        }
        if (mounted) {
          setState(() => isLoadingPlayback = false);
          final opener = widget.onOpenVideo ??
              (context, video, auto) => VideoPlaybackDialog.show(
                    context,
                    video: video,
                    autoplay: auto,
                  );
          await opener(context, resolved, autoplay);
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => isLoadingPlayback = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Video unavailable. Please try again.'),
        ),
      );
    }
  }

  Future<VideoEmbedInfo?> _resolvePlayback(Uri uri) async {
    final current = widget.data?.videoEmbedInfo;
    if (current?.playbackSource != null) return current;

    final streamUrl = widget.data?.video?.streamUrl;
    if (streamUrl != null) {
      return (current ??
              VideoEmbedInfo(
                originalUrl: uri,
                title: widget.data?.title ?? 'Video',
                platformName: widget.data?.siteName ?? 'Video',
                aspectRatio: widget.data?.video?.aspectRatio,
              ))
          .copyWith(playbackSource: NativeVideoSource(streamUrl));
    }

    if (!provider.canHandle(uri)) return null;
    return await provider.resolve(uri, fetchPlayback: true);
  }

  void _openLink() {
    if (widget.onOpenLink != null) {
      widget.onOpenLink?.call();
    } else if (widget.data?.uri != null) {
      LinkUtils.open(widget.data!.uri, context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double maxWidth = isVideo ? (isShortForm ? 280 : 420) : 300;
    final double maxHeight = isVideo ? (isShortForm ? 480 : 360) : 240;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Tile.surfaceContainer(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('url-preview-card'),
            onTap: widget.data == null || (isVideo && isLoadingPlayback)
                ? null
                : isVideo
                    ? () => _openVideo(autoplay: false)
                    : _openLink,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxWidth,
                      maxHeight: maxHeight,
                    ),
                    child: widget.data == null
                        ? buildLoadingDisplay()
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.topLeft,
                                child: body(context),
                              ),
                              if (hasBody)
                                const SizedBox(
                                  width: 10,
                                  height: 10,
                                ),
                              if (isVideo)
                                Flexible(child: _buildVideoThumbnail())
                              else if (widget.data!.image != null &&
                                  widget.data?.video == null)
                                Flexible(child: image())
                              else if (widget.data!.video != null)
                                MessageAttachment(
                                  previewMedia: true,
                                  widget.data!.video!,
                                  constrainSize: false,
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail() {
    final aspect = widget.data?.videoEmbedInfo?.aspectRatio ??
        (isShortForm ? (9.0 / 16.0) : (16.0 / 9.0));
    final platformName =
        widget.data?.videoEmbedInfo?.platformName ?? widget.data?.siteName;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Material(
        color: Colors.black26,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.data?.image != null)
              AspectRatio(
                aspectRatio: aspect,
                child: Image(
                  image: widget.data!.image!,
                  filterQuality: FilterQuality.medium,
                  fit: BoxFit.cover,
                ),
              )
            else
              AspectRatio(
                aspectRatio: aspect,
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
            ),
            if (isLoadingPlayback)
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            else
              InkWell(
                key: const ValueKey('url-preview-play'),
                onTap: () => _openVideo(autoplay: true),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            if (platformName != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  key: const ValueKey('url-preview-badge'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isShortForm)
                        const Padding(
                          padding: EdgeInsets.only(right: 3.0),
                          child: Icon(
                            Icons.bolt,
                            size: 13,
                            color: Colors.redAccent,
                          ),
                        ),
                      Text(
                        platformName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.data?.videoEmbedInfo?.duration != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(widget.data!.videoEmbedInfo!.duration!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final remMinutes = minutes % 60;
      return '$hours:${remMinutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget buildLoadingDisplay() {
    final color = Theme.of(context).colorScheme.surfaceContainerLowest;
    return Shimmer(
      child: ShimmerLoading(
        isLoading: true,
        child: SizedBox(
          height: 300,
          child: Row(
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: titleWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: bodyWidth1,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 10,
                      width: bodyWidth2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 180,
                          maxWidth: 300,
                        ),
                        child: Container(color: color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget image() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: widget.data?.type != UrlDestinationType.video
            ? () {
                Lightbox.show(context, image: widget.data!.image);
              }
            : null,
        child: Image(
          image: widget.data!.image!,
          filterQuality: FilterQuality.medium,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  bool get hasBody =>
      widget.data?.siteName != null ||
      widget.data?.title != null ||
      widget.data?.description != null;

  Widget body(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.data!.siteName != null)
          tiamat.Text.labelLow(
            widget.data!.siteName!,
            maxLines: 1,
            overflow: TextOverflow.fade,
          ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.data!.title != null)
              tiamat.Text.labelEmphasised(
                widget.data!.title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (widget.data!.description != null)
              tiamat.Text.tiny(
                widget.data!.description!,
                maxLines: 2,
                color: Theme.of(context).colorScheme.secondary,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            // Explicit External Link affordance
            InkWell(
              key: const ValueKey('url-preview-external-link'),
              onTap: _openLink,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: tiamat.Text.tiny(
                        widget.data!.uri.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
