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

// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data' show Uint8List;

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:async/async.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

import '../core/engine.dart';
import '../core/room.dart';
import '../core/signal_client.dart';
import '../core/transport.dart';
import '../data_stream/stream_writer.dart';
import '../events.dart';
import '../exceptions.dart';
import '../extensions.dart';
import '../internal/events.dart';
import '../logger.dart';
import '../managers/broadcast_manager.dart';
import '../options.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../publication/local.dart';
import '../support/platform.dart';
import '../support/serial_runner.dart';
import '../track/local/audio.dart';
import '../track/local/local.dart';
import '../track/local/video.dart';
import '../track/options.dart';
import '../types/audio_encoding.dart';
import '../types/data_stream.dart';
import '../types/other.dart';
import '../types/participant_permissions.dart';
import '../types/rpc.dart';
import '../types/video_dimensions.dart';
import '../utils.dart' show buildStreamId, mimeTypeToVideoCodecString, Utils, compareVersions, isSVCCodec;
import 'participant.dart';

/// Represents the current participant in the room. Instance of [LocalParticipant] is automatically
/// created after successfully connecting to a [Room] and will be accessible from [Room.localParticipant].
class LocalParticipant extends Participant<LocalTrackPublication> {
  // RPC Pending Acks
  final Map<String, Function(String participantIdentity)> _pendingAcks = {};

  // RPC Pending Responses
  final Map<String, Function(String? payload, RpcError? error)> _pendingResponses = {};

  // Pending signal request responses (keyed by requestId)
  final Map<int, Completer<void>> _pendingSignalRequests = {};

  // Serializes publish operations to prevent duplicate tracks from concurrent calls
  final _publishRunner = SerialRunner<LocalTrackPublication?>();

  LocalParticipant._({
    required Room room,
    required String sid,
    required String identity,
    required String name,
  }) : super(
          room: room,
          sid: sid,
          identity: identity,
          name: name,
        );

  @internal
  static Future<LocalParticipant> createFromInfo({
    required Room room,
    required lk_models.ParticipantInfo info,
  }) async {
    final participant = LocalParticipant._(
      room: room,
      sid: info.sid,
      identity: info.identity,
      name: info.name,
    );

    await participant.updateFromInfo(info);

    if (lkPlatformIs(PlatformType.iOS)) {
      BroadcastManager().addListener(participant._broadcastStateChanged);
    }

    participant.onDispose(() async {
      BroadcastManager().removeListener(participant._broadcastStateChanged);
      // Fail any pending signal requests
      for (final completer in participant._pendingSignalRequests.values) {
        if (!completer.isCompleted) {
          completer.completeError(
            UnexpectedStateException('Participant disposed'),
          );
        }
      }
      participant._pendingSignalRequests.clear();
      await participant.unpublishAllTracks();
    });

    return participant;
  }

  @override
  @internal
  Future<bool> updateFromInfo(lk_models.ParticipantInfo info) async {
    final didUpdate = await super.updateFromInfo(info);
    if (!didUpdate) return false;

    // Reconcile local mute state with the server's copy.
    for (final trackInfo in info.tracks) {
      final pub = trackPublications[trackInfo.sid];
      if (pub == null) continue;

      final localMuted = pub.muted;
      if (localMuted != trackInfo.muted) {
        logger.fine(
          'updating server mute state after reconcile, track: ${trackInfo.sid}, muted: $localMuted',
        );
        try {
          room.engine.signalClient.sendMuteTrack(trackInfo.sid, localMuted);
        } catch (e) {
          logger.warning('Failed to update server mute state after reconcile: $e');
        }
      }
    }

    return true;
  }

  /// Handle broadcast state change (iOS only)
  void _broadcastStateChanged() {
    final isEnabled = BroadcastManager().isBroadcasting && BroadcastManager().shouldPublishTrack;
    // Listener must stay sync (void), so use unawaited here.
    unawaited(setScreenShareEnabled(isEnabled));
  }

  /// Publish an [AudioTrack] to the [Room].
  /// For most cases, using [setMicrophoneEnabled] would be simpler and recommended.
  Future<LocalTrackPublication<LocalAudioTrack>> publishAudioTrack(
    LocalAudioTrack track, {
    AudioPublishOptions? publishOptions,
  }) async {
    final result = await _publishRunner.run(() => _publishAudioTrack(track, publishOptions: publishOptions));
    return result! as LocalTrackPublication<LocalAudioTrack>;
  }

