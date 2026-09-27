import 'dart:async';
import 'dart:io' show HttpServer, InternetAddress, ContentType, Platform;

import 'package:commet/browser_runtime.dart';
import 'package:commet/cache/file_provider.dart';
import 'package:commet/client/components/video_embed/media_embed_adapter.dart';
import 'package:commet/client/components/video_embed/video_embed_info.dart';
import 'package:commet/client/components/video_embed/video_playback_source.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart' show browserRuntime;
import 'package:commet/utils/links/link_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:media_kit_video/media_kit_video.dart'
    show defaultEnterNativeFullscreen, defaultExitNativeFullscreen;

import 'official_embed_frame.dart';
import 'video_player.dart';

class VideoPlaybackDialog extends StatefulWidget {
  const VideoPlaybackDialog({
    required this.video,
    required this.autoplay,
    super.key,
  });

  final VideoEmbedInfo video;
  final bool autoplay;

  /// Whether this platform can render an [OfficialVideoEmbedSource] in the
  /// dialog. Windows and Linux play official embeds through the bundled CEF
  /// host and the [MediaEmbedAdapter] (a build without one, such as a
  /// development build, cannot); macOS, Android, and iOS keep their web
  /// view; the web build puts the embed in an iframe.
  static bool get supportsOfficialEmbeds {
    if (kIsWeb) return true;
    if (Platform.isWindows || Platform.isLinux) return _cefBundled;
    return true;
  }

  /// Looked up once: the bundle does not change while the app runs.
  static final bool _cefBundled = isBundledBrowserRuntimeAvailable();

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
                                      onOpenInBrowser: openInBrowser,
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

  bool get supportsInAppWebView => VideoPlaybackDialog.supportsOfficialEmbeds;

  /// Playback URL with the preserved autoplay rule. Single source of truth
  /// is [mediaEmbedPlaybackUri] so the CEF adapter serves the same URL.
  Uri get playbackUri =>
      mediaEmbedPlaybackUri(widget.source, autoplay: widget.autoplay);

  /// Origin the wrapper page claims to come from. YouTube's player checks
  /// that a Referer is present, so the page embedding it must have one.
  /// Single source of truth is [mediaEmbedPageOrigin].
  String get pageOrigin => mediaEmbedPageOrigin(widget.source);

  /// Loopback-hosted wrapper page. Single source of truth is
  /// [mediaEmbedWrapperHtml] so the CEF adapter serves identical markup.
  String get wrapperHtml => mediaEmbedWrapperHtml(playbackUri);

  /// Whether a navigation target stays inside the embed. Single source of
  /// truth is [mediaEmbedIsAllowedNavigation] so the CEF adapter enforces
  /// the same provider allowlist.
  bool _isAllowedNavigation(Uri target) => mediaEmbedIsAllowedNavigation(
        target,
        embedUri: widget.source.uri,
        pageOrigin: pageOrigin,
      );

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return OfficialEmbedFrame(uri: playbackUri);

    // Windows and Linux official-video playback runs through the CEF
    // MediaEmbedAdapter; every other platform keeps its web-view/external
    // path.
    if (mediaEmbedUsesCef(
      isWeb: kIsWeb,
      isWindows: Platform.isWindows,
      isLinux: Platform.isLinux,
    )) {
      return _CefOfficialVideoEmbed(
        video: widget.video,
        source: widget.source,
        autoplay: widget.autoplay,
      );
    }

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

    // The remaining InAppWebView branch serves macOS, Android, and iOS only:
    // Web, Windows and Linux return above. The legacy Windows loopback
    // workaround is gone with the old Windows web view.
    return Stack(
      fit: StackFit.expand,
      children: [
        if (error == null)
          InAppWebView(
            key: ValueKey(revision),
            initialData: InAppWebViewInitialData(
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
          _EmbedErrorView(
            onRetry: () {
              setState(() {
                error = null;
                loaded = false;
                revision += 1;
              });
            },
            onOpenInBrowser: () {
              Navigator.pop(context);
              LinkUtils.open(
                widget.video.originalUrl,
                context: context,
              );
            },
          ),
      ],
    );
  }
}

/// Shared retry/close/error chrome for official-video embeds.
///
/// Both the preserved web-view branch (macOS, Android, iOS) and the CEF
/// branch render this on load failure so retry, close, and error behavior
/// stay identical across the engine change.
class _EmbedErrorView extends StatelessWidget {
  const _EmbedErrorView({
    required this.onRetry,
    required this.onOpenInBrowser,
  });

  final VoidCallback onRetry;
  final VoidCallback onOpenInBrowser;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
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
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onOpenInBrowser,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open in Browser'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Windows and Linux official-video playback through the CEF
/// [MediaEmbedAdapter].
///
/// The loopback-hosted wrapper page (origin and Referer preserved) opens as
/// an embedded BrowserRuntime surface, the provider allowlist and navigation
/// policy travel in the [SurfaceSpec], disallowed links become explicit
/// external actions via `LinkUtils`, and closing the dialog closes the
/// surface so no profile, host, or owned-window leaks. Loading, Retry,
/// Close, and error chrome match the WebView branch. Web (an iframe), macOS,
/// Android, and iOS never reach this widget (see [mediaEmbedUsesCef]).
class _CefOfficialVideoEmbed extends StatefulWidget {
  const _CefOfficialVideoEmbed({
    required this.video,
    required this.source,
    required this.autoplay,
  });

