import 'dart:async';
import 'dart:convert';

import 'package:commet/browser_runtime.dart';
import 'package:commet/debug/log.dart';

import 'video_playback_source.dart';

/// Profile key for official-video embeds.
///
/// YouTube/Instagram embeds carry third-party (provider) cookies, not Matrix
/// account state, so they share one persistent context instead of borrowing a
/// Matrix account record. The key is still a validated [ProfileKey] so the
/// host maps it to a generated directory exactly like account profiles.
const String mediaEmbedProfileKey = 'official-video';

/// Explicit in-CEF origins for YouTube playback.
///
/// Mirrors the WebView suffix allowlist (`.youtube.com`,
/// `.youtube-nocookie.com`) as declared origins: the embed host, the
/// privacy-enhanced host, the page origin YouTube checks the Referer against,
/// and their common mobile/apex variants. Anything else becomes an explicit
/// external action or a cancellation through [SurfacePolicy].
const List<String> mediaEmbedYouTubeOrigins = [
  'https://m.youtube.com',
  'https://www.youtube-nocookie.com',
  'https://www.youtube.com',
  'https://youtube.com',
];

/// Explicit in-CEF origins for Instagram playback.
///
/// Mirrors the WebView `.instagram.com` suffix allowlist as declared origins.
const List<String> mediaEmbedInstagramOrigins = [
  'https://instagram.com',
  'https://m.instagram.com',
  'https://www.instagram.com',
];

/// Whether official-video playback routes through the CEF
/// [MediaEmbedAdapter] instead of a platform web view.
///
/// Pure predicate over platform flags so it is unit-testable: the desktop
/// platforms with a bundled CEF host (Windows and Linux) use CEF; web keeps
/// its external path and macOS/Android/iOS keep their web views. There is
/// no standalone official-video presentation.
bool mediaEmbedUsesCef({
  required bool isWeb,
  required bool isWindows,
  bool isLinux = false,
}) =>
    !isWeb && (isWindows || isLinux);

/// Playback URL for an official embed, preserving the existing autoplay rule:
/// YouTube forces `autoplay=1` when the dialog requested autoplay, every
/// other provider plays its resolved URL unchanged.
Uri mediaEmbedPlaybackUri(
  OfficialVideoEmbedSource source, {
  required bool autoplay,
}) {
  if (source.provider != OfficialVideoProvider.youtube || !autoplay) {
    return source.uri;
  }
  return source.uri.replace(
    queryParameters: {
      ...source.uri.queryParameters,
      'autoplay': '1',
    },
  );
}

/// Origin the wrapper page claims to come from.
///
/// YouTube's player checks that a Referer is present, so YouTube embeds
/// declare `https://www.youtube.com` exactly like the WebView wrapper did.
/// Every other provider uses its embed origin.
String mediaEmbedPageOrigin(OfficialVideoEmbedSource source) {
  if (source.provider == OfficialVideoProvider.youtube) {
    return 'https://www.youtube.com';
  }
  return source.uri.origin;
}

