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

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../core/room.dart';
import '../events.dart';
import '../exceptions.dart';
import '../extensions.dart';
import '../internal/events.dart';
import '../logger.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../publication/remote.dart';
import '../support/platform.dart';
import '../track/options.dart';
import '../track/remote/audio.dart';
import '../track/remote/remote.dart';
import '../track/remote/video.dart';
import '../types/other.dart';
import 'participant.dart';

/// Result of creating a RemoteParticipant with all its initial data populated.
///
/// This struct is returned by [RemoteParticipant.createFromInfo] and contains
/// the fully initialized participant along with the list of track publications
/// that were added during creation. The caller is responsible for emitting
/// events in the correct order.
@internal
class ParticipantCreationResult {
  /// The fully initialized remote participant with all basic info and tracks populated.
  final RemoteParticipant participant;

  /// List of new track publications that were added during participant creation.
  /// The caller should emit [TrackPublishedEvent] for each of these after
  /// emitting [ParticipantConnectedEvent].
  final List<RemoteTrackPublication> newPublications;

  const ParticipantCreationResult({
    required this.participant,
    required this.newPublications,
  });
}

/// Represents other participant in the [Room].
class RemoteParticipant extends Participant<RemoteTrackPublication> {
  RemoteParticipant._({
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

  /// Creates a fully initialized RemoteParticipant without emitting events.
  ///
  /// Populates the participant with all data from [info] including metadata, permissions,
  /// and track publications. No events are emitted, allowing the caller to control event
  /// timing and order.
  ///
  /// Returns [ParticipantCreationResult] with the participant and new track publications.
  /// The caller should emit [ParticipantConnectedEvent] first, then [TrackPublishedEvent]
  /// for each track, ensuring the participant is fully populated when connected event fires.
  ///
  /// @internal - Should only be called by [Room].
  @internal
  static Future<ParticipantCreationResult> createFromInfo({
    required Room room,
    required lk_models.ParticipantInfo info,
  }) async {
    final participant = RemoteParticipant._(
      room: room,
      sid: info.sid,
      identity: info.identity,
      name: info.name,
    );
    // Update basic participant info (state, metadata, etc.)
    await participant._updateBasicInfo(info);
    // Add tracks to participant without emitting events
    final newPubs = await participant._addTracks(info.tracks);
    // Return result for caller to emit events in correct order
    return ParticipantCreationResult(
      participant: participant,
      newPublications: newPubs,
    );
  }

  Future<void> _updateBasicInfo(lk_models.ParticipantInfo info) async {
    // Only call superclass updateFromInfo to update basic participant state
    await super.updateFromInfo(info);
  }

  Future<List<RemoteTrackPublication>> _addTracks(List<lk_models.TrackInfo> tracks) async {
    final newPubs = <RemoteTrackPublication>[];
    for (final trackInfo in tracks) {
      final RemoteTrackPublication? pub = getTrackPublicationBySid(trackInfo.sid);
      if (pub == null) {
        final RemoteTrackPublication pub;
        if (trackInfo.type == lk_models.TrackType.VIDEO) {
          pub = RemoteTrackPublication<RemoteVideoTrack>(
            participant: this,
            info: trackInfo,
          );
        } else if (trackInfo.type == lk_models.TrackType.AUDIO) {
          pub = RemoteTrackPublication<RemoteAudioTrack>(
            participant: this,
            info: trackInfo,
          );
        } else {
          throw UnexpectedStateException('Unknown track type');
        }
        newPubs.add(pub);
        addTrackPublication(pub);
      } else {
        pub.updateFromInfo(trackInfo);
      }
    }
    return newPubs;
  }

  /// A convenience property to get all video tracks.
  @override
  List<RemoteTrackPublication<RemoteVideoTrack>> get videoTrackPublications =>
      trackPublications.values.whereType<RemoteTrackPublication<RemoteVideoTrack>>().toList();

  /// A convenience property to get all audio tracks.
  @override
  List<RemoteTrackPublication<RemoteAudioTrack>> get audioTrackPublications =>
      trackPublications.values.whereType<RemoteTrackPublication<RemoteAudioTrack>>().toList();

  List<RemoteTrackPublication> get subscribedTracks =>
      trackPublications.values.where((e) => e.subscribed).cast<RemoteTrackPublication>().toList();

  @override
  RemoteTrackPublication? getTrackPublicationByName(String name) {
    final track = super.getTrackPublicationByName(name);
    if (track != null) {
      return track;
    }
    return null;
  }

  @override
  RemoteTrackPublication? getTrackPublicationBySid(String sid) {
    final track = super.getTrackPublicationBySid(sid);
    if (track != null) {
      return track;
    }
    return null;
  }

  @override
  RemoteTrackPublication? getTrackPublicationBySource(TrackSource source) {
    final track = super.getTrackPublicationBySource(source);
    if (track != null) {
      return track;
    }
    return null;
  }

  @internal
  Future<void> addSubscribedMediaTrack(
    rtc.MediaStreamTrack mediaTrack,
    rtc.MediaStream stream,
    String trackSid, {
    rtc.RTCRtpReceiver? receiver,
    AudioOutputOptions audioOutputOptions = const AudioOutputOptions(),
  }) async {
    logger.fine('addSubscribedMediaTrack()');

    // If publication doesn't exist yet...
    RemoteTrackPublication? pub = getTrackPublicationBySid(trackSid);
    if (pub == null) {
      logger.fine('addSubscribedMediaTrack() pub is null, will wait...');
      logger.fine('addSubscribedMediaTrack() tracks: $trackPublications');
      // Wait for the metadata to arrive
      final event = await events.waitFor<TrackPublishedEvent>(
        filter: (event) => event.participant == this && event.publication.sid == trackSid,
        duration: room.connectOptions.timeouts.publish,
        onTimeout: () => throw TrackSubscriptionExceptionEvent(
          participant: this,
          sid: trackSid,
          reason: TrackSubscribeFailReason.notTrackMetadataFound,
        ),
      );
      pub = event.publication;
      logger.fine('addSubscribedMediaTrack() did receive pub');
    }

    // Check if track type is supported, throw if not.
    if (![lk_models.TrackType.AUDIO, lk_models.TrackType.VIDEO].contains(pub.kind.toPBType())) {
      throw TrackSubscriptionExceptionEvent(
        participant: this,
        sid: trackSid,
        reason: TrackSubscribeFailReason.unsupportedTrackType,
      );
    }

    // create Track
    final RemoteTrack track;
    if (pub.kind == TrackType.VIDEO) {
      // video track
      track = RemoteVideoTrack(pub.source, stream, mediaTrack, receiver: receiver);
    } else if (pub.kind == TrackType.AUDIO) {
      // audio track
      track = RemoteAudioTrack(pub.source, stream, mediaTrack, receiver: receiver);

      final listener = track.createListener();
      listener.on<AudioPlaybackStarted>((event) {
        logger.fine('AudioPlaybackStarted');
        room.engine.events.emit(event);
      });

      listener.on<AudioPlaybackFailed>((event) {
        logger.fine('AudioPlaybackFailed');
        room.engine.events.emit(event);
      });
    } else {
      throw UnexpectedStateException('Unknown track type');
    }

    /// Apply audio output selection for the web.
    if (pub.kind == TrackType.AUDIO && lkPlatformIs(PlatformType.web)) {
      if (audioOutputOptions.deviceId != null) {
        (track as RemoteAudioTrack).setSinkId(audioOutputOptions.deviceId!);
      }
    }

    await pub.updateTrack(track);
    await pub.updateSubscriptionAllowed(true);
    addTrackPublication(pub);

    [events, room.events].emit(TrackSubscribedEvent(
      participant: this,
      track: track,
      publication: pub,
    ));

    await track.start();
  }

  @override
  @internal
  Future<bool> updateFromInfo(lk_models.ParticipantInfo info) async {
    logger.fine('RemoteParticipant.updateFromInfo(info: $info)');
    if (!await super.updateFromInfo(info)) {
      //return false;
    }

    await _updateTracks(info.tracks);

    return true;
  }

  Future<void> _updateTracks(List<lk_models.TrackInfo> tracks) async {
    // Add new tracks
    final newPubs = await _addTracks(tracks);

    // Emit events for new publications
    for (final pub in newPubs) {
      final event = TrackPublishedEvent(
        participant: this,
        publication: pub,
      );
      if (room.connectionState == ConnectionState.connected) {
        [events, room.events].emit(event);
      }
    }

    // Remove any published track that is not in the info
    final validSids = tracks.map((e) => e.sid);
    final removeSids = trackPublications.keys.where((e) => !validSids.contains(e)).toSet();
    for (final sid in removeSids) {
      await removePublishedTrack(sid);
    }
  }

  Future<void> removePublishedTrack(String trackSid, {bool notify = true}) async {
    logger.finer('removePublishedTrack track sid: $trackSid, notify: $notify');
    final pub = trackPublications.remove(trackSid);
    if (pub == null) {
      logger.warning('Publication not found $trackSid');
      return;
    }
    await pub.dispose();

    final track = pub.track;
    // if has track
    if (track != null) {
      await track.stop();
      [events, room.events].emit(TrackUnsubscribedEvent(
        participant: this,
        track: track,
        publication: pub,
      ));
    }

    if (notify) {
      [events, room.events].emit(TrackUnpublishedEvent(
        participant: this,
        publication: pub,
      ));
    }

    await pub.dispose();
  }

  Future<void> removeAllPublishedTracks({bool notify = true}) async {
    final sids = trackPublications.keys.toList();
    for (final sid in sids) {
      await removePublishedTrack(sid, notify: notify);
    }
  }

  @internal
  lk_models.ParticipantTracks participantTracks() => lk_models.ParticipantTracks(
        participantSid: sid,
        trackSids: trackPublications.values.map((e) => e.sid),
      );
}
