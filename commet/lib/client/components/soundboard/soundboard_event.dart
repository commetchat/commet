// Versioned, typed soundboard trigger protocol.
//
// Transport: LiveKit data channel topic [livekitTopic] (reliable) with
// Matrix to-device fallback using the same envelope. NEVER timeline events.
// Identity: receivers MUST prefer the authenticated sender (LiveKit
// participant identity / Matrix sender) over [senderId] in the payload;
// [senderId] is a hint for debugging only.
import 'dart:convert';

import 'soundboard_constraints.dart';

class SoundboardEvent {
  static const String typePlay = 'soundboard.play';
  static const String livekitTopic = 'chat.commet.soundboard.v1';
  static const String toDeviceType = 'chat.commet.soundboard.play';
  static const int currentVersion = 1;

  final String type;
  final int version;
  final String soundId;
  final String senderId;
  final String eventId;
  final int timestampMs;

  const SoundboardEvent({
    this.type = typePlay,
    this.version = currentVersion,
    required this.soundId,
    required this.senderId,
    required this.eventId,
    required this.timestampMs,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'version': version,
        'sound_id': soundId,
        'sender_id': senderId,
        'event_id': eventId,
        'timestamp': timestampMs,
      };

  /// Parses unknown-future versions leniently: unknown fields ignored,
  /// unknown [type] rejected, version > current still accepted for
  /// forward-compat (caller only needs sound_id/event_id/timestamp).
  static SoundboardEvent? tryParse(Map<String, dynamic> json) {
    try {
      if (json['type'] != typePlay) return null;
      final soundId = json['sound_id'] as String?;
      final eventId = json['event_id'] as String?;
      final ts = json['timestamp'];
      if (soundId == null || soundId.isEmpty) return null;
      if (eventId == null || eventId.isEmpty) return null;
      if (ts is! num) return null;
      return SoundboardEvent(
        type: typePlay,
        version: (json['version'] as num?)?.toInt() ?? 1,
        soundId: soundId,
        senderId: (json['sender_id'] as String?) ?? '',
        eventId: eventId,
        timestampMs: ts.toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  static SoundboardEvent? tryParseBytes(List<int> bytes) {
    try {
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      return tryParse(json);
    } catch (_) {
      return null;
    }
  }

  List<int> encode() => utf8.encode(jsonEncode(toJson()));

  /// TTL check against [nowMs]. Drops stale (reconnect queue) and
  /// far-future (clock abuse) events.
  bool isFresh(int nowMs) {
    final age = nowMs - timestampMs;
    if (age < -SoundboardConstraints.maxFutureSkew.inMilliseconds) {
      return false;
    }
    return age <= SoundboardConstraints.eventTtl.inMilliseconds;
  }
}