  Future<LocalTrackPublication<LocalAudioTrack>?> _publishAudioTrack(
    LocalAudioTrack track, {
    AudioPublishOptions? publishOptions,
  }) async {
    if (audioTrackPublications.any((e) => e.track?.mediaStreamTrack.id == track.mediaStreamTrack.id)) {
      throw TrackPublishException('track already exists');
    }

    // Use defaultPublishOptions if options is null
    publishOptions ??= track.lastPublishOptions ?? room.roomOptions.defaultAudioPublishOptions;

    final audioEncoding = publishOptions.encoding ?? AudioEncoding.presetMusic;
    final List<rtc.RTCRtpEncoding> encodings = [audioEncoding.toRTCRtpEncoding()];

    final req = lk_rtc.AddTrackRequest(
      cid: track.getCid(),
      name: publishOptions.name ?? AudioPublishOptions.defaultMicrophoneName,
      type: track.kind.toPBType(),
      source: track.source.toPBType(),
      muted: track.muted,
      stream: buildStreamId(publishOptions, track.source),
      disableDtx: !publishOptions.dtx,
      disableRed: room.e2eeManager != null ? true : publishOptions.red ?? true,
      encryption: room.roomOptions.lkEncryptionType,
    );

    // Populate audio features (e.g., TF_NO_DTX, TF_PRECONNECT_BUFFER)
    req.audioFeatures.addAll([
      if (!publishOptions.dtx) lk_models.AudioTrackFeature.TF_NO_DTX,
      if (publishOptions.preConnect) lk_models.AudioTrackFeature.TF_PRECONNECT_BUFFER,
    ]);

    Future<lk_models.TrackInfo> negotiate() async {
      track.transceiver = await room.engine.createTransceiverRTCRtpSender(track, publishOptions!, encodings);
      await room.engine.negotiate();
      return lk_models.TrackInfo();
    }

    late lk_models.TrackInfo trackInfo;
    if (room.engine.enabledPublishCodecs?.isNotEmpty ?? false) {
      final rets = await Future.wait<lk_models.TrackInfo>([room.engine.addTrack(req), negotiate()]);
      trackInfo = rets[0];
    } else {
      trackInfo = await room.engine.addTrack(req);

      final transceiverInit = rtc.RTCRtpTransceiverInit(
        direction: rtc.TransceiverDirection.SendOnly,
        sendEncodings: encodings,
      );
      // addTransceiver cannot pass in a kind parameter due to a bug in flutter-webrtc (web)
      track.transceiver = await room.engine.publisher?.pc.addTransceiver(
        track: track.mediaStreamTrack,
        kind: rtc.RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: transceiverInit,
      );

      await room.engine.negotiate();
    }

    logger.fine('publishAudioTrack engine.addTrack response: ${trackInfo}');

    track.lastPublishOptions = publishOptions;

    final pub = LocalTrackPublication<LocalAudioTrack>(
      participant: this,
      info: trackInfo,
      track: track,
    );
    addTrackPublication(pub);

    // did publish
    await track.onPublish();
    await track.processor?.onPublish(room);

    await room.applyAudioSpeakerSettings();

    final listener = track.createListener();
    listener.on((TrackEndedEvent event) async {
      logger.fine('TrackEndedEvent: ${event.track}');
      await removePublishedTrack(pub.sid);
    });

    [events, room.events].emit(LocalTrackPublishedEvent(
      participant: this,
      publication: pub,
    ));

    await track.start();

    return pub;
  }

  /// Publish a [LocalVideoTrack] to the [Room].
  /// For most cases, using [setCameraEnabled] would be simpler and recommended.
  Future<LocalTrackPublication<LocalVideoTrack>> publishVideoTrack(
    LocalVideoTrack track, {
    VideoPublishOptions? publishOptions,
  }) async {
    final result = await _publishRunner.run(() => _publishVideoTrack(track, publishOptions: publishOptions));
    return result! as LocalTrackPublication<LocalVideoTrack>;
  }

