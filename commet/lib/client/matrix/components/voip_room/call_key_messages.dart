// The to-device messages that carry media keys in an encrypted voice room,
// and who is in the call to send them to. Pure: the key provider
// (matrix_livekit_encryption_key_provider.dart) does the Matrix side.
import 'dart:convert';
import 'dart:typed_data';

import 'package:commet/client/matrix/components/voip_room/call_key_distributor.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_call_membership.dart';
import 'package:commet/debug/log.dart';

/// Carries a participant's media key (Element Call's format).
const callKeysEventType = "io.element.call.encryption_keys";

/// Asks a participant for its media key: we cannot decrypt it. Clients that
/// do not know it ignore it.
const callKeyRequestEventType = "io.roscord.call.encryption_keys_request";

/// The call a voice room holds, as its memberships name it.
const _application = "m.call";
const _callId = "";

/// The devices in the call according to [state] (the room's call member
/// state events), without this device, each with when it joined: live,
/// non-empty memberships of the room's call only.
Map<CallMember, DateTime?> callMembersFromState(
  Iterable<({String sender, Map<String, dynamic> content, DateTime? sentAt})>
      state, {
  required String ownUserId,
  required String ownDeviceId,
  required DateTime now,
}) {
  final members = <CallMember, DateTime?>{};
  for (final entry in state) {
    final content = entry.content;
    if (content.isEmpty) continue;
    if (content["application"] != _application) continue;
    if (content["call_id"] != _callId) continue;
    final device = content["device_id"];
    if (device is! String || device.isEmpty) continue;
    if (entry.sender == ownUserId && device == ownDeviceId) continue;
    if (MatrixCallMembership.isExpired(content, entry.sentAt, now)) continue;
    members[CallMember(entry.sender, device)] =
        MatrixCallMembership.joinedAt(content, entry.sentAt);
  }
  return members;
}

/// The content of a key message from us.
Map<String, dynamic> callKeyContent({
  required String roomId,
  required String ownDeviceId,
  required int index,
  required Uint8List key,
  required DateTime now,
}) =>
    {
      "keys": {"index": index, "key": base64Encode(key)},
      "member": {"claimed_device_id": ownDeviceId},
      "room_id": roomId,
      "sent_ts": now.millisecondsSinceEpoch,
      "session": {
        "application": _application,
        "call_id": _callId,
        "scope": "m.room",
      },
    };

/// The content of a request for someone's key.
Map<String, dynamic> callKeyRequestContent(
        {required String roomId, required String ownDeviceId}) =>
    {
      "member": {"claimed_device_id": ownDeviceId},
      "room_id": roomId,
      "session": {
        "application": _application,
        "call_id": _callId,
        "scope": "m.room",
      },
    };

/// A to-device message about this room's call, as it arrived.
class CallToDevice {
  const CallToDevice({
    required this.type,
    required this.sender,
    required this.content,
    required this.encrypted,
    this.senderKey,
  });

  final String type;
  final String sender;
  final Map<String, dynamic> content;

  /// It came olm-encrypted: nobody but the sender's device wrote it.
  final bool encrypted;

  /// The curve25519 key of the device that encrypted it.
  final String? senderKey;
}

/// A validated key message.
class CallKeyMessage {
  const CallKeyMessage(this.from, this.index, this.key, this.sentTs);

  final CallMember from;
  final int index;
  final Uint8List key;
  final int? sentTs;

  /// The key in [message] if it is one for [roomId]'s call, null otherwise:
  /// not encrypted, another room's or another call's, a malformed one, or
  /// one whose device is not the one that encrypted it
  /// ([deviceCurve25519] is what we know of the claimed device's key).
  static CallKeyMessage? parse(
    CallToDevice message, {
    required String roomId,
    String? Function(CallMember member)? deviceCurve25519,
  }) {
    if (message.type != callKeysEventType) return null;
    final from = _checkedSender(message, roomId, deviceCurve25519);
    if (from == null) return null;
    final keys = message.content["keys"];
    // Element Call has sent a list of keys, we send one.
    final entry = keys is List ? keys.firstOrNull : keys;
    if (entry is! Map) return null;
    final index = entry["index"];
    final encoded = entry["key"];
    if (index is! int || index < 0 || index > 255) return null;
    if (encoded is! String) return null;
    final Uint8List key;
    try {
      key = base64Decode(encoded);
    } on FormatException {
      return null;
    }
    if (key.isEmpty || key.length > 64) return null;
    final sentTs = message.content["sent_ts"];
    return CallKeyMessage(from, index, key, sentTs is int ? sentTs : null);
  }
}

/// Who is asking for our key, if [message] is a request for [roomId]'s
/// call.
CallMember? parseCallKeyRequest(
  CallToDevice message, {
  required String roomId,
  String? Function(CallMember member)? deviceCurve25519,
}) {
  if (message.type != callKeyRequestEventType) return null;
  return _checkedSender(message, roomId, deviceCurve25519);
}

CallMember? _checkedSender(
  CallToDevice message,
  String roomId,
  String? Function(CallMember member)? deviceCurve25519,
) {
  // Anyone can send an unencrypted to-device message claiming anything.
  if (!message.encrypted) return null;
  final content = message.content;
  if (content["room_id"] != roomId) return null;
  final session = content["session"];
  if (session is Map &&
      (session["application"] != _application ||
          session["call_id"] != _callId)) {
    return null;
  }
  final member = content["member"];
  final device = member is Map ? member["claimed_device_id"] : null;
  if (device is! String || device.isEmpty) return null;
  final from = CallMember(message.sender, device);
  final known = deviceCurve25519?.call(from);
  if (known != null &&
      message.senderKey != null &&
      known != message.senderKey) {
    Log.w("Voice keys: a message claiming $from came from another device");
    return null;
  }
  return from;
}

/// Keys we receive: applied in the order they were sent, and held a while
/// when their sender is not in the call yet (the key can arrive before the
/// membership does).
class IncomingCallKeys {
  IncomingCallKeys({
    required this.apply,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Sets [key] at [index] for [member]'s frames.
  final Future<void> Function(CallMember member, int index, Uint8List key)
      apply;
  final DateTime Function() _now;

  /// How long a key from someone not in the call is kept.
  static const holdFor = Duration(seconds: 60);

  final Map<(CallMember, int), int> _sentTs = {};
  final List<({CallKeyMessage message, DateTime until})> _held = [];

  Future<void> receive(CallKeyMessage message,
      {required bool fromMember}) async {
    if (!fromMember) {
      _held.removeWhere((h) => !_now().isBefore(h.until));
      _held.add((message: message, until: _now().add(holdFor)));
      return;
    }
    // A key sent before the one we hold for the same index is stale (they
    // arrive out of order across a reconnect).
    final sent = message.sentTs;
    final slot = (message.from, message.index);
    final last = _sentTs[slot];
    if (sent != null && last != null && sent < last) return;
    if (sent != null) _sentTs[slot] = sent;
    await apply(message.from, message.index, message.key);
  }

  /// [members] are in the call now: keys held for them are applied.
  Future<void> membersChanged(Set<CallMember> members) async {
    final now = _now();
    _held.removeWhere((h) => !now.isBefore(h.until));
    final ready = _held.where((h) => members.contains(h.message.from)).toList();
    _held.removeWhere(ready.contains);
    for (final h in ready) {
      await receive(h.message, fromMember: true);
    }
  }
}
