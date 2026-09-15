// Copyright 2024 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:collection/collection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../../events.dart';
import '../../exceptions.dart';
import '../../extensions.dart';
import '../../logger.dart';
import '../../options.dart';
import '../../proto/livekit_models.pb.dart' as lk_models;
import '../../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../../stats/stats.dart';
import '../../support/platform.dart';
import '../../types/other.dart';
import '../../utils.dart' show isSVCCodec;
import '../options.dart';
import 'audio.dart';
import 'local.dart';

class SimulcastTrackInfo {
  String codec;

  rtc.MediaStreamTrack mediaStreamTrack;

  rtc.RTCRtpSender? sender;

  List<rtc.RTCRtpEncoding>? encodings;

  SimulcastTrackInfo({
    required this.codec,
    this.encodings,
    required this.mediaStreamTrack,
    this.sender,
  });
}

/// A video track from the local device. Use static methods in this class to create
/// video tracks.
class LocalVideoTrack extends LocalTrack with VideoTrack {
  // Options used for this track
  @override
  covariant VideoCaptureOptions currentOptions;

  VideoPublishOptions? lastPublishOptions;

  num? _currentBitrate;
  num? get currentBitrate => _currentBitrate;

  Map<String, VideoSenderStats>? prevStats;
  final Map<String, num> _bitrateFoLayers = {};

  Map<String, SimulcastTrackInfo> simulcastCodecs = {};
  Map<(String, int), rtc.RTCRtpEncoding> encodingBackups = {};

  List<lk_rtc.SubscribedCodec> subscribedCodecs = [];

  @override
  Future<bool> monitorStats() async {
    if (events.isDisposed || !isActive) {
      _currentBitrate = 0;
      return false;
    }
    List<VideoSenderStats> stats = [];
    try {
      stats = await getSenderStats();
    } catch (e) {
      logger.warning('Failed to get sender stats: $e');
      return false;
    }
    final Map<String, VideoSenderStats> statsMap = {};

    for (var s in stats) {
      statsMap[s.rid ?? 'f'] = s;
    }

    if (prevStats != null) {
      num totalBitrate = 0;
      statsMap.forEach((key, s) {
        final prev = prevStats![key];
        if (prev == null) {
          return;
        }
        try {
          final bitRateForlayer = computeBitrateForSenderStats(s, prev).toInt();
          _bitrateFoLayers[key] = bitRateForlayer;
          totalBitrate += bitRateForlayer;
        } catch (e) {
          logger.warning('Failed to compute bitrate for layer: $e');
        }
      });
      _currentBitrate = totalBitrate;
      events.emit(
        VideoSenderStatsEvent(
          stats: statsMap,
          currentBitrate: totalBitrate,
          bitrateForLayers: _bitrateFoLayers,
        ),
      );
    }

    prevStats = statsMap;
    return true;
  }