  Future<LocalTrackPublication<LocalVideoTrack>?> _publishVideoTrack(
    LocalVideoTrack track, {
    VideoPublishOptions? publishOptions,
  }) async {
    if (videoTrackPublications.any((e) => e.track?.mediaStreamTrack.id == track.mediaStreamTrack.id)) {
      throw TrackPublishException('track already exists');
    }

    // Use defaultPublishOptions if options is null
    publishOptions ??= track.lastPublishOptions ?? room.roomOptions.defaultVideoPublishOptions;

    if (publishOptions.videoCodec.toLowerCase() != publishOptions.videoCodec) {
      publishOptions = publishOptions.copyWith(
        videoCodec: publishOptions.videoCodec.toLowerCase(),
      );
    }

    if (room.engine.enabledPublishCodecs?.isNotEmpty ?? false) {
      // fallback to a supported codec if it is not supported
      if (!room.engine.enabledPublishCodecs!
          .where((c) => c.mime.startsWith('video/'))
          .where((c) => videoCodecs.any((v) => c.mime.toLowerCase().endsWith(v)))
          .any((c) => publishOptions?.videoCodec == mimeTypeToVideoCodecString(c.mime))) {
        publishOptions = publishOptions.copyWith(
          videoCodec: mimeTypeToVideoCodecString(room.engine.enabledPublishCodecs![0].mime).toLowerCase(),
        );
      }
    }

    // handle SVC publishing
    final isSVC = isSVCCodec(publishOptions.videoCodec);
    if (isSVC) {
      if (!room.roomOptions.dynacast) {
        room.engine.roomOptions = room.roomOptions.copyWith(dynacast: true);
      }

      if (publishOptions.scalabilityMode == null) {
        publishOptions = publishOptions.copyWith(
          scalabilityMode: 'L3T3_KEY',
        );
      }

      // vp9 svc with screenshare has problem to encode, always use L1T3 here
      if (track.source == TrackSource.screenShareVideo) {
        publishOptions = publishOptions.copyWith(
          scalabilityMode: 'L1T3',
        );
      }
    }

    // use finalraints passed to getUserMedia by default
    VideoDimensions dimensions = track.currentOptions.params.dimensions;

    if (kIsWeb || lkPlatformIsMobile()) {
      // getSettings() is only implemented for Web & Mobile
      try {
        // try to use getSettings for more accurate resolution
        final settings = track.mediaStreamTrack.getSettings();
        if ((settings['width'] is int && settings['width'] as int > 0) &&
            (settings['height'] is int && settings['height'] as int > 0)) {
          dimensions = dimensions.copyWith(width: settings['width'] as int);
          dimensions = dimensions.copyWith(height: settings['height'] as int);
        }
      } catch (_) {
        logger.warning('Failed to call `mediaStreamTrack.getSettings()`');
      }
    }

    logger.fine('Compute encodings with resolution: ${dimensions}, options: ${publishOptions}');

    // Video encodings and simulcasts
    var encodings = Utils.computeVideoEncodings(
      isScreenShare: track.source == TrackSource.screenShareVideo,
      dimensions: dimensions,
      options: publishOptions,
      codec: publishOptions.videoCodec,
    );

    logger.fine('Using encodings: ${encodings?.map((e) => e.toMap())}');

    final simulcastCodecs = <lk_rtc.SimulcastCodec>[
      lk_rtc.SimulcastCodec(
        codec: publishOptions.videoCodec,
        cid: track.getCid(),
      ),
    ];

    if (publishOptions.backupVideoCodec.enabled && publishOptions.backupVideoCodec.codec != publishOptions.videoCodec) {
      simulcastCodecs.add(lk_rtc.SimulcastCodec(
        codec: publishOptions.backupVideoCodec.codec.toLowerCase(),
        cid: '',
      ));
    }

    final layers = Utils.computeVideoLayers(
      dimensions,
      encodings,
      isSVC,
    );

    if (room.engine.isClosed) {
      throw UnexpectedConnectionState('cannot publish track when not connected');
    }

    logger.fine('Video layers: ${layers.map((e) => e)}');

    Future<lk_models.TrackInfo> negotiate() async {
      track.transceiver = await room.engine.createTransceiverRTCRtpSender(track, publishOptions!, encodings);

      track.codec = publishOptions.videoCodec;
      if (lkBrowser() != BrowserType.firefox) {
        await room.engine.setPreferredCodec(
          track.transceiver!,
          'video',
          publishOptions.videoCodec,
        );
      }

      if ([TrackSource.camera, TrackSource.screenShareVideo].contains(track.source)) {
        final degradationPreference = publishOptions.degradationPreference ??
            getDefaultDegradationPreference(
              track,
            );
        await track.setDegradationPreference(degradationPreference);
      }

      if (kIsWeb && lkBrowser() == BrowserType.firefox && track.kind == TrackType.AUDIO) {
        //TOOD:
      } else if (isSVCCodec(publishOptions.videoCodec) && encodings?.first.maxBitrate != null) {
        room.engine.publisher?.setTrackBitrateInfo(TrackBitrateInfo(
            cid: track.getCid(),
            transceiver: track.transceiver,
            codec: publishOptions.videoCodec,
            maxbr: encodings![0].maxBitrate! ~/ 1000));
      }

      await room.engine.negotiate();

      return lk_models.TrackInfo();
    }

    final req = lk_rtc.AddTrackRequest(
      cid: track.getCid(),
      name: publishOptions.name ??
          (track.source == TrackSource.screenShareVideo
              ? VideoPublishOptions.defaultScreenShareName
              : VideoPublishOptions.defaultCameraName),
      type: track.kind.toPBType(),
      source: track.source.toPBType(),
      encryption: room.roomOptions.lkEncryptionType,
      simulcastCodecs: simulcastCodecs,
      muted: track.muted,
      stream: buildStreamId(publishOptions, track.source),
    );

    // video specific
    if (dimensions.width > 0 && dimensions.height > 0) {
      req.width = dimensions.width;
      req.height = dimensions.height;
    }

    if (layers.isNotEmpty) {
      req.layers
        ..clear()
        ..addAll(layers);
    }
    late lk_models.TrackInfo trackInfo;
    if (room.engine.enabledPublishCodecs?.isNotEmpty ?? false) {
      final rets = await Future.wait<lk_models.TrackInfo>([room.engine.addTrack(req), negotiate()]);
      trackInfo = rets[0];
    } else {
      trackInfo = await room.engine.addTrack(req);

      String? primaryCodecMime;
      for (var codec in trackInfo.codecs) {
        primaryCodecMime ??= codec.mimeType;
      }

      if (primaryCodecMime != null) {
        final updatedCodec = mimeTypeToVideoCodecString(primaryCodecMime);
        if (updatedCodec != publishOptions.videoCodec) {
          logger.fine(
            'requested a different codec than specified by serverRequested: ${publishOptions.videoCodec}, server: ${updatedCodec}',
          );
          publishOptions = publishOptions.copyWith(
            videoCodec: updatedCodec,
          );
          // recompute encodings since bitrates/etc could have changed
          encodings = Utils.computeVideoEncodings(
            isScreenShare: track.source == TrackSource.screenShareVideo,
            dimensions: dimensions,
            options: publishOptions,
            codec: publishOptions.videoCodec,
          );
        }
      }

      final transceiverInit = rtc.RTCRtpTransceiverInit(
        direction: rtc.TransceiverDirection.SendOnly,
        sendEncodings: encodings,
      );

      logger.fine('publishVideoTrack publisher: ${room.engine.publisher}');

      track.transceiver = await room.engine.publisher?.pc.addTransceiver(
        track: track.mediaStreamTrack,
        kind: rtc.RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: transceiverInit,
      );

      track.codec = publishOptions.videoCodec;
      if (lkBrowser() != BrowserType.firefox) {
        await room.engine.setPreferredCodec(
          track.transceiver!,
          'video',
          publishOptions.videoCodec,
        );
      }

      if ([TrackSource.camera, TrackSource.screenShareVideo].contains(track.source)) {
        final degradationPreference = publishOptions.degradationPreference ??
            getDefaultDegradationPreference(
              track,
            );
        await track.setDegradationPreference(degradationPreference);
      }

      if (kIsWeb && lkBrowser() == BrowserType.firefox && track.kind == TrackType.AUDIO) {
        //TOOD:
      } else if (isSVCCodec(publishOptions.videoCodec) && encodings?.first.maxBitrate != null) {
        room.engine.publisher?.setTrackBitrateInfo(TrackBitrateInfo(
            cid: track.getCid(),
            transceiver: track.transceiver,
            codec: publishOptions.videoCodec,
            maxbr: encodings![0].maxBitrate! ~/ 1000));
      }

      await room.engine.negotiate();
    }

    logger.fine('publishVideoTrack engine.addTrack response: ${trackInfo}');

    track.lastPublishOptions = publishOptions;

    await track.start();

    final pub = LocalTrackPublication<LocalVideoTrack>(
      participant: this,
      info: trackInfo,
      track: track,
    );
    addTrackPublication(pub);
    pub.backupVideoCodec = publishOptions.backupVideoCodec;

    // did publish
    await track.onPublish();
    await track.processor?.onPublish(room);

    final listener = track.createListener();
    listener.on((TrackEndedEvent event) async {
      logger.fine('TrackEndedEvent: ${event.track}');
      await removePublishedTrack(pub.sid);
    });

    [events, room.events].emit(LocalTrackPublishedEvent(
      participant: this,
      publication: pub,
    ));

    return pub;
  }

