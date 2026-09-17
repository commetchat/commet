import 'package:commet/client/components/video_embed/composite_video_provider.dart';
import 'package:commet/client/components/video_embed/providers/generic_video_provider.dart';
import 'package:commet/client/components/video_embed/providers/instagram_provider.dart';
import 'package:commet/client/components/video_embed/providers/twitter_provider.dart';
import 'package:commet/client/components/video_embed/providers/youtube_provider.dart';
import 'package:commet/client/components/video_embed/video_capabilities.dart';
import 'package:commet/client/components/video_embed/video_embed_info.dart';
import 'package:commet/client/components/video_embed/video_playback_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoCapabilities & Models', () {
    test('declares native and official embed capability defaults', () {
      expect(VideoCapabilities.native.supportsPlaybackRate, isTrue);
      expect(VideoCapabilities.native.supportsVolume, isTrue);
      expect(VideoCapabilities.native.supportsFullscreen, isTrue);
      expect(VideoCapabilities.native.supportsQualitySelection, isTrue);
      expect(VideoCapabilities.native.supportsCaptions, isTrue);
      expect(VideoCapabilities.native.supportsCustomControls, isTrue);

      expect(VideoCapabilities.officialEmbed.supportsCustomControls, isFalse);
      expect(VideoCapabilities.officialEmbed.supportsFullscreen, isTrue);
    });

    test('VideoEmbedInfo creates and copies with correct properties', () {
      final info = VideoEmbedInfo(
        originalUrl: Uri.parse('https://www.youtube.com/shorts/3f5e0jP8hK8'),
        title: 'Shorts Video',
        platformName: 'YouTube Shorts',
        isShortForm: true,
        aspectRatio: 9.0 / 16.0,
      );

      expect(info.isShortForm, isTrue);
      expect(info.aspectRatio, 9.0 / 16.0);
      expect(info.platformName, 'YouTube Shorts');

      final updated = info.copyWith(
        title: 'Updated Short',
        streamUrl: Uri.parse('https://stream.mp4'),
      );
      expect(updated.title, 'Updated Short');
      expect(updated.streamUrl, Uri.parse('https://stream.mp4'));
      expect(updated.isShortForm, isTrue);
    });
  });

  group('YouTubeProvider', () {
    final provider = YouTubeProvider();

    test('canHandle detects standard YouTube URLs', () {
      expect(
        provider.canHandle(Uri.parse('https://www.youtube.com/watch?v=dQw4w9WgXcQ')),
        isTrue,
      );
      expect(
        provider.canHandle(Uri.parse('https://youtu.be/dQw4w9WgXcQ')),
        isTrue,
      );
      expect(
        provider.canHandle(Uri.parse('https://m.youtube.com/watch?v=dQw4w9WgXcQ&t=42s')),
        isTrue,
      );
    });

    test('canHandle detects YouTube Shorts URLs with parameters', () {
      expect(
        provider.canHandle(Uri.parse('https://www.youtube.com/shorts/3f5e0jP8hK8')),
        isTrue,
      );
      expect(
        provider.canHandle(
          Uri.parse('https://youtube.com/shorts/3f5e0jP8hK8?feature=share&si=test'),
        ),
        isTrue,
      );
    });

    test('canHandle rejects malicious / spoofed domains', () {
      expect(
        provider.canHandle(Uri.parse('https://youtube.com.attacker.com/watch?v=123')),
        isFalse,
      );
      expect(provider.canHandle(Uri.parse('https://notyoutube.com/watch?v=123')), isFalse);
      expect(provider.canHandle(Uri.parse('https://example.com/video')), isFalse);
    });

    test('extracts video ID and distinguishes Shorts (9:16) from normal videos (16:9)', () {
      final regularUri = Uri.parse('https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=10s');
      expect(provider.extractVideoId(regularUri), 'dQw4w9WgXcQ');
      expect(provider.isShorts(regularUri), isFalse);

      final shortsUri = Uri.parse('https://www.youtube.com/shorts/3f5e0jP8hK8');
      expect(provider.extractVideoId(shortsUri), '3f5e0jP8hK8');
      expect(provider.isShorts(shortsUri), isTrue);
    });

    test('resolves Shorts using official privacy-enhanced embed (youtube-nocookie.com)', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          '{"title":"Awesome Short","author_name":"Creator",'
          '"thumbnail_url":"https://i.ytimg.com/vi/3f5e0jP8hK8/hqdefault.jpg"}',
          200,
        );
      });

      final result = await provider.resolve(
        Uri.parse('https://www.youtube.com/shorts/3f5e0jP8hK8?feature=share'),
        fetchPlayback: true,
        client: mockClient,
      );

      expect(result, isNotNull);
      expect(result!.isShortForm, isTrue);
      expect(result.aspectRatio, 9.0 / 16.0);
      expect(result.platformName, 'YouTube Shorts');
      expect(result.title, 'Awesome Short');
      expect(result.author, 'Creator');

      final source = result.playbackSource as OfficialVideoEmbedSource?;
      expect(source?.provider, OfficialVideoProvider.youtube);
      expect(source?.uri.host, 'www.youtube-nocookie.com');
      expect(source?.uri.path, '/embed/3f5e0jP8hK8');
      expect(source?.uri.queryParameters['autoplay'], '1');
      expect(source?.uri.queryParameters['playsinline'], '1');
    });
  });

  group('TwitterProvider', () {
    final provider = TwitterProvider();

    test('canHandle detects Twitter and X status URLs', () {
      expect(provider.canHandle(Uri.parse('https://twitter.com/jack/status/20')), isTrue);
      expect(provider.canHandle(Uri.parse('https://x.com/jack/status/20?s=20')), isTrue);
      expect(
          provider.canHandle(
              Uri.parse('https://fxtwitter.com/crubielson/status/2099241162825470403')),
          isTrue);
      expect(provider.canHandle(Uri.parse('https://fixupx.com/jack/status/20')), isTrue);
      expect(provider.canHandle(Uri.parse('https://vxtwitter.com/jack/status/20')), isTrue);
      expect(provider.canHandle(Uri.parse('https://fxtwitter.com/jack')), isFalse);
    });

    test('canHandle rejects non-status Twitter/X URLs and attacker domains', () {
      expect(provider.canHandle(Uri.parse('https://x.com/home')), isFalse);
      expect(provider.canHandle(Uri.parse('https://twitter.com/settings')), isFalse);
      expect(provider.canHandle(Uri.parse('https://x.com.attacker.org/jack/status/20')), isFalse);
    });

    test('differentiates tweet with video from tweet with only text/image', () async {
      // Mock tweet with ONLY images (no video)
      final textOnlyClient = MockClient((_) async {
        return http.Response(
          '{"tweet":{"text":"No video here","media":{"photos":[{"url":"https://pic.jpg"}]}}}',
          200,
        );
      });

      final noVideoResult = await provider.resolve(
        Uri.parse('https://x.com/user/status/12345'),
        fetchPlayback: true,
        client: textOnlyClient,
      );
      // Invariant: must be null so it is NOT treated as a video player card
      expect(noVideoResult, isNull);

      // Mock tweet WITH video
      final videoClient = MockClient((_) async {
        return http.Response(
          '{"tweet":{"text":"Check out this video!","author":{"name":"John","screen_name":"john"},'
          '"media":{"videos":[{"url":"https://video.twimg.com/ext_tw_video/123.mp4",'
          '"thumbnail_url":"https://thumb.jpg","width":1080,"height":1920,"duration":15.5}]}}}',
          200,
        );
      });

      final videoResult = await provider.resolve(
        Uri.parse('https://x.com/john/status/98765'),
        fetchPlayback: true,
        client: videoClient,
      );

      expect(videoResult, isNotNull);
      expect(videoResult!.streamUrl, Uri.parse('https://video.twimg.com/ext_tw_video/123.mp4'));
      expect(videoResult.isShortForm, isTrue); // 1080/1920 < 0.85 => vertical
      expect(videoResult.playbackSource, isA<NativeVideoSource>());
      expect(videoResult.effectiveCapabilities.supportsVolume, isTrue);
      expect(videoResult.effectiveCapabilities.supportsPlaybackRate, isTrue);
    });
  });

  group('InstagramProvider', () {
    final provider = InstagramProvider();

    test('canHandle detects Instagram reels and posts', () {
      expect(provider.canHandle(Uri.parse('https://www.instagram.com/reel/C3bV8Uyrk8q/')), isTrue);
      expect(provider.canHandle(Uri.parse('https://instagram.com/p/C3bV8Uyrk8q/')), isTrue);
      expect(provider.canHandle(Uri.parse('https://instagram.com/tv/C3bV8Uyrk8q/')), isTrue);
    });

    test('canHandle rejects profile and general pages', () {
      expect(provider.canHandle(Uri.parse('https://www.instagram.com/explore/')), isFalse);
      expect(provider.canHandle(Uri.parse('https://instagram.com/accounts/login/')), isFalse);
    });

    test('extracts shortcode and marks Reel as 9:16 aspect ratio', () async {
      final reelUri = Uri.parse('https://www.instagram.com/reel/C3bV8Uyrk8q/?igsh=abc==');
      final result = await provider.resolve(reelUri, fetchPlayback: true);

      expect(result, isNotNull);
      expect(result!.isShortForm, isTrue);
      expect(result.aspectRatio, 9.0 / 16.0);
      expect(result.platformName, 'Instagram Reels');

      final source = result.playbackSource as OfficialVideoEmbedSource?;
      expect(source?.provider, OfficialVideoProvider.instagram);
      expect(source?.uri.path, '/reel/C3bV8Uyrk8q/embed/');
    });
  });

  group('GenericVideoProvider', () {
    final provider = GenericVideoProvider();

    test('handles direct video extensions', () async {
      final uri = Uri.parse('https://example.com/assets/video.mp4');
      expect(provider.canHandle(uri), isTrue);

      final result = await provider.resolve(uri);
      expect(result?.title, 'video.mp4');
      expect(result?.streamUrl, uri);
      expect(result?.playbackSource, isA<NativeVideoSource>());
      expect(result?.effectiveCapabilities.supportsCustomControls, isTrue);
    });

    test('rejects non-video extensions', () {
      expect(provider.canHandle(Uri.parse('https://example.com/photo.png')), isFalse);
      expect(provider.canHandle(Uri.parse('https://example.com/index.html')), isFalse);
    });
  });

  group('CompositeVideoProvider', () {
    final composite = CompositeVideoProvider();

    test('delegates canHandle across providers', () {
      expect(composite.canHandle(Uri.parse('https://youtu.be/123')), isTrue);
      expect(composite.canHandle(Uri.parse('https://x.com/user/status/456')), isTrue);
      expect(composite.canHandle(Uri.parse('https://instagram.com/reel/789/')), isTrue);
      expect(composite.canHandle(Uri.parse('https://example.com/video.webm')), isTrue);
      expect(composite.canHandle(Uri.parse('https://github.com')), isFalse);
    });
  });
}
