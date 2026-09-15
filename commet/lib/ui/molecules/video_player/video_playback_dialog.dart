import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpServer, InternetAddress, ContentType, Platform;

import 'package:commet/cache/file_provider.dart';
import 'package:commet/client/components/video_embed/video_embed_info.dart';
import 'package:commet/client/components/video_embed/video_playback_source.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/links/link_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:media_kit_video/media_kit_video.dart'
    show defaultEnterNativeFullscreen, defaultExitNativeFullscreen;

import 'video_player.dart';

class VideoPlaybackDialog extends StatefulWidget {
  const VideoPlaybackDialog({
    required this.video,
    required this.autoplay,
    super.key,
  });

  final VideoEmbedInfo video;
  final bool autoplay;

  static Future<void> show(
    BuildContext context, {
    required VideoEmbedInfo video,
    required bool autoplay,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'VIDEO_PLAYBACK',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) =>
          VideoPlaybackDialog(video: video, autoplay: autoplay),
      transitionBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(animation),
          child: child,
        ),
      ),
    );
  }

  @override
  State<VideoPlaybackDialog> createState() => _VideoPlaybackDialogState();
}

class _VideoPlaybackDialogState extends State<VideoPlaybackDialog> {
  /// Fullscreen is handled here rather than by media_kit: its built-in
  /// fullscreen route re-uses the `controls` we pass (none), which leaves no
  /// way back out. We instead grow this dialog to the whole window, and ask
  /// the OS for a fullscreen window on top of that.
  bool isFullscreen = false;
  bool nativeFullscreenActive = false;

  final FocusNode focusNode = FocusNode(debugLabel: 'VideoPlaybackDialog');

  VideoEmbedInfo get video => widget.video;

  Future<void> toggleFullscreen() async {
    final next = !isFullscreen;
    setState(() => isFullscreen = next);
    await _setNativeFullscreen(next);
  }

  Future<void> _setNativeFullscreen(bool enabled) async {
    if (nativeFullscreenActive == enabled) return;
    nativeFullscreenActive = enabled;
    try {
      if (enabled) {
        await defaultEnterNativeFullscreen();
      } else {
        await defaultExitNativeFullscreen();
      }
    } catch (e, s) {
      Log.onError(e, s, content: 'Failed to toggle native fullscreen');
    }
  }