  Future<void> removePublishedTrack(String trackSid, {bool notify = true}) async {
    logger.finer('Unpublish track sid: $trackSid, notify: $notify');
    final pub = trackPublications.remove(trackSid);
    if (pub == null) {
      logger.warning('Publication not found $trackSid');
      return;
    }
    await pub.dispose();

    final track = pub.track;
    if (track != null) {
      if (room.roomOptions.stopLocalTrackOnUnpublish) {
        await track.stop();
      }

      final sender = track.transceiver?.sender;
      if (sender != null) {
        try {
          await room.engine.publisher?.pc.removeTrack(sender);
          if (track is LocalVideoTrack) {
            track.simulcastCodecs.forEach((key, simulcastTrack) async {
              await room.engine.publisher?.pc.removeTrack(simulcastTrack.sender!);
            });
          }
        } catch (e) {
          logger.warning('[$objectId] rtc.removeTrack() did throw $e');
        }

        // doesn't make sense to negotiate if already disposed
        if (!isDisposed) {
          // manual negotiation since track changed
          await room.engine.negotiate();
        }
      }

      // did unpublish
      await track.onUnpublish();

      if (track.processor != null) {
        await track.processor?.onUnpublish();
        await track.stopProcessor();
      }

      await room.applyAudioSpeakerSettings();
    }

    if (notify) {
      [events, room.events].emit(LocalTrackUnpublishedEvent(
        participant: this,
        publication: pub,
      ));
    }

    await pub.dispose();
  }

  DegradationPreference getDefaultDegradationPreference(LocalVideoTrack track) {
    // a few of reasons we have different default paths:
    // 1. without this, Chrome seems to aggressively resize the SVC video stating `quality-limitation: bandwidth` even when BW isn't an issue
    // 2. since we are overriding contentHint to motion (to workaround L1T3 publishing), it overrides the default degradationPreference to `balanced`
    final VideoDimensions dimensions = track.currentOptions.params.dimensions;
    if (track.source == TrackSource.screenShareVideo || dimensions.height >= 1080) {
      return DegradationPreference.maintainResolution;
    }
    return DegradationPreference.balanced;
  }

  /// Convenience method to unpublish all tracks.
  Future<void> unpublishAllTracks({bool notify = true, bool? stopOnUnpublish}) async {
    final trackSids = trackPublications.keys.toSet();
    for (final trackid in trackSids) {
      await removePublishedTrack(trackid, notify: notify);
    }
  }

  Future<void> rePublishAllTracks() async {
    final tracks = trackPublications.values.toList();
    trackPublications.clear();
    for (LocalTrackPublication track in tracks) {
      if (track.track is LocalAudioTrack) {
        await publishAudioTrack(track.track as LocalAudioTrack);
      } else if (track.track is LocalVideoTrack) {
        await publishVideoTrack(track.track as LocalVideoTrack);
      }
    }
  }

  /// Publish a new data payload to the room.
  /// @param reliable, when true, data will be sent reliably.
  /// @param destinationIdentities When empty, data will be forwarded to each participant in the room.
  /// @param topic, the topic under which the message gets published.
  Future<void> publishData(
    List<int> data, {
    bool? reliable,
    List<String>? destinationIdentities,
    String? topic,
  }) async {
    final publishReliably = reliable == true;
    final packet = lk_models.DataPacket(
      kind: publishReliably ? lk_models.DataPacket_Kind.RELIABLE : lk_models.DataPacket_Kind.LOSSY,
      user: lk_models.UserPacket(
        payload: data,
        participantIdentity: identity,
        destinationIdentities: destinationIdentities,
        topic: topic,
      ),
    );

    await room.engine.sendDataPacket(packet, reliability: publishReliably ? Reliability.reliable : Reliability.lossy);
  }

  /// Sets and updates the metadata of the local participant.
  /// Note: this requires `CanUpdateOwnMetadata` permission encoded in the token.
  /// @param metadata
  Future<void> setMetadata(String metadata) {
    final requestId = room.engine.signalClient.sendUpdateLocalMetadata(
      lk_rtc.UpdateParticipantMetadata(
        name: name,
        metadata: metadata,
      ),
    );
    return _waitForRequestResponse(requestId);
  }

  /// Sets and updates the attributes of the local participant.
  /// @attributes key-value pairs to set
  Future<void> setAttributes(Map<String, String> attributes) {
    final requestId = room.engine.signalClient.sendUpdateLocalMetadata(
      lk_rtc.UpdateParticipantMetadata(
        name: name,
        metadata: metadata,
        attributes: attributes.entries,
      ),
    );
    return _waitForRequestResponse(requestId);
  }

  /// Sets and updates the name of the local participant.
  ///  Note: this requires `CanUpdateOwnMetadata` permission encoded in the token.
  ///  @param name
  Future<void> setName(String name) {
    final requestId = room.engine.signalClient.sendUpdateLocalMetadata(
      lk_rtc.UpdateParticipantMetadata(
        name: name,
        metadata: metadata,
      ),
    );
    return _waitForRequestResponse(requestId);
  }

