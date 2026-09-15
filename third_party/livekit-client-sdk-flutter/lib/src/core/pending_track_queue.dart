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

import '../events.dart';
import '../logger.dart';
import '../types/other.dart';

typedef PendingTrackSubscriber = Future<bool> Function(PendingTrack entry);
typedef TrackExceptionEmitter = void Function(TrackSubscriptionExceptionEvent event);

/// Helper that queues subscriber tracks when participant metadata isn't ready yet.
@internal
class PendingTrackQueue {
  final int maxSize;
  Duration ttl;
  final TrackExceptionEmitter emitException;

  // keyed by participant sid
  final Map<String, List<PendingTrack>> _pending = {};

  PendingTrackQueue({
    required this.ttl,
    required this.emitException,
    this.maxSize = 100,
  });

  void updateTtl(Duration ttl) {
    this.ttl = ttl;
  }

  void clear() {
    _pending.clear();
  }

  void enqueue({
    required rtc.MediaStreamTrack track,
    required rtc.MediaStream stream,
    required rtc.RTCRtpReceiver? receiver,
    required String participantSid,
    required String trackSid,
    required ConnectionState connectionState,
  }) {
    // If we're already disconnected, drop immediately.
    if (connectionState == ConnectionState.disconnected) {
      final event = TrackSubscriptionExceptionEvent(
        participant: null,
        sid: trackSid,
        reason: TrackSubscribeFailReason.noParticipantFound,
      );
      logger.warning('Dropping pending track while disconnected trackSid:$trackSid participantSid:$participantSid');
      emitException(event);
      return;
    }

    _removeExpired();

    final totalPending = _pending.values.fold<int>(0, (sum, list) => sum + list.length);
    if (totalPending >= maxSize) {
      final event = TrackSubscriptionExceptionEvent(
        participant: null,
        sid: trackSid,
        reason: TrackSubscribeFailReason.noParticipantFound,
      );
      logger.severe('Pending track queue full, dropping trackSid:$trackSid participantSid:$participantSid');
      emitException(event);
      return;
    }

    final expiresAt = DateTime.now().add(ttl);
    logger.fine('Queueing pending trackSid:$trackSid participantSid:$participantSid until metadata is ready');
    final entry = PendingTrack(
      track: track,
      stream: stream,
      receiver: receiver,
      participantSid: participantSid,
      trackSid: trackSid,
      expiresAt: expiresAt,
    );
    final list = _pending.putIfAbsent(participantSid, () => []);
    list.add(entry);
  }

  @internal
  Future<void> flush({
    required bool isConnected,
    String? participantSid,
    required PendingTrackSubscriber subscriber,
  }) async {
    _removeExpired();
    if (!isConnected) return;

    final Iterable<PendingTrack> source = participantSid != null
        ? List<PendingTrack>.from(_pending[participantSid] ?? const [])
        : _pending.values.expand((e) => e).toList();

    for (final item in source) {
      final success = await subscriber(item);
      if (success) {
        _pending[item.participantSid]?.remove(item);
      }
    }
  }

  void _removeExpired() {
    final now = DateTime.now();
    _pending.forEach((sid, list) {
      final expired = list.where((p) => p.expiresAt.isBefore(now)).toList();
      for (final item in expired) {
        list.remove(item);
        final event = TrackSubscriptionExceptionEvent(
          participant: null,
          sid: item.trackSid,
          reason: TrackSubscribeFailReason.noParticipantFound,
        );
        logger.warning('Pending track expired waiting for participant metadata: $event');
        emitException(event);
      }
    });
  }
}

@internal
class PendingTrack {
  final rtc.MediaStreamTrack track;
  final rtc.MediaStream stream;
  final rtc.RTCRtpReceiver? receiver;
  final String participantSid;
  final String trackSid;
  final DateTime expiresAt;

  PendingTrack({
    required this.track,
    required this.stream,
    required this.receiver,
    required this.participantSid,
    required this.trackSid,
    required this.expiresAt,
  });
}