  void close() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    // Closing the dialog while fullscreen must hand the normal window back.
    if (nativeFullscreenActive) {
      nativeFullscreenActive = false;
      defaultExitNativeFullscreen();
    }
    focusNode.dispose();
    super.dispose();
  }

  KeyEventResult onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (isFullscreen) {
        toggleFullscreen();
      } else {
        close();
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyF &&
        video.playbackSource is NativeVideoSource) {
      toggleFullscreen();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final source = video.playbackSource;
    final aspect = video.aspectRatio ?? (video.isShortForm ? 9 / 16 : 16 / 9);
    final isVertical = aspect < 0.9;
    final screenSize = MediaQuery.sizeOf(context);

    final double maxWidth = isFullscreen
        ? screenSize.width
        : isVertical
            ? 420.0
            : 1000.0;
    final double maxHeight = isFullscreen
        ? screenSize.height
        : isVertical
            ? (screenSize.height * 0.88).clamp(360.0, 800.0)
            : (screenSize.height * 0.82).clamp(300.0, 700.0);

    // The widget tree below keeps the same shape in both modes so the player
    // (and its media session) survives the switch.
    return Focus(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: onKeyEvent,
      child: Material(
        color: isFullscreen ? Colors.black : Colors.transparent,
        child: SafeArea(
          child: Stack(
            children: [
              // Barrier dismiss gesture
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isFullscreen ? null : close,
                ),
              ),
              Center(
                child: Padding(
                  padding: isFullscreen
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxWidth,
                      maxHeight: maxHeight,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: AspectRatio(
                            aspectRatio: aspect,
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(isFullscreen ? 0 : 12),
                              child: ColoredBox(
                                color: Colors.black,
                                child: switch (source) {
                                  NativeVideoSource(
                                    :final uri,
                                    :final httpHeaders,
                                    :final capabilities,
                                  ) =>
                                    VideoPlayer(
                                      WebFileProvider(uri),
                                      streamUrl: uri,
                                      httpHeaders: httpHeaders,
                                      thumbnail: video.thumbnail,
                                      fileName: video.title,
                                      decodeFirstFrame: true,
                                      autoplay: widget.autoplay,
                                      canGoFullscreen: true,
                                      onFullscreen: toggleFullscreen,
                                      isFullscreen: isFullscreen,
                                      capabilities: capabilities,
                                    ),
                                  OfficialVideoEmbedSource() =>
                                    _OfficialVideoEmbed(
                                      video: video,
                                      source: source,
                                      autoplay: widget.autoplay,
                                    ),
                                  null => _UnavailableView(
                                      video: video,
                                      onOpenInBrowser: openInBrowser,
                                    ),
                                },
                              ),
                            ),
                          ),
                        ),
                        if (!isFullscreen) ...[
                          const SizedBox(height: 8),
                          metaRow(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Close button in top-right
              Positioned(
                top: 12,
                right: 12,
                child: IconButton.filledTonal(
                  tooltip: 'Close',
                  onPressed: close,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void openInBrowser() {
    close();
    LinkUtils.open(video.originalUrl, context: context);
  }

  Widget metaRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            video.platformName,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                video.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (video.author != null)
                Text(
                  video.author!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Open link in browser',
          onPressed: openInBrowser,
          icon: const Icon(
            Icons.open_in_new_rounded,
            color: Colors.white70,
            size: 18,
          ),
        ),
      ],
    );
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView({required this.video, required this.onOpenInBrowser});

  final VideoEmbedInfo video;
  final VoidCallback onOpenInBrowser;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.videocam_off_rounded,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 12),
          const Text(
            'Video playback unavailable',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onOpenInBrowser,
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Open in Browser'),
          ),
        ],
      ),
    );
  }
}

class _OfficialVideoEmbed extends StatefulWidget {
  const _OfficialVideoEmbed({
    required this.video,
    required this.source,
    required this.autoplay,
  });

  final VideoEmbedInfo video;
  final OfficialVideoEmbedSource source;
  final bool autoplay;

  @override
  State<_OfficialVideoEmbed> createState() => _OfficialVideoEmbedState();
}

class _OfficialVideoEmbedState extends State<_OfficialVideoEmbed> {
  bool loaded = false;
  String? error;
  int revision = 0;

  /// Loopback server hosting the wrapper page on platforms where the webview
  /// cannot give an in-memory page an origin. See [_needsLoopbackServer].
  HttpServer? pageServer;
  Uri? pageServerUri;

  bool get supportsInAppWebView {
    if (kIsWeb) return false;
    // flutter_inappwebview is supported on Android, iOS, Windows, macOS.
    // On Linux desktop, flutter_inappwebview plugin is not registered.
    if (!kIsWeb && Platform.isLinux) {
      return false;
    }
    return true;
  }

  /// WebView2 (Windows) loads in-memory HTML with `NavigateToString`, which
  /// ignores `baseUrl` and gives the page an opaque origin. Frames inside it
  /// then send no Referer, and YouTube refuses to play (error 153). Serving
  /// the same page from 127.0.0.1 gives it a real origin.
  bool get _needsLoopbackServer => !kIsWeb && Platform.isWindows;

  Uri get playbackUri {
    final source = widget.source;
    if (source.provider != OfficialVideoProvider.youtube || !widget.autoplay) {
      return source.uri;
    }
    return source.uri.replace(
      queryParameters: {
        ...source.uri.queryParameters,
        'autoplay': '1',
      },
    );
  }

  /// Origin the wrapper page claims to come from. YouTube's player checks
  /// that a Referer is present, so the page embedding it must have one.
  String get pageOrigin => switch (widget.source.provider) {
        OfficialVideoProvider.youtube => 'https://www.youtube.com',
        _ => widget.source.uri.origin,
      };