  Future<void> _waitForRequestResponse(int requestId) {
    final completer = Completer<void>();
    _pendingSignalRequests[requestId] = completer;
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _pendingSignalRequests.remove(requestId);
        throw TimeoutException('Signal request timed out');
      },
    );
  }

  @internal
  void handleSignalRequestResponse(lk_rtc.RequestResponse response) {
    final completer = _pendingSignalRequests.remove(response.requestId);
    if (completer != null && !completer.isCompleted) {
      if (response.reason != lk_rtc.RequestResponse_Reason.OK) {
        completer.completeError(
          UnexpectedStateException('Signal request failed: ${response.reason} - ${response.message}'),
        );
      } else {
        completer.complete();
      }
    }
  }

  /// A convenience property to get all video tracks.
  @override
  List<LocalTrackPublication<LocalVideoTrack>> get videoTrackPublications =>
      trackPublications.values.whereType<LocalTrackPublication<LocalVideoTrack>>().toList();

  /// A convenience property to get all audio tracks.
  @override
  List<LocalTrackPublication<LocalAudioTrack>> get audioTrackPublications =>
      trackPublications.values.whereType<LocalTrackPublication<LocalAudioTrack>>().toList();

  @override
  LocalTrackPublication? getTrackPublicationByName(String name) {
    final track = super.getTrackPublicationByName(name);
    if (track != null) {
      return track;
    }
    return null;
  }

  @override
  LocalTrackPublication? getTrackPublicationBySid(String sid) {
    final track = super.getTrackPublicationBySid(sid);
    if (track != null) {
      return track;
    }
    return null;
  }

  @override
  LocalTrackPublication? getTrackPublicationBySource(TrackSource source) {
    final track = super.getTrackPublicationBySource(source);
    if (track != null) {
      return track;
    }
    return null;
  }

  /// Shortcut for publishing a [TrackSource.camera]
  Future<LocalTrackPublication?> setCameraEnabled(bool enabled, {CameraCaptureOptions? cameraCaptureOptions}) async {
    cameraCaptureOptions ??= room.roomOptions.defaultCameraCaptureOptions;
    return setSourceEnabled(TrackSource.camera, enabled, cameraCaptureOptions: cameraCaptureOptions);
  }

  /// Shortcut for publishing a [TrackSource.microphone]
  Future<LocalTrackPublication?> setMicrophoneEnabled(bool enabled, {AudioCaptureOptions? audioCaptureOptions}) async {
    audioCaptureOptions ??= room.roomOptions.defaultAudioCaptureOptions;
    return setSourceEnabled(TrackSource.microphone, enabled, audioCaptureOptions: audioCaptureOptions);
  }

  /// Shortcut for publishing a [TrackSource.screenShareVideo]
  Future<LocalTrackPublication?> setScreenShareEnabled(bool enabled,
      {bool? captureScreenAudio, ScreenShareCaptureOptions? screenShareCaptureOptions}) async {
    screenShareCaptureOptions ??= room.roomOptions.defaultScreenShareCaptureOptions;
    return setSourceEnabled(TrackSource.screenShareVideo, enabled,
        captureScreenAudio: captureScreenAudio, screenShareCaptureOptions: screenShareCaptureOptions);
  }

  /// A convenience method to publish a track for a specific [TrackSource].
  /// This is the recommended method to publish tracks.
  Future<LocalTrackPublication?> setSourceEnabled(TrackSource source, bool enabled,
      {bool? captureScreenAudio,
      AudioCaptureOptions? audioCaptureOptions,
      CameraCaptureOptions? cameraCaptureOptions,
      ScreenShareCaptureOptions? screenShareCaptureOptions}) {
    return _publishRunner.run(() async {
      if (TrackSource.screenShareVideo == source && lkPlatformIsWebMobile()) {
        throw TrackCreateException('Screen sharing is not supported on mobile devices');
      }

      logger.fine('setSourceEnabled(source: $source, enabled: $enabled)');

      final publication = getTrackPublicationBySource(source);
      if (publication != null) {
        final stopOnMute = switch (publication.source) {
          TrackSource.camera => cameraCaptureOptions?.stopCameraCaptureOnMute ?? true,
          TrackSource.microphone => audioCaptureOptions?.stopAudioCaptureOnMute ?? true,
          _ => true,
        };
        if (enabled) {
          await publication.unmute(stopOnMute: stopOnMute);
        } else {
          if (source == TrackSource.screenShareVideo) {
            await removePublishedTrack(publication.sid);
            final screenAudio = getTrackPublicationBySource(TrackSource.screenShareAudio);
            if (screenAudio != null) {
              await removePublishedTrack(screenAudio.sid);
            }
          } else {
            await publication.mute(stopOnMute: stopOnMute);
          }
        }
        return publication;
      } else if (enabled) {
        if (source == TrackSource.camera) {
          final CameraCaptureOptions captureOptions =
              cameraCaptureOptions ?? room.roomOptions.defaultCameraCaptureOptions;
          final track = await LocalVideoTrack.createCameraTrack(captureOptions);
          return await _publishVideoTrack(track);
        } else if (source == TrackSource.microphone) {
          final AudioCaptureOptions captureOptions = audioCaptureOptions ?? room.roomOptions.defaultAudioCaptureOptions;
          final track = await LocalAudioTrack.create(captureOptions);
          return await _publishAudioTrack(track);
        } else if (source == TrackSource.screenShareVideo) {
          ScreenShareCaptureOptions captureOptions =
              screenShareCaptureOptions ?? room.roomOptions.defaultScreenShareCaptureOptions;

          if (lkPlatformIs(PlatformType.iOS) && !BroadcastManager().isBroadcasting) {
            // Wait until broadcasting to publish track
            await BroadcastManager().requestActivation();
            return null;
          }

          /// When capturing chrome table audio, we can't capture audio/video
          /// track separately, it has to be returned once in getDisplayMedia,
          /// so we publish it twice here, but only return videoTrack to user.
          if (captureScreenAudio ?? false) {
            captureOptions = captureOptions.copyWith(captureScreenAudio: true);
            final tracks = await LocalVideoTrack.createScreenShareTracksWithAudio(captureOptions);
            LocalTrackPublication<LocalVideoTrack>? publication;
            for (final track in tracks) {
              if (track is LocalVideoTrack) {
                publication = await _publishVideoTrack(track);
              } else if (track is LocalAudioTrack) {
                await _publishAudioTrack(track);
              }
            }

            /// just return the video track publication
            return publication;
          }
          final track = await LocalVideoTrack.createScreenShareTrack(captureOptions);
          return await _publishVideoTrack(track);
        }
      }
      return null;
    });
  }

  bool _allParticipantsAllowed = true;
  List<ParticipantTrackPermission> _participantTrackPermissions = [];

  /// Control who can subscribe to LocalParticipant's published tracks.
  ///
  /// By default, all participants can subscribe. This allows fine-grained control over
  /// who is able to subscribe at a participant and track level.
  ///
  /// Note: if access is given at a track-level (i.e. both [allParticipantsAllowed] and
  /// [ParticipantTrackPermission.allTracksAllowed] are false), any newer published tracks
  /// will not grant permissions to any participants and will require a subsequent
  /// permissions update to allow subscription.
  ///
  /// [allParticipantsAllowed] Allows all participants to subscribe all tracks.
  /// Takes precedence over [trackPermissions] if set to true.
  /// By default this is set to true.
  ///
  /// [trackPermissions] Full list of individual permissions per
  /// participant/track. Any omitted participants will not receive any permissions.

  void setTrackSubscriptionPermissions({
    required bool allParticipantsAllowed,
    List<ParticipantTrackPermission> trackPermissions = const [],
  }) {
    _allParticipantsAllowed = allParticipantsAllowed;
    _participantTrackPermissions = trackPermissions;
    sendTrackSubscriptionPermissions();
  }

  void sendTrackSubscriptionPermissions() {
    if (room.engine.connectionState != ConnectionState.connected) {
      return;
    }
    room.engine.signalClient.sendUpdateSubscriptionPermissions(
      allParticipants: _allParticipantsAllowed,
      trackPermissions: _participantTrackPermissions.map((e) => e.toPBType()).toList(),
    );
  }

  @internal
  Iterable<lk_rtc.TrackPublishedResponse> publishedTracksInfo() =>
      trackPublications.values.map((e) => e.toPBTrackPublishedResponse());

  @internal
  @override
  ParticipantPermissions? setPermissions(ParticipantPermissions newValue) {
    final oldValue = super.setPermissions(newValue);
    if (oldValue != null) {
      // notify
      [events, room.events].emit(ParticipantPermissionsUpdatedEvent(
        participant: this,
        permissions: newValue,
        oldPermissions: oldValue,
      ));
    }
    return oldValue;
  }

  Future<void> publishAdditionalCodecForPublication(
    LocalTrackPublication publication,
    String backupCodec,
  ) async {
    if (publication.track is! LocalVideoTrack) {
      throw Exception('multi-codec simulcast is supported only for video');
    }
    final track = publication.track as LocalVideoTrack;

    final backupCodecOpts = publication.backupVideoCodec;
    if (backupCodecOpts == null) {
      throw Exception('backupCodec settings not specified');
    }

    var options = room.roomOptions.defaultVideoPublishOptions;
    options = options.copyWith(simulcast: backupCodecOpts.simulcast);

    if (backupCodec.toLowerCase() == publication.track?.codec?.toLowerCase()) {
      // not needed, same codec already published
      return;
    }

    if (backupCodec != backupCodecOpts.codec.toLowerCase()) {
      logger.warning(
        'requested a different codec than specified as backup serverRequested: ${backupCodec}, backup: ${backupCodecOpts.codec}',
      );
    }

    final encodings = Utils.computeTrackBackupEncodings(track, backupCodecOpts);
    if (encodings == null) {
      logger.fine('backup codec has been disabled, ignoring request to add additional codec for track');
      return;
    }

    final simulcastTrack = track.addSimulcastTrack(backupCodec, encodings);
    final dimensions = track.currentOptions.params.dimensions;

    final layers = Utils.computeVideoLayers(dimensions, encodings, isSVCCodec(backupCodec));

    simulcastTrack.sender = await room.engine.createSimulcastTransceiverSender(
      track,
      simulcastTrack,
      encodings,
      publication,
      backupCodec,
    );

    final cid = simulcastTrack.sender!.senderId;

    final req = lk_rtc.AddTrackRequest(
      cid: cid,
      name: options.name ??
          (track.source == TrackSource.screenShareVideo
              ? VideoPublishOptions.defaultScreenShareName
              : VideoPublishOptions.defaultCameraName),
      type: track.kind.toPBType(),
      source: track.source.toPBType(),
      muted: track.muted,
      layers: layers,
      sid: publication.sid,
      simulcastCodecs: <lk_rtc.SimulcastCodec>[
        lk_rtc.SimulcastCodec(
          codec: backupCodec.toLowerCase(),
          cid: cid,
        ),
      ],
    );

    // video specific
    if (dimensions.width > 0 && dimensions.height > 0) {
      req.width = dimensions.width;
      req.height = dimensions.height;
    }

    final trackInfo = await room.engine.addTrack(req);

    await room.engine.negotiate();

    logger.info('published backupCodec $backupCodec for track ${track.sid}, track info ${trackInfo}');
  }
}