/// Wrapper page served from the loopback server.
///
/// Identical contract to the WebView wrapper: the provider iframe keeps
/// `allow="autoplay; encrypted-media; fullscreen; picture-in-picture"`,
/// `allowfullscreen`, and `referrerpolicy="strict-origin-when-cross-origin"`
/// with a matching document referrer policy, so autoplay, fullscreen,
/// picture-in-picture, and Referer behavior survive the engine change.
String mediaEmbedWrapperHtml(Uri playbackUri) {
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

/// Whether a navigation target stays inside the embed.
///
/// Preserves the WebView `_isAllowedNavigation` rule: the loopback wrapper,
/// the embed host, the declared page origin, `about:` bootstraps, and the
/// YouTube/YouTube-nocookie/Instagram suffix families stay in-process.
/// Anything else (channel links, "watch on YouTube") is a disallowed link
/// the caller turns into an explicit external action or a cancellation.
bool mediaEmbedIsAllowedNavigation(
  Uri target, {
  required Uri embedUri,
  required String pageOrigin,
  Uri? loopbackUri,
}) {
  final host = target.host.toLowerCase();
  if (target.scheme == 'about') return true;
  if (loopbackUri != null && host == loopbackUri.host.toLowerCase()) {
    return true;
  }
  if (host == embedUri.host.toLowerCase()) return true;
  if (host == Uri.parse(pageOrigin).host.toLowerCase()) return true;
  return host.endsWith('.youtube.com') ||
      host.endsWith('.youtube-nocookie.com') ||
      host.endsWith('.instagram.com');
}

/// Immutable caller data used to open one official-video surface.
///
/// This is deliberately independent of Flutter widgets so URL/policy
/// construction is testable at the BrowserRuntime seam. Only
/// [OfficialVideoEmbedSource] enters CEF: native direct-stream sources keep
/// using the media-kit player and are
/// never adapted. Presentation is always embedded; there is no standalone
/// official-video surface, so requesting one is an error rather than a
/// fallback.
class MediaEmbedLaunch {
  final OfficialVideoEmbedSource source;
  final Uri originalUrl;
  final bool autoplay;
  final String profileKey;
  final PresentationMode presentation;
  final PrivacyMode privacy;

  /// Loopback URI serving [wrapperHtml] (e.g. `http://127.0.0.1:PORT/embed`).
  ///
  /// Windows always provides this: serving the wrapper from 127.0.0.1 gives
  /// the page a real origin so provider iframes send a Referer. Without it
  /// the embed URL itself is the initial navigation (tests, non-CEF paths).
  final Uri? loopbackUri;

  MediaEmbedLaunch({
    required this.source,
    required this.originalUrl,
    this.autoplay = false,
    this.profileKey = mediaEmbedProfileKey,
    this.presentation = PresentationMode.embedded,
    this.privacy = PrivacyMode.persistent,
    this.loopbackUri,
  }) {
    if (presentation != PresentationMode.embedded) {
      throw ArgumentError.value(
        presentation,
        'presentation',
        'MediaEmbedLaunch supports only PresentationMode.embedded: '
            'no standalone official-video surface exists.',
      );
    }
    // Validate the opaque key at the adapter boundary, before it reaches the
    // host or any generated profile path.
    ProfileKey(profileKey);
  }

  /// Playback URL with the preserved autoplay rule applied.
  Uri get playbackUri => mediaEmbedPlaybackUri(source, autoplay: autoplay);

  /// Origin the wrapper claims to come from (Referer behavior).
  String get pageOrigin => mediaEmbedPageOrigin(source);

  /// Loopback-hosted wrapper page for this launch.
  String get wrapperHtml => mediaEmbedWrapperHtml(playbackUri);

  /// Initial navigation: the loopback wrapper when one is served, otherwise
  /// the provider embed URL.
  Uri get initialUrl => loopbackUri ?? playbackUri;

  /// Declared in-process origins: the embed host, the page origin, and the
  /// shared YouTube/YouTube-nocookie/Instagram provider allowlist. The list
  /// is intentionally provider-independent, exactly like the WebView suffix
  /// rule it replaces. The host externalizes anything else when the caller
  /// policy permits it, otherwise it cancels.
  List<String> get allowedOrigins {
    final origins = <String>{
      source.uri.origin,
      pageOrigin,
      ...mediaEmbedYouTubeOrigins,
      ...mediaEmbedInstagramOrigins,
    };
    return origins.toList()..sort();
  }

  /// Declared loopback wrapper origin. Empty when no loopback server backs
  /// this launch.
  List<String> get allowedLoopbackOrigins {
    final loopback = loopbackUri;
    if (loopback == null) return const [];
    return [loopback.origin];
  }

  /// BrowserRuntime declaration for this surface. The host receives only
  /// typed policy/profile values; provider specifics stay in this adapter.
  SurfaceSpec toSurfaceSpec() {
    return SurfaceSpec(
      profileKey: ProfileKey(profileKey),
      presentation: presentation,
      privacy: privacy,
      initialNavigation: NavigationRequest(url: initialUrl.toString()),
      policy: SurfacePolicy(
        allowedOrigins: allowedOrigins,
        allowedLoopbackOrigins: allowedLoopbackOrigins,
        allowExternalNavigation: true,
        capabilities: const {},
      ),
    );
  }

  /// Adapter-level allowlist check, mirroring the host policy for tests and
  /// for non-CEF callers that share this contract.
  bool isAllowedNavigation(Uri target) => mediaEmbedIsAllowedNavigation(
        target,
        embedUri: source.uri,
        pageOrigin: pageOrigin,
        loopbackUri: loopbackUri,
      );
}

/// One opened BrowserRuntime surface rendering an official-video wrapper.
///
/// Owns an [EmbeddedBrowserSurface] in embedded presentation, exposes its
/// frame/event streams for Flutter composition, and turns normalized
/// `external` navigation outcomes into explicit external-navigation events
/// for the caller (the dialog opens them via `LinkUtils`). `blocked` and
/// `cancelled` outcomes are cancellations: the embed stays put and no
/// callback fires. Autoplay, fullscreen, and picture-in-picture travel in
/// the wrapper page itself; retry is a fresh session via [MediaEmbedAdapter].
class MediaEmbedSession {
  MediaEmbedSession({required this.runtime, required this.launch})
      : surface = EmbeddedBrowserSurface(
          runtime: runtime,
          spec: launch.toSurfaceSpec(),
        );

  final BrowserRuntime runtime;
  final MediaEmbedLaunch launch;

  /// Embedded OSR surface presenting the wrapper (texture when bound,
  /// frame metadata otherwise).
  final EmbeddedBrowserSurface surface;

  final StreamController<Uri> _external = StreamController<Uri>.broadcast();
  final StreamController<void> _onClosed = StreamController<void>.broadcast();
  final Completer<void> _closed = Completer<void>();
  final Completer<void> _ready = Completer<void>();
  Object? _readyFailure;
  StreamSubscription<SurfaceEvent>? _subscription;
  Future<void>? _disposeFuture;
  bool _closedState = false;

  /// Disallowed-link navigations the caller must externalize explicitly.
  Stream<Uri> get externalNavigations => _external.stream;

  /// Raw surface events (ready/frame/navigation/failed/closed) for
  /// loading, error, and lifecycle UI.
  Stream<SurfaceEvent> get events => surface.surfaceEvents;

  Stream<void> get onClosed => _onClosed.stream;

  bool get isReady => _ready.isCompleted && _readyFailure == null;

  bool get isClosed => _closedState;

  /// Accessible reconnecting state delegated to the owned embedded surface.
  /// Host loss never takes down the app; retry is a fresh session via
  /// [MediaEmbedAdapter] and [dispose] still drains without leaking.
  bool get isReconnecting => surface.isReconnecting;

  /// Records a host-loss observation on the owned surface.
  void noteHostLost() => surface.noteHostLost();

  /// Clears the reconnecting state after the host restores the surface.
  void noteRestored() => surface.noteRestored();

  SurfaceId? get surfaceId => surface.surfaceId;

  Future<void> open() async {
    if (_disposeFuture != null) {
      throw StateError('Media embed session was disposed');
    }
    _subscription ??= surface.surfaceEvents.listen(_handleEvent);
    try {
      await surface.open();
    } catch (_) {
      await _subscription?.cancel();
      _subscription = null;
      rethrow;
    }
    await _ready.future;
    final failure = _readyFailure;
    if (failure != null) throw failure;
  }

  void _handleEvent(SurfaceEvent event) {
    if (event is ReadyEvent) {
      if (!_ready.isCompleted) _ready.complete();
      return;
    }
    if (event is FailedEvent) {
      if (!_ready.isCompleted) {
        _readyFailure = StateError(event.failure.message);
        _ready.complete();
      }
      _finishClosed();
      return;
    }
    if (event is ClosedEvent) {
      if (!_ready.isCompleted) {
        _readyFailure = StateError('Media embed surface closed before ready');
        _ready.complete();
      }
      _finishClosed();
      return;
    }
    if (event is NavigationEvent &&
        event.navigation.outcome == NavigationOutcome.external) {
      final uri = Uri.tryParse(event.navigation.url);
      if (uri != null && !_external.isClosed) _external.add(uri);
    }
    if (event is PopupRequestEvent) {
      // "Watch on YouTube", channel links and the like open a new window.
      // A click hands them to the browser (the host answers with an external
      // navigation); anything the page opens on its own is refused.
      unawaited(
        surface
            .resolvePopup(
              event.requestId,
              event.userGesture ? PopupAction.openExternal : PopupAction.deny,
            )
            .catchError((Object _) {}),
      );
    }
    // Allowed navigations stay in-process; blocked/cancelled outcomes are
    // cancellations and deliberately produce no callback.
  }

  void _finishClosed() {
    if (_closedState) return;
    _closedState = true;
    if (!_ready.isCompleted) {
      _readyFailure ??= StateError('Media embed surface closed before ready');
      _ready.complete();
    }
    if (!_closed.isCompleted) _closed.complete();
    if (!_onClosed.isClosed) {
      _onClosed.add(null);
      _onClosed.close();
    }
  }

  Future<void> dispose() {
    final existing = _disposeFuture;
    if (existing != null) return existing;
    final future = _disposeInternal();
    _disposeFuture = future;
    return future;
  }

  Future<void> _disposeInternal() async {
    // Closing sends the typed BrowserRuntime close so the host destroys the
    // browser, releases the profile reference, and frees the owned surface:
    // no profile, host, or owned-window leak survives playback.
    if (!_closedState) {
      if (surface.surfaceId == null) {
        _finishClosed();
      } else {
        try {
          await surface.close();
          await _closed.future.timeout(
            const Duration(seconds: 5),
            onTimeout: _finishClosed,
          );
        } on Object catch (error, stack) {
          Log.onError(error, stack, content: 'Closing media embed surface');
          _finishClosed();
        }
      }
    }
    await _subscription?.cancel();
    _subscription = null;
    await surface.dispose();
    if (!_external.isClosed) await _external.close();
    if (!_onClosed.isClosed) await _onClosed.close();
  }
}

/// Adapter that owns the one active official-video session for a runtime.
///
/// Opening a new session is serialized with other opens and deterministically
/// disposes the previous surface first, so at most one embed surface is live
/// per adapter and a closed dialog never leaves a surface behind.
class MediaEmbedAdapter {
  final BrowserRuntime runtime;
  MediaEmbedSession? _activeSession;
  Future<void> _openTail = Future<void>.value();

  MediaEmbedAdapter({required this.runtime});

  MediaEmbedSession? get activeSession => _activeSession;

  Future<MediaEmbedSession> openSession(MediaEmbedLaunch launch) {
    final result = _openTail.then((_) => _openSession(launch));
    // Keep the queue usable after a failed open while returning the original
    // error to that caller.
    _openTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  Future<MediaEmbedSession> _openSession(MediaEmbedLaunch launch) async {
    final previous = _activeSession;
    if (previous != null) await previous.dispose();
    _activeSession = null;

    final session = MediaEmbedSession(runtime: runtime, launch: launch);
    try {
      await session.open();
    } catch (_) {
      await session.dispose();
      rethrow;
    }
    _activeSession = session;
    session.onClosed.listen((_) {
      if (identical(_activeSession, session)) _activeSession = null;
    });
    return session;
  }

  Future<void> dispose() async {
    await _openTail;
    final session = _activeSession;
    if (session != null) await session.dispose();
    _activeSession = null;
  }
}