  Future<List<VideoSenderStats>> getSenderStats() async {
    if (sender == null) {
      return [];
    }

    final stats = await sender!.getStats();
    final List<VideoSenderStats> items = [];
    for (var v in stats) {
      if (v.type == 'outbound-rtp') {
        final vs = VideoSenderStats(v.id, v.timestamp);
        vs.frameHeight = getNumValFromReport(v.values, 'frameHeight');
        vs.frameWidth = getNumValFromReport(v.values, 'frameWidth');
        vs.framesPerSecond = getNumValFromReport(v.values, 'framesPerSecond');
        vs.firCount = getNumValFromReport(v.values, 'firCount');
        vs.pliCount = getNumValFromReport(v.values, 'pliCount');
        vs.nackCount = getNumValFromReport(v.values, 'nackCount');
        vs.packetsSent = getNumValFromReport(v.values, 'packetsSent');
        vs.bytesSent = getNumValFromReport(v.values, 'bytesSent');
        vs.framesSent = getNumValFromReport(v.values, 'framesSent');
        vs.rid = getStringValFromReport(v.values, 'rid');
        vs.encoderImplementation = getStringValFromReport(
          v.values,
          'encoderImplementation',
        );
        vs.retransmittedPacketsSent = getNumValFromReport(
          v.values,
          'retransmittedPacketsSent',
        );
        vs.qualityLimitationReason = getStringValFromReport(
          v.values,
          'qualityLimitationReason',
        );
        vs.qualityLimitationResolutionChanges = getNumValFromReport(
          v.values,
          'qualityLimitationResolutionChanges',
        );

        // locate the appropriate remote-inbound-rtp item
        final remoteId = getStringValFromReport(v.values, 'remoteId');
        final r = stats.firstWhereOrNull((element) => element.id == remoteId);
        if (r != null) {
          vs.jitter = getNumValFromReport(r.values, 'jitter');
          vs.packetsLost = getNumValFromReport(r.values, 'packetsLost');
          vs.roundTripTime = getNumValFromReport(r.values, 'roundTripTime');
        }
        final c = stats.firstWhereOrNull((element) => element.type == 'codec');
        if (c != null) {
          vs.mimeType = getStringValFromReport(c.values, 'mimeType');
          vs.payloadType = getNumValFromReport(c.values, 'payloadType');
          vs.channels = getNumValFromReport(c.values, 'channels');
          vs.clockRate = getNumValFromReport(c.values, 'clockRate');
        }
        items.add(vs);
      }
    }
    return items;
  }

  // Private constructor
  @internal
  LocalVideoTrack(
    TrackSource source,
    rtc.MediaStream stream,
    rtc.MediaStreamTrack track,
    this.currentOptions,
  ) : super(TrackType.VIDEO, source, stream, track);

  /// Creates a LocalVideoTrack from camera input.
  static Future<LocalVideoTrack> createCameraTrack([
    CameraCaptureOptions? options,
  ]) async {
    options ??= const CameraCaptureOptions();

    final stream = await LocalTrack.createStream(options);
    final track = LocalVideoTrack(
      TrackSource.camera,
      stream,
      stream.getVideoTracks().first,
      options,
    );

    if (options.processor != null) {
      await track.setProcessor(options.processor);
    }

    return track;
  }

  /// Creates a LocalVideoTrack from the display.
  ///
  /// Note: Android requires a foreground service to be started prior to
  /// creating a screen track. Refer to the example app for an implementation.
  static Future<LocalVideoTrack> createScreenShareTrack([
    ScreenShareCaptureOptions? options,
  ]) async {
    if (lkPlatformIsWebMobile()) {
      throw TrackCreateException(
        'Screen sharing is not supported on mobile devices',
      );
    }
    options ??= const ScreenShareCaptureOptions();

    final stream = await LocalTrack.createStream(options);
    return LocalVideoTrack(
      TrackSource.screenShareVideo,
      stream,
      stream.getVideoTracks().first,
      options,
    );
  }

  /// Creates a LocalTracks(audio/video) from the display.
  ///
  /// The current API is mainly used to capture audio when chrome captures tab,
  /// but in the future it can also be used for flutter native to open audio
  /// capture device when capturing screen
  static Future<List<LocalTrack>> createScreenShareTracksWithAudio([
    ScreenShareCaptureOptions? options,
  ]) async {
    if (lkPlatformIsWebMobile()) {
      throw TrackCreateException(
        'Screen sharing is not supported on mobile devices',
      );
    }
    if (options == null) {
      options = const ScreenShareCaptureOptions(captureScreenAudio: true);
    } else {
      options = options.copyWith(captureScreenAudio: true);
    }
    final stream = await LocalTrack.createStream(options);

    final List<LocalTrack> tracks = [
      LocalVideoTrack(
        TrackSource.screenShareVideo,
        stream,
        stream.getVideoTracks().first,
        options,
      ),
    ];

    if (stream.getAudioTracks().isNotEmpty) {
      tracks.add(
        LocalAudioTrack(
          TrackSource.screenShareAudio,
          stream,
          stream.getAudioTracks().first,
          const AudioCaptureOptions(),
        ),
      );
    }
    return tracks;
  }
}