extension RPCMethods on LocalParticipant {
  @internal
  Future<void> publishRpcRequest({
    required String destinationIdentity,
    required String requestId,
    required String method,
    required String payload,
    required Duration responseTimeout,
    int? version,
  }) async {
    if (payload.length > kRpcMaxPayloadBytes) {
      throw RpcError.builtIn(RpcError.requestPayloadTooLarge);
    }

    if ((room.engine.serverInfo?.version.isNotEmpty ?? false) &&
        compareVersions(room.engine.serverInfo!.version, '1.8.0') < 0) {
      throw RpcError.builtIn(RpcError.unsupportedServer);
    }

    final packet = lk_models.DataPacket(
      kind: lk_models.DataPacket_Kind.RELIABLE,
      rpcRequest: lk_models.RpcRequest(
        id: requestId,
        method: method,
        payload: payload,
        responseTimeoutMs: responseTimeout.inMilliseconds,
        version: version ?? kRpcVesion,
      ),
      participantIdentity: identity,
      destinationIdentities: [destinationIdentity],
    );

    await room.engine.sendDataPacket(packet, reliability: Reliability.reliable);
  }

  @internal
  Future<void> publishRpcResponse({
    required String destinationIdentity,
    required String requestId,
    String? payload,
    lk_models.RpcError? error,
  }) async {
    final packet = lk_models.DataPacket(
      kind: lk_models.DataPacket_Kind.RELIABLE,
      rpcResponse: lk_models.RpcResponse(
        requestId: requestId,
        payload: error == null ? payload : null,
        error: error,
      ),
      destinationIdentities: [destinationIdentity],
      participantIdentity: identity,
    );

    await room.engine.sendDataPacket(packet, reliability: Reliability.reliable);
  }

