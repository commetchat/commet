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

  /// No sound: a sample of the sender's clock, sent on joining a call so
  /// receivers know how far it is from theirs (see SoundboardClocks).
  /// Clients that predate it drop it as an unknown type.
  static const String typeClock = 'soundboard.clock';
  static const String livekitTopic = 'chat.commet.soundboard.v1';
  static const String toDeviceType = 'chat.commet.soundboard.play';
  static const int currentVersion = 1;

  final String type;
  final int version;
  final String soundId;
  final String senderId;
  final String eventId;
  final int timestampMs;

  /// On a clock message: whether receivers should answer with their own, as
  /// the people already in a call do for someone joining.
  final bool wantsReply;

  const SoundboardEvent({
    this.type = typePlay,
    this.version = currentVersion,
    required this.soundId,
    required this.senderId,
    required this.eventId,
    required this.timestampMs,
    this.wantsReply = false,
  });

  const SoundboardEvent.clock({
    required this.senderId,
    required this.eventId,
    required this.timestampMs,
    this.wantsReply = false,
  })  : type = typeClock,
        version = currentVersion,
        soundId = '';

  bool get isClock => type == typeClock;

  Map<String, dynamic> toJson() => {
        'type': type,
        'version': version,
        if (!isClock) 'sound_id': soundId,
        'sender_id': senderId,
        'event_id': eventId,
        'timestamp': timestampMs,
        if (isClock) 'wants_reply': wantsReply,
      };

  /// Parses unknown-future versions leniently: unknown fields ignored,
  /// unknown [type] rejected, version > current still accepted for
  /// forward-compat (caller only needs sound_id/event_id/timestamp).
  static SoundboardEvent? tryParse(Map<String, dynamic> json) {
    try {
      final type = json['type'];
      if (type != typePlay && type != typeClock) return null;
      final soundId = json['sound_id'] as String?;
      final eventId = json['event_id'] as String?;
      final ts = json['timestamp'];
      if (type == typePlay && (soundId == null || soundId.isEmpty)) {
        return null;
      }
      if (eventId == null || eventId.isEmpty) return null;
      if (ts is! num) return null;
      return SoundboardEvent(
        type: type as String,
        version: (json['version'] as num?)?.toInt() ?? 1,
        soundId: soundId ?? '',
        senderId: (json['sender_id'] as String?) ?? '',
        eventId: eventId,
        timestampMs: ts.toInt(),
        wantsReply: json['wants_reply'] == true,
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
  /// far-future (clock abuse) events. Trusts the sender's clock: only for a
  /// sender whose clock offset is unknown (see SoundboardClocks).
  bool isFresh(int nowMs) {
    final age = nowMs - timestampMs;
    if (age < -SoundboardConstraints.maxFutureSkew.inMilliseconds) {
      return false;
    }
    return age <= SoundboardConstraints.eventTtl.inMilliseconds;
  }
}