//
// Convenience extensions
//
extension LocalVideoTrackExt on LocalVideoTrack {
  // Calls restartTrack under the hood
  Future<void> setCameraPosition(CameraPosition position) async {
    final options = currentOptions;
    if (options is! CameraCaptureOptions) {
      logger.warning('Not a camera track');
      return;
    }
    final newOptions = CameraCaptureOptions(
      cameraPosition: position,
      deviceId: null,
      maxFrameRate: options.maxFrameRate,
      params: options.params,
    );
    await restartTrack(newOptions);
    await replaceTrackForMultiCodecSimulcast(mediaStreamTrack);
    currentOptions = newOptions;
  }

  Future<void> switchCamera(String deviceId, {bool fastSwitch = false}) async {
    final options = currentOptions;
    if (options is! CameraCaptureOptions) {
      logger.warning('Not a camera track');
      return;
    }

    if (fastSwitch) {
      currentOptions = options.copyWith(deviceId: deviceId);
      await rtc.Helper.switchCamera(mediaStreamTrack, deviceId, mediaStream);
      return;
    }

    await restartTrack(options.copyWith(deviceId: deviceId));

    await replaceTrackForMultiCodecSimulcast(mediaStreamTrack);
  }

  Future<void> replaceTrackForMultiCodecSimulcast(
    rtc.MediaStreamTrack newTrack,
  ) async {
    simulcastCodecs.forEach((key, simulcastTrack) async {
      await simulcastTrack.sender?.replaceTrack(newTrack);
      simulcastTrack.mediaStreamTrack = mediaStreamTrack;
    });
  }

  Future<List<String>> setPublishingCodecs(
    List<lk_rtc.SubscribedCodec> codecs,
    LocalTrack track,
  ) async {
    logger.fine('setPublishingCodecs $codecs');

    // only enable simulcast codec for preference codec setted
    if (codec == null && codecs.isNotEmpty) {
      await setPublishingLayers(track, codecs[0].qualities, isSVC: isSVCCodec(codecs[0].codec));
      return [];
    }

    subscribedCodecs = codecs;

    final List<String> newCodecs = [];

    for (var codec in codecs) {
      if (this.codec?.toLowerCase() == codec.codec.toLowerCase()) {
        await setPublishingLayers(track, codec.qualities, isSVC: isSVCCodec(codec.codec));
      } else {
        final simulcastCodecInfo = simulcastCodecs[codec.codec];
        logger.fine('setPublishingCodecs $codecs');
        if (simulcastCodecInfo == null) {
          for (var q in codec.qualities) {
            if (q.enabled) {
              newCodecs.add(codec.codec.toLowerCase());
              break;
            }
          }
        } else if (simulcastCodecInfo.encodings != null && simulcastCodecInfo.sender != null) {
          logger.fine('setPublishingCodecs $codecs');
          await setPublishingLayersForSender(
            simulcastCodecInfo.sender!,
            simulcastCodecInfo.encodings!,
            codec.qualities,
            isSVC: isSVCCodec(codec.codec),
          );
        }
      }
    }
    return newCodecs;
  }

  @internal
  Future<void> setPublishingLayers(
    LocalTrack? track,
    List<lk_rtc.SubscribedQuality> layers, {
    bool isSVC = false,
  }) async {
    logger.fine('Update publishing layers: $layers');

    if (track?.sender == null) {
      logger.fine('Update publishing layers: sender is null');
      return;
    }

    final params = track?.sender?.parameters;
    if (params == null) {
      logger.fine('Update publishing layers: sender params are null');
      return;
    }

    final encodings = params.encodings;
    if (encodings == null) {
      logger.fine('Update publishing layers: encodings are null');
      return;
    }

    return setPublishingLayersForSender(track!.sender!, encodings, layers, isSVC: isSVC);
  }