  @internal
  Future<void> publishRpcAck({
    required String destinationIdentity,
    required String requestId,
  }) async {
    final packet = lk_models.DataPacket(
      kind: lk_models.DataPacket_Kind.RELIABLE,
      rpcAck: lk_models.RpcAck(
        requestId: requestId,
      ),
      destinationIdentities: [destinationIdentity],
      participantIdentity: identity,
    );

    await room.engine.sendDataPacket(packet, reliability: Reliability.reliable);
  }

  @internal
  void handleIncomingRpcAck(String requestId) {
    final handler = _pendingAcks[requestId];
    if (handler != null) {
      handler(requestId);
      _pendingAcks.remove(requestId);
    } else {
      logger.warning('Ack received for unexpected RPC request $requestId');
    }
  }

  @internal
  void handleIncomingRpcResponse(
    String requestId,
    String? payload,
    RpcError? error,
  ) {
    final handler = _pendingResponses[requestId];
    if (handler != null) {
      handler(payload, error);
      _pendingResponses.remove(requestId);
    } else {
      logger.warning('Response received for unexpected RPC request $requestId');
    }
  }

  @internal
  Future<void> handleIncomingRpcRequest(
    String callerIdentity,
    String requestId,
    String method,
    String payload,
    num responseTimeoutMs,
    num version,
  ) async {
    await publishRpcAck(
      destinationIdentity: callerIdentity,
      requestId: requestId,
    );

    RpcError? responseError;
    String? responsePayload;

    try {
      if (version != kRpcVesion) {
        await publishRpcResponse(
          destinationIdentity: callerIdentity,
          requestId: requestId,
          error: RpcError.builtIn(RpcError.unsupportedVersion).toProto(),
        );
        return;
      }

      final handler = room.rpcHandlers[method];
      if (handler == null) {
        await publishRpcResponse(
          destinationIdentity: callerIdentity,
          requestId: requestId,
          error: RpcError.builtIn(RpcError.unsupportedMethod).toProto(),
        );
        return;
      }

      final response = await handler(RpcInvocationData(
          requestId: requestId,
          callerIdentity: callerIdentity,
          payload: payload,
          responseTimeoutMs: responseTimeoutMs.toInt()));

      if (response.length > kRpcMaxPayloadBytes) {
        responseError = RpcError.builtIn(RpcError.responsePayloadTooLarge);
        logger.warning('RPC Response payload too large for $method');
      } else {
        responsePayload = response;
      }
    } catch (error) {
      if (error is RpcError) {
        responseError = error;
      } else {
        logger.warning(
            'Uncaught error returned by RPC handler for ${method}. Returning RpcError.applicationError instead. $error');
        responseError = RpcError(code: RpcError.applicationError, message: error.toString());
      }
    }

    await publishRpcResponse(
      destinationIdentity: callerIdentity,
      requestId: requestId,
      payload: responsePayload,
      error: responseError?.toProto(),
    );

    logger.fine('RPC request ${method} handled');
  }

  /// Initiate an RPC call to a remote participant.
  /// @param [params] - RPC call parameters.
  /// @returns A promise that resolves with the response payload or rejects with an error.
  /// @throws Error on failure. Details in `message`.
  Future<String> performRpc(PerformRpcParams params) async {
    final requestId = Uuid().v4();
    final completer = Completer<String>();

    final maxRoundTripLatency = Duration(seconds: 7);
    final minEffectiveTimeout = const Duration(milliseconds: 1000);

    try {
      final effectiveTimeout = Duration(
        milliseconds: (params.responseTimeoutMs.inMilliseconds - maxRoundTripLatency.inMilliseconds)
            .clamp(minEffectiveTimeout.inMilliseconds, double.infinity)
            .toInt(),
      );
      await publishRpcRequest(
        destinationIdentity: params.destinationIdentity,
        requestId: requestId,
        method: params.method,
        payload: params.payload,
        responseTimeout: effectiveTimeout,
        version: kRpcVesion,
      );

      final ackTimer = Timer(maxRoundTripLatency, () {
        completer.completeError(RpcError.builtIn(RpcError.connectionTimeout));
        _pendingResponses.remove(requestId);
      });

      _pendingAcks[requestId] = (id) {
        ackTimer.cancel();
      };

      final responseTimer = Timer(params.responseTimeoutMs, () {
        completer.completeError(RpcError.builtIn(RpcError.responseTimeout));
        _pendingResponses.remove(requestId);
      });

      _pendingResponses[requestId] = (String? response, RpcError? error) {
        responseTimer.cancel();
        if (error != null) {
          completer.completeError(error);
        } else {
          completer.complete(response!);
        }
        ackTimer.cancel();
        _pendingAcks.remove(requestId);
      };
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }

    return completer.future;
  }
}

