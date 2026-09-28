import 'dart:async';
import 'dart:typed_data';
import 'package:commet/client/components/voip/android_screencapture_source.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/webrtc_screencapture_source.dart';
import 'package:commet/ui/organisms/call_view/screen_capture_source_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:tiamat/config/style/theme_extensions.dart';

Widget createTestApp(Widget child) {
  return MaterialApp(
    theme: ThemeData.light().copyWith(
      extensions: const [
        ThemeSettings(),
      ],
    ),
    home: child,
  );
}

class DummyDesktopCapturerSource implements DesktopCapturerSource {
  @override
  final String id;
  @override
  final String name;
  @override
  final Uint8List? thumbnail = null;
  @override
  final ThumbnailSize thumbnailSize = ThumbnailSize(100, 100);
  @override
  final SourceType type = SourceType.Screen;

  DummyDesktopCapturerSource({required this.id, required this.name});

  @override
  StreamController<String> get onNameChanged => StreamController.broadcast();
  @override
  StreamController<Uint8List> get onThumbnailChanged =>
      StreamController.broadcast();
}

void main() {
  group('Slice 1: ScreenCaptureSource and ScreenCaptureDialogResult Contract',
      () {
    test(
        'ScreenCaptureDialogResult defaults doNotShareAudio to false and captureAudio to true',
        () {
      final source =
          DummyDesktopCapturerSource(id: 'screen:0', name: 'Screen 1');
      final result = ScreenCaptureDialogResult(source: source);

      expect(result.source.id, equals('screen:0'));
      expect(result.doNotShareAudio, isFalse);
      expect(result.captureAudio, isTrue);
    });

    test(
        'ScreenCaptureDialogResult sets captureAudio to false when doNotShareAudio is true',
        () {
      final source =
          DummyDesktopCapturerSource(id: 'window:1', name: 'App Window');
      final result =
          ScreenCaptureDialogResult(source: source, doNotShareAudio: true);

      expect(result.doNotShareAudio, isTrue);
      expect(result.captureAudio, isFalse);
    });

    test('WebrtcScreencaptureSource defaults captureAudio to true', () {
      final source =
          DummyDesktopCapturerSource(id: 'screen:0', name: 'Screen 1');
      final captureSource = WebrtcScreencaptureSource(source);

      expect(captureSource.captureAudio, isTrue);
    });

    test('WebrtcScreencaptureSource accepts captureAudio parameter', () {
      final source =
          DummyDesktopCapturerSource(id: 'screen:0', name: 'Screen 1');
      final captureSourceWithAudio =
          WebrtcScreencaptureSource(source, captureAudio: true);
      final captureSourceWithoutAudio =
          WebrtcScreencaptureSource(source, captureAudio: false);

      expect(captureSourceWithAudio.captureAudio, isTrue);
      expect(captureSourceWithoutAudio.captureAudio, isFalse);
    });

    test('WebrtcBrowserScreenCaptureSource supports captureAudio', () {
      final browserDefault = WebrtcBrowserScreenCaptureSource();
      final browserNoAudio =
          WebrtcBrowserScreenCaptureSource(captureAudio: false);

      expect(browserDefault.captureAudio, isTrue);
      expect(browserNoAudio.captureAudio, isFalse);
    });

    test('WebrtcAndroidScreencaptureSource supports captureAudio', () {
      final androidDefault = WebrtcAndroidScreencaptureSource();
      final androidNoAudio =
          WebrtcAndroidScreencaptureSource(captureAudio: false);

      expect(androidDefault.captureAudio, isTrue);
      expect(androidNoAudio.captureAudio, isFalse);
    });
  });

  // Slice 2, the picker and its system audio switch, is in
  // screen_capture_source_dialog_test.dart.

  group('Slice 3: VoipSession Screen Share Audio Contract', () {
    test('setScreenShare activates screen audio when captureAudio is true',
        () async {
      final session = MockScreenShareVoipSession();
      final source =
          DummyDesktopCapturerSource(id: 'screen:0', name: 'Screen 1');
      final captureSource =
          WebrtcScreencaptureSource(source, captureAudio: true);

      expect(session.isSharingScreen, isFalse);
      expect(session.isScreenAudioActive, isFalse);

      await session.setScreenShare(captureSource);

      expect(session.isSharingScreen, isTrue);
      expect(session.isScreenAudioActive, isTrue);
      expect(session.currentScreenshare?.captureAudio, isTrue);
    });

    test(
        'setScreenShare does not activate screen audio when captureAudio is false',
        () async {
      final session = MockScreenShareVoipSession();
      final source =
          DummyDesktopCapturerSource(id: 'screen:0', name: 'Screen 1');
      final captureSource =
          WebrtcScreencaptureSource(source, captureAudio: false);

      await session.setScreenShare(captureSource);

      expect(session.isSharingScreen, isTrue);
      expect(session.isScreenAudioActive, isFalse);
      expect(session.currentScreenshare?.captureAudio, isFalse);
    });

    test('stopScreenshare disables both screenshare and screen audio',
        () async {
      final session = MockScreenShareVoipSession();
      final source =
          DummyDesktopCapturerSource(id: 'screen:0', name: 'Screen 1');
      final captureSource =
          WebrtcScreencaptureSource(source, captureAudio: true);

      await session.setScreenShare(captureSource);
      expect(session.isSharingScreen, isTrue);
      expect(session.isScreenAudioActive, isTrue);

      await session.stopScreenshare();
      expect(session.isSharingScreen, isFalse);
      expect(session.isScreenAudioActive, isFalse);
      expect(session.currentScreenshare, isNull);
    });
  });
}

class MockScreenShareVoipSession implements VoipSession {
  ScreenCaptureSource? currentScreenshare;
  bool isScreenAudioActive = false;
  bool _isSharingScreen = false;

  @override
  bool get isSharingScreen => _isSharingScreen;

  @override
  Future<void> setScreenShare(ScreenCaptureSource source) async {
    currentScreenshare = source;
    _isSharingScreen = true;
    isScreenAudioActive = source.captureAudio;
  }

  @override
  Future<void> stopScreenshare() async {
    currentScreenshare = null;
    _isSharingScreen = false;
    isScreenAudioActive = false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
