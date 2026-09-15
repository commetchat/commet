import 'dart:typed_data';

import 'package:commet/client/components/video_embed/video_capabilities.dart';
import 'package:commet/ui/molecules/video_player/video_player_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VideoPlayerController Seam', () {
    test('volume mute and unmute toggle restores previous non-zero volume',
        () async {
      final volumeValues = <double>[];
      final controller = VideoPlayerController();
      controller.attach(
        pause: () async {},
        play: () async {},
        replay: () async {},
        getLength: () async => Duration.zero,
        getSize: () async => const Size(640, 360),
        screenshot: () async => Uint8List(0),
        seekTo: (_) async {},
        setVolume: (value) async => volumeValues.add(value),
      );

      await controller.setVolume(75.0);
      expect(controller.settings.volume, 75.0);
      expect(controller.settings.isMuted, isFalse);

      // Mute
      await controller.toggleMute();
      expect(controller.settings.volume, 0.0);
      expect(controller.settings.isMuted, isTrue);

      // Unmute restores 75.0
      await controller.toggleMute();
      expect(controller.settings.volume, 75.0);
      expect(controller.settings.isMuted, isFalse);

      expect(volumeValues, [75.0, 0.0, 75.0]);
    });

    test('playback rate forwarding and state updates for 0.25x to 2.0x speeds',
        () async {
      final rateCalls = <double>[];
      final controller = VideoPlayerController();
      controller.attach(
        pause: () async {},
        play: () async {},
        replay: () async {},
        getLength: () async => Duration.zero,
        getSize: () async => const Size(640, 360),
        seekTo: (_) async {},
        setRate: (rate) async => rateCalls.add(rate),
      );

      const supportedRates = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
      for (final rate in supportedRates) {
        await controller.setRate(rate);
        expect(controller.settings.rate, rate);
      }

      expect(rateCalls, supportedRates);
    });

    test('track selection and fullscreen forwarding', () async {
      final operations = <String>[];
      final controller = VideoPlayerController();
      controller.attach(
        pause: () async => operations.add('pause'),
        play: () async => operations.add('play'),
        replay: () async => operations.add('replay'),
        getLength: () async => const Duration(seconds: 120),
        getSize: () async => const Size(1920, 1080),
        seekTo: (pos) async => operations.add('seek:${pos.inSeconds}'),
        setVolume: (vol) async => operations.add('vol:$vol'),
        setRate: (rate) async => operations.add('rate:$rate'),
        selectVideoTrack: (id) async => operations.add('videoTrack:$id'),
        selectSubtitleTrack: (id) async => operations.add('subtitleTrack:$id'),
        enterFullscreen: () async => operations.add('enterFullscreen'),
        exitFullscreen: () async => operations.add('exitFullscreen'),
      );

      controller.updateSettings(
        qualities: const [
          VideoQualityOption(id: '720', label: '720p'),
          VideoQualityOption(id: '1080', label: '1080p'),
        ],
        subtitles: const [
          VideoSubtitleOption(id: 'en', label: 'English', language: 'en'),
        ],
        capabilities: VideoCapabilities.native,
      );

      await controller.play();
      await controller.selectVideoTrack('1080');
      await controller.selectSubtitleTrack('en');
      await controller.enterFullscreen();
      await controller.exitFullscreen();
      await controller.pause();

      expect(operations, [
        'play',
        'videoTrack:1080',
        'subtitleTrack:en',
        'enterFullscreen',
        'exitFullscreen',
        'pause',
      ]);
      expect(controller.settings.selectedQualityId, '1080');
      expect(controller.settings.selectedSubtitleId, 'en');
      expect(controller.settings.playing, isFalse);
    });
  });
}