extension DataStreamParticipantMethods on LocalParticipant {
  Future<TextStreamInfo> sendText(String text, {SendTextOptions? options}) async {
    final streamId = Uuid().v4();
    final textInBytes = text.codeUnits;
    final totalTextLength = textInBytes.length;

    final fileIds = options?.attachments.map((f) => Uuid().v4()).toList();
    var len = 0;
    if (fileIds != null && fileIds.isNotEmpty) {
      len = fileIds.length + 1;
    } else {
      len = 1;
    }
    final progresses = List<num>.filled(len, 0);

    handleProgress(num progress, int idx) {
      progresses[idx] = progress;
      final totalProgress = progresses.reduce((acc, val) => acc + val);
      options?.onProgress?.call(totalProgress.toDouble() / len);
    }

    final writer = await streamText(StreamTextOptions(
      streamId: streamId,
      totalSize: totalTextLength,
      destinationIdentities: options?.destinationIdentities ?? [],
      topic: options?.topic,
      attachedStreamIds: fileIds ?? [],
      attributes: options?.attributes ?? {},
    ));

    await writer.write(text);
    // set text part of progress to 1
    handleProgress(1, 0);

    await writer.close();

    if (options?.attachments != null) {
      var idx = 0;
      await Future.wait<void>(
        options?.attachments.map(
              (file) {
                final curIdx = idx++;
                return _sendFile(
                  fileIds![curIdx],
                  file,
                  SendFileOptions(
                      topic: options.topic,
                      mimeType: mime(basename(file.path)),
                      onProgress: (progress) {
                        handleProgress(progress, curIdx + 1);
                      }),
                );
              },
            ).toList() ??
            [],
      );
    }
    return writer.info;
  }

  Future<TextStreamWriter> streamText(StreamTextOptions? options) async {
    final streamId = options?.streamId ?? Uuid().v4();
    final timestamp = DateTime.timestamp().millisecondsSinceEpoch;

    final info = TextStreamInfo(
      id: streamId,
      mimeType: 'text/plain',
      timestamp: timestamp,
      topic: options?.topic ?? '',
      size: options?.totalSize ?? 0,
      replyToStreamId: options?.replyToStreamId,
      attachedStreamIds: options?.attachedStreamIds ?? [],
      version: options?.version,
      generated: options?.generated ?? false,
      operationType: options?.type,
      sendingParticipantIdentity: identity,
    );

    final header = lk_models.DataStream_Header(
      streamId: streamId,
      mimeType: info.mimeType,
      topic: info.topic,
      timestamp: Int64(timestamp),
      totalLength: Int64(options?.totalSize ?? 0),
      attributes: options?.attributes.entries,
      textHeader: lk_models.DataStream_TextHeader(
        version: options?.version,
        attachedStreamIds: options?.attachedStreamIds,
        replyToStreamId: options?.replyToStreamId,
        generated: options?.generated ?? false,
        operationType: options?.type?.toPBType(),
      ),
    );

    final destinationIdentities = options?.destinationIdentities;
    final packet = lk_models.DataPacket(
      kind: lk_models.DataPacket_Kind.RELIABLE,
      destinationIdentities: destinationIdentities,
      streamHeader: header,
    );
    await room.engine.sendDataPacket(packet, reliability: Reliability.reliable);

    final writableStream =
        WritableStream<String>(destinationIdentities: destinationIdentities!, engine: room.engine, streamId: streamId);

    onEngineClose() async {
      await writableStream.close();
    }

    final cancelFun = room.engine.events.once<EngineClosingEvent>((_) => onEngineClose);

    final writer = TextStreamWriter(writableStream: writableStream, info: info, onClose: cancelFun);

    return writer;
  }

  Future<Map<String, String>> sendFile(
    File file, {
    required SendFileOptions options,
  }) async {
    final streamId = Uuid().v4();
    await _sendFile(streamId, file, options);
    return {'id': streamId};
  }

  Future<void> _sendFile(
    String streamId,
    File file,
    SendFileOptions options,
  ) async {
    final totalLength = await file.length();

    final streamBytesOptions = StreamBytesOptions(
      streamId: streamId,
      totalSize: totalLength,
      topic: options.topic,
      mimeType: options.mimeType ?? mime(basename(file.path)),
      name: basename(file.path),
      destinationIdentities: options.destinationIdentities,
      encryptionType: options.encryptionType,
    );

    final writer = await streamBytes(streamBytesOptions);

    final reader = ChunkedStreamReader(file.openRead());

    final totalChunks = (totalLength / kStreamChunkSize).ceil();
    for (var i = 0; i < totalChunks; i++) {
      final chunkData = await reader.readBytes(min((i + 1) * kStreamChunkSize, kStreamChunkSize));
      await writer.write(chunkData);
      options.onProgress?.call((i + 1) / totalChunks);
    }
    await writer.close();
  }

  Future<ByteStreamWriter> streamBytes(StreamBytesOptions? options) async {
    final streamId = options?.streamId ?? Uuid().v4();
    final timestamp = DateTime.timestamp().millisecondsSinceEpoch;

    final info = ByteStreamInfo(
      name: options?.name ?? 'unknown',
      id: streamId,
      mimeType: options?.mimeType ?? 'application/octet-stream',
      timestamp: timestamp,
      topic: options?.topic ?? '',
      size: options?.totalSize ?? 0,
      attributes: options?.attributes ?? {},
      sendingParticipantIdentity: identity,
    );

    final header = lk_models.DataStream_Header(
      totalLength: Int64(info.size),
      mimeType: info.mimeType,
      streamId: streamId,
      topic: options?.topic,
      encryptionType: options?.encryptionType,
      timestamp: Int64(timestamp),
      byteHeader: lk_models.DataStream_ByteHeader(
        name: info.name,
      ),
      attributes: options?.attributes.entries,
    );

    final destinationIdentities = options?.destinationIdentities;
    final packet = lk_models.DataPacket(
      kind: lk_models.DataPacket_Kind.RELIABLE,
      destinationIdentities: destinationIdentities,
      streamHeader: header,
    );

    await room.engine.sendDataPacket(packet, reliability: Reliability.reliable);

    final writableStream = WritableStream<Uint8List>(
      destinationIdentities: destinationIdentities,
      streamId: streamId,
      engine: room.engine,
    );

    onEngineClose() async {
      await writableStream.close();
    }

    final cancelFun = room.engine.events.once<EngineClosingEvent>((_) => onEngineClose);

    final byteWriter = ByteStreamWriter(
      writableStream: writableStream,
      info: info,
      onClose: cancelFun,
    );

    return byteWriter;
  }
}
