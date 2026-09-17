import 'package:commet/client/components/url_preview/url_preview_component.dart';
import 'package:commet/client/components/video_embed/composite_video_provider.dart';
import 'package:commet/client/components/video_embed/video_capabilities.dart';
import 'package:commet/client/components/video_embed/video_embed_info.dart';
import 'package:commet/client/components/video_embed/video_playback_source.dart';
import 'package:commet/client/components/video_embed/video_provider.dart';
import 'package:commet/ui/molecules/url_preview_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tiamat/config/style/theme_extensions.dart';

class _FakeVideoProvider implements VideoProvider {
  int resolveCount = 0;

  @override
  String get id => 'fake';

  @override
  String get name => 'Fake Video';

  @override
  VideoCapabilities get capabilities => VideoCapabilities.native;

  @override
  bool canHandle(Uri uri) => true;

  @override
  Future<VideoEmbedInfo?> resolve(
    Uri uri, {
    bool fetchPlayback = false,
    http.Client? client,
  }) async {
    if (fetchPlayback) resolveCount++;
    return VideoEmbedInfo(
      originalUrl: uri,
      title: 'Fake Title',
      platformName: 'Fake Platform',
      playbackSource: fetchPlayback
          ? NativeVideoSource(Uri.parse('https://example.com/video.mp4'))
          : null,
      capabilities: VideoCapabilities.native,
    );
  }
}