  String get wrapperHtml {
    final src = const HtmlEscape(HtmlEscapeMode.attribute)
        .convert(playbackUri.toString());
    return '''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<meta name="referrer" content="strict-origin-when-cross-origin">
<style>
html, body { margin: 0; padding: 0; height: 100%; background: #000; overflow: hidden; }
iframe { position: absolute; inset: 0; width: 100%; height: 100%; border: 0; }
</style>
</head>
<body>
<iframe src="$src"
  allow="autoplay; encrypted-media; fullscreen; picture-in-picture"
  allowfullscreen
  referrerpolicy="strict-origin-when-cross-origin"></iframe>
</body>
</html>''';
  }

  @override
  void initState() {
    super.initState();
    if (supportsInAppWebView && _needsLoopbackServer) {
      _startPageServer();
    }
  }

  Future<void> _startPageServer() async {
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        request.response.headers.contentType = ContentType.html;
        request.response.write(wrapperHtml);
        request.response.close();
      });
      if (!mounted) {
        await server.close(force: true);
        return;
      }
      setState(() {
        pageServer = server;
        pageServerUri = Uri.http('127.0.0.1:${server.port}', '/embed');
      });
    } catch (e, s) {
      Log.onError(e, s, content: 'Failed to start embed page server');
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  void dispose() {
    pageServer?.close(force: true);
    super.dispose();
  }

  bool _isAllowedNavigation(Uri target) {
    final host = target.host.toLowerCase();
    if (target.scheme == 'about') return true;
    if (pageServerUri != null && host == pageServerUri!.host) return true;
    if (host == widget.source.uri.host.toLowerCase()) return true;
    if (host == Uri.parse(pageOrigin).host) return true;
    return host.endsWith('.youtube.com') ||
        host.endsWith('.youtube-nocookie.com') ||
        host.endsWith('.instagram.com');
  }

  @override
  Widget build(BuildContext context) {
    if (!supportsInAppWebView) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.open_in_browser_rounded,
                color: Colors.white,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                'Watch ${widget.video.title}',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  LinkUtils.open(widget.video.originalUrl, context: context);
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Open in Browser'),
              ),
            ],
          ),
        ),
      );
    }

    final waitingForServer = _needsLoopbackServer && pageServerUri == null;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (!waitingForServer && error == null)
          InAppWebView(
            key: ValueKey(revision),
            initialUrlRequest: _needsLoopbackServer
                ? URLRequest(url: WebUri(pageServerUri.toString()))
                : null,
            initialData: _needsLoopbackServer
                ? null
                : InAppWebViewInitialData(
                    data: wrapperHtml,
                    baseUrl: WebUri(pageOrigin),
                    mimeType: 'text/html',
                    encoding: 'utf-8',
                  ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: !widget.autoplay,
              allowsInlineMediaPlayback: true,
              iframeAllowFullscreen: true,
              supportZoom: false,
              transparentBackground: true,
              useShouldOverrideUrlLoading: true,
            ),
            onLoadStop: (_, __) {
              if (mounted) setState(() => loaded = true);
            },
            onReceivedError: (_, request, receivedError) {
              if (mounted && request.isForMainFrame != false) {
                setState(() {
                  loaded = false;
                  error = receivedError.description;
                });
              }
            },
            shouldOverrideUrlLoading: (_, navigationAction) async {
              final target = navigationAction.request.url;
              if (target == null) return NavigationActionPolicy.ALLOW;

              if (_isAllowedNavigation(target)) {
                return NavigationActionPolicy.ALLOW;
              }

              // Anything else (channel links, "watch on YouTube") goes to
              // the system browser instead of navigating the embed away.
              LinkUtils.open(target, context: context);
              return NavigationActionPolicy.CANCEL;
            },
          ),
        if (!loaded && error == null)
          const Center(child: CircularProgressIndicator()),
        if (error != null)
          ColoredBox(
            color: Colors.black,
            child: Center(
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
                    'Unable to load this video',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            error = null;
                            loaded = false;
                            revision += 1;
                          });
                          if (_needsLoopbackServer && pageServerUri == null) {
                            _startPageServer();
                          }
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          LinkUtils.open(
                            widget.video.originalUrl,
                            context: context,
                          );
                        },
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Open in Browser'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