  final VideoEmbedInfo video;
  final OfficialVideoEmbedSource source;
  final bool autoplay;

  @override
  State<_CefOfficialVideoEmbed> createState() => _CefOfficialVideoEmbedState();
}

class _CefOfficialVideoEmbedState extends State<_CefOfficialVideoEmbed> {
  HttpServer? _pageServer;
  Uri? _pageServerUri;
  MediaEmbedAdapter? _adapter;
  MediaEmbedSession? _session;
  StreamSubscription<Uri>? _externalSubscription;
  StreamSubscription<SurfaceEvent>? _eventSubscription;
  Object? _error;
  int _revision = 0;

  /// Shared desktop runtime from `main.dart`; null until the app initializes
  /// it (or in tests), in which case playback degrades to the retryable
  /// error view with an explicit external-browser action instead of
  /// crashing.
  BrowserRuntime? get _runtime => browserRuntime;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await _startPageServer();
    if (!mounted) return;
    if (_error != null) {
      setState(() {});
      return;
    }
    await _openSession();
  }

  /// Loopback server hosting the wrapper page. Serving from 127.0.0.1 gives
  /// the page a real origin so provider iframes send a Referer — the same
  /// reason the legacy Windows web-view branch needed it.
  Future<void> _startPageServer() async {
    if (_pageServerUri != null) return;
    try {
      final html = MediaEmbedLaunch(
        source: widget.source,
        originalUrl: widget.video.originalUrl,
        autoplay: widget.autoplay,
      ).wrapperHtml;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        request.response.headers.contentType = ContentType.html;
        request.response.write(html);
        request.response.close();
      });
      if (!mounted) {
        await server.close(force: true);
        return;
      }
      _pageServer = server;
      _pageServerUri = Uri.http('127.0.0.1:${server.port}', '/embed');
    } catch (e, s) {
      Log.onError(e, s, content: 'Failed to start embed page server');
      _error = e;
    }
  }

  Future<void> _openSession() async {
    final runtime = _runtime;
    final loopbackUri = _pageServerUri;
    if (runtime == null || loopbackUri == null) {
      if (mounted) {
        setState(() {
          _error ??= StateError('Embedded browser unavailable');
        });
      }
      return;
    }
    try {
      final adapter = MediaEmbedAdapter(runtime: runtime);
      final session = await adapter.openSession(
        MediaEmbedLaunch(
          source: widget.source,
          originalUrl: widget.video.originalUrl,
          autoplay: widget.autoplay,
          loopbackUri: loopbackUri,
        ),
      );
      if (!mounted) {
        await session.dispose();
        return;
      }
      _adapter = adapter;
      _session = session;
      _eventSubscription = session.events.listen(_onSurfaceEvent);
      // Disallowed links become explicit external actions; the embed stays.
      _externalSubscription = session.externalNavigations.listen((uri) {
        LinkUtils.open(uri, context: context);
      });
      setState(() {});
    } catch (e, s) {
      Log.onError(e, s, content: 'Failed to open official video surface');
      if (mounted) {
        setState(() => _error = e);
      }
    }
  }

  void _onSurfaceEvent(SurfaceEvent event) {
    if (!mounted) return;
    if (event is FailedEvent) {
      setState(() => _error ??= StateError(event.failure.message));
    } else if (event is ClosedEvent) {
      // An unexpected close (anything but dispose) surfaces retryable UI
      // instead of stranding a dead frame.
      setState(() => _error ??= StateError('Embedded browser closed'));
    }
  }

  Future<void> _retry() async {
    setState(() {
      _error = null;
      _revision += 1;
      _session = null;
    });
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await _externalSubscription?.cancel();
    _externalSubscription = null;
    await _adapter?.dispose();
    _adapter = null;
    await _startPageServer();
    if (!mounted) return;
    if (_error != null) {
      setState(() {});
      return;
    }
    await _openSession();
  }

  @override
  void dispose() {
    // State.dispose cannot await: the close command is queued on the runtime
    // before subscriptions and the loopback server are torn down, so the
    // host still destroys the browser and releases the surface.
    unawaited(_eventSubscription?.cancel());
    unawaited(_externalSubscription?.cancel());
    unawaited(_adapter?.dispose());
    unawaited(_pageServer?.close(force: true));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      return _EmbedErrorView(
        onRetry: _retry,
        onOpenInBrowser: () {
          Navigator.pop(context);
          LinkUtils.open(
            widget.video.originalUrl,
            context: context,
          );
        },
      );
    }

    final session = _session;
    if (session == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // The view reports its size, forwards pointer, wheel and keyboard input
    // in order (so the provider player keeps its click-to-play contract),
    // and shows the page's cursor.
    return EmbeddedBrowserView(
      key: ValueKey(_revision),
      surface: session.surface,
      autofocus: true,
    );
  }
}