  lk_models.VideoQuality _videoQualityForRid(String rid) {
    switch (rid) {
      case 'f':
        return lk_models.VideoQuality.HIGH;
      case 'h':
        return lk_models.VideoQuality.MEDIUM;
      case 'q':
        return lk_models.VideoQuality.LOW;
      default:
        return lk_models.VideoQuality.HIGH;
    }
  }

  Future<void> setPublishingLayersForSender(
    rtc.RTCRtpSender sender,
    List<rtc.RTCRtpEncoding> encodings,
    List<lk_rtc.SubscribedQuality> layers, {
    bool isSVC = false,
  }) async {
    logger.fine('Update publishing layers: $layers');

    final params = sender.parameters;

    var hasChanged = false;

    // NOTE: closable spatial layer is disabled due to video blur / frozen issues
    // with Chrome 113+ and LiveKit SFU PLI handling. See JS SDK LocalVideoTrack.ts:529-568.
    // For SVC codecs, all layers are kept enabled and the SFU handles layer selection.
    if (isSVC) {
      final hasEnabledEncoding = layers.any((q) => q.enabled);
      if (hasEnabledEncoding) {
        for (var q in layers) {
          q.enabled = true;
        }
      }
    }
    // simulcast dynacast encodings
    var idx = 0;
    for (var encoding in encodings) {
      var rid = encoding.rid ?? '';
      if (rid == '') {
        rid = 'q';
      }
      final quality = _videoQualityForRid(rid);
      final subscribedQuality = layers.firstWhereOrNull(
        (q) => q.quality == quality,
      );
      if (subscribedQuality == null) {
        continue;
      }
      if (encoding.active != subscribedQuality.enabled) {
        hasChanged = true;
        encoding.active = subscribedQuality.enabled;
        logger.fine(
          'setting layer ${subscribedQuality.quality} to ${encoding.active ? 'enabled' : 'disabled'}',
        );

        // FireFox does not support setting encoding.active to false, so we
        // have a workaround of lowering its bitrate and resolution to the min.
        if (kIsWeb && lkBrowser() == BrowserType.firefox) {
          if (subscribedQuality.enabled) {
            final encodingBackup = encodingBackups[(sender.senderId, idx)] ?? encoding;
            encoding.scaleResolutionDownBy = encodingBackup.scaleResolutionDownBy;
            encoding.maxBitrate = encodingBackup.maxBitrate;
            encoding.maxFramerate = encodingBackup.maxFramerate;
          } else {
            encodingBackups[(sender.senderId, idx)] = rtc.RTCRtpEncoding(
              scaleResolutionDownBy: encoding.scaleResolutionDownBy,
              maxBitrate: encoding.maxBitrate,
              maxFramerate: encoding.maxFramerate,
            );
            encoding.scaleResolutionDownBy = 4;
            encoding.maxBitrate = 10;
            encoding.maxFramerate = 2;
          }
        }
      }
      idx++;
    }

    if (hasChanged) {
      params.encodings = encodings;
      try {
        final result = await sender.setParameters(params);
        if (result == false) {
          logger.warning('Failed to update sender parameters');
        }
      } catch (e) {
        logger.warning('Failed to update sender parameters $e');
      }
    }
  }

  SimulcastTrackInfo addSimulcastTrack(
    String codec,
    List<rtc.RTCRtpEncoding> encodings,
  ) {
    if (simulcastCodecs[codec] != null) {
      throw Exception('$codec already added');
    }
    final SimulcastTrackInfo simulcastCodecInfo = SimulcastTrackInfo(
      codec: codec,
      encodings: encodings,
      mediaStreamTrack: mediaStreamTrack,
    );

    simulcastCodecs[codec] = simulcastCodecInfo;
    return simulcastCodecInfo;
  }

  Future<void> setDegradationPreference(DegradationPreference preference) async {
    final params = sender?.parameters;
    if (params == null) {
      return;
    }
    params.degradationPreference = preference.toRTCType();
    await sender?.setParameters(params);
  }
}