Widget _testApp(Widget child) => MaterialApp(
      theme: ThemeData.light().copyWith(
        extensions: const [ThemeSettings()],
      ),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'card tap opens paused modal, play tap opens autoplay modal, link tap opens browser',
      (tester) async {
    final uri = Uri.parse('https://www.youtube.com/shorts/3f5e0jP8hK8');
    final fakeProvider = _FakeVideoProvider();
    final composite = CompositeVideoProvider(providers: [fakeProvider]);

    final autoplayEvents = <bool>[];
    var externalLinkOpens = 0;

    final preview = UrlPreviewData(
      uri,
      title: 'Awesome Shorts',
      siteName: 'YouTube Shorts',
      type: UrlDestinationType.video,
      videoEmbedInfo: VideoEmbedInfo(
        originalUrl: uri,
        title: 'Awesome Shorts',
        platformName: 'YouTube Shorts',
        isShortForm: true,
        aspectRatio: 9.0 / 16.0,
      ),
    );

    await tester.pumpWidget(
      _testApp(
        UrlPreviewWidget(
          preview,
          provider: composite,
          onOpenVideo: (_, __, autoplay) async {
            autoplayEvents.add(autoplay);
          },
          onOpenLink: () {
            externalLinkOpens++;
          },
        ),
      ),
    );

    // 1. Tap card visual area (away from play button and link)
    final cardFinder = find.byKey(const ValueKey('url-preview-card'));
    expect(cardFinder, findsOneWidget);
    await tester.tapAt(tester.getTopLeft(cardFinder) + const Offset(8, 8));
    await tester.pump();

    // Opened modal without autoplay
    expect(autoplayEvents, [false]);
    expect(externalLinkOpens, 0);

    // 2. Tap Play button overlay
    final playFinder = find.byKey(const ValueKey('url-preview-play'));
    expect(playFinder, findsOneWidget);
    await tester.tap(playFinder);
    await tester.pump();

    // Opened modal WITH autoplay
    expect(autoplayEvents, [false, true]);
    expect(externalLinkOpens, 0);

    // 3. Tap explicit external URL link
    final linkFinder = find.byKey(const ValueKey('url-preview-external-link'));
    expect(linkFinder, findsOneWidget);
    await tester.tap(linkFinder);
    await tester.pump();

    // External link opened in browser; no new modal opened
    expect(externalLinkOpens, 1);
    expect(autoplayEvents.length, 2);

    // Check Short-form visual badge is present
    expect(find.byKey(const ValueKey('url-preview-badge')), findsOneWidget);
    expect(find.text('YouTube Shorts'), findsNWidgets(2));
    expect(find.byIcon(Icons.bolt), findsOneWidget);
  });

  group('play falls back to the browser', () {
    final uri = Uri.parse('https://www.youtube.com/watch?v=ettaeKZHAwA');

    Future<({List<bool> videoOpens, List<int> linkOpens})> tapPlay(
      WidgetTester tester, {
      required UrlPreviewData preview,
      required CompositeVideoProvider provider,
      required bool supportsOfficialEmbeds,
    }) async {
      final videoOpens = <bool>[];
      final linkOpens = <int>[];
      await tester.pumpWidget(
        _testApp(
          UrlPreviewWidget(
            preview,
            provider: provider,
            supportsOfficialEmbeds: supportsOfficialEmbeds,
            onOpenVideo: (_, __, autoplay) async => videoOpens.add(autoplay),
            onOpenLink: () => linkOpens.add(1),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('url-preview-play')));
      await tester.pump();
      return (videoOpens: videoOpens, linkOpens: linkOpens);
    }

    UrlPreviewData youtubePreview() => UrlPreviewData(
          uri,
          title: 'A YouTube video',
          siteName: 'YouTube',
          type: UrlDestinationType.video,
          videoEmbedInfo: VideoEmbedInfo(
            originalUrl: uri,
            title: 'A YouTube video',
            platformName: 'YouTube',
            capabilities: VideoCapabilities.officialEmbed,
          ),
        );

    testWidgets('for a YouTube link when there is no web view', (tester) async {
      final result = await tapPlay(
        tester,
        preview: youtubePreview(),
        provider: CompositeVideoProvider(providers: [_OfficialEmbedProvider()]),
        supportsOfficialEmbeds: false,
      );

      expect(result.videoOpens, isEmpty);
      expect(result.linkOpens, hasLength(1));
    });

    testWidgets('except where a web view can host the embed', (tester) async {
      final result = await tapPlay(
        tester,
        preview: youtubePreview(),
        provider: CompositeVideoProvider(providers: [_OfficialEmbedProvider()]),
        supportsOfficialEmbeds: true,
      );

      expect(result.videoOpens, [true]);
      expect(result.linkOpens, isEmpty);
    });

    testWidgets('for an embed page no provider can play', (tester) async {
      // What the preview component builds for Vimeo: og:video is a
      // text/html player page, so there is no stream to play.
      final vimeo = Uri.parse('https://vimeo.com/76979871');
      final result = await tapPlay(
        tester,
        preview: UrlPreviewData(
          vimeo,
          title: 'A Vimeo video',
          siteName: 'Vimeo',
          type: UrlDestinationType.video,
        ),
        provider: CompositeVideoProvider(providers: []),
        supportsOfficialEmbeds: true,
      );

      expect(result.videoOpens, isEmpty);
      expect(result.linkOpens, hasLength(1));
      expect(find.text('Video unavailable. Please try again.'), findsNothing);
    });
  });
}

class _OfficialEmbedProvider implements VideoProvider {
  @override
  String get id => 'official';

  @override
  String get name => 'Official';

  @override
  VideoCapabilities get capabilities => VideoCapabilities.officialEmbed;

  @override
  bool canHandle(Uri uri) => true;

  @override
  Future<VideoEmbedInfo?> resolve(
    Uri uri, {
    bool fetchPlayback = false,
    http.Client? client,
  }) async {
    return VideoEmbedInfo(
      originalUrl: uri,
      title: 'A YouTube video',
      platformName: 'YouTube',
      playbackSource: fetchPlayback
          ? OfficialVideoEmbedSource(
              Uri.https('www.youtube-nocookie.com', '/embed/ettaeKZHAwA'),
              provider: OfficialVideoProvider.youtube,
            )
          : null,
      capabilities: capabilities,
    );
  }
}
