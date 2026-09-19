// Wire format of the DJ booth, on the LiveKit data channel (reliable, topic
// [DjProtocol.topic]). Every message is a JSON object with a `t` type:
//
//   caps   {dj: bool, p: platform}      what the sender's client can do
//   sync   {}                           someone asks for the booth
//   state  {DjSnapshot}                 the booth, from the DJ on every change
//                                       (or, while empty, from anyone asked)
//   tick   {e, s, c, pos, p, b}         the DJ's position, every few seconds
//   req    {on: bool}                   ask (or stop asking) to be the DJ
//   pfail  {e, pid, why}                the handoff target could not take over
//   part   {id, i, n, d}                one piece of a large message
//
// LiveKit takes about 15 KiB per data packet, so a state carrying a long
// queue is sent as the pieces of its JSON text, put back together by the
// receiver. Not compressed: what a sender can make a receiver hold is then
// bounded by what it sends (see [DjPartAssembler]).
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

class DjProtocol {
  static const topic = 'chat.commet.dj.v1';

  /// Largest message sent whole, in bytes.
  static const maxPacketBytes = 14000;

  /// Characters of JSON per part (at most 3 bytes each in UTF-8, plus the
  /// part's own wrapping, still under the packet limit once escaped).
  static const partChars = 3500;

  /// Most parts in one message: about 450 KB of JSON, a full queue of
  /// ordinary songs with room to spare.
  static const maxParts = 128;

  static final Random _random = Random();

  /// The messages to send for [message]: itself when it fits in a packet,
  /// its parts otherwise. Null when it is too big to send at all.
  static List<Map<String, Object?>>? split(Map<String, Object?> message) {
    final text = jsonEncode(message);
    if (utf8.encode(text).length <= maxPacketBytes) return [message];

    final count = (text.length / partChars).ceil();
    if (count > maxParts) return null;
    final id = _random.nextInt(1 << 31).toRadixString(36);
    return [
      for (var i = 0; i < count; i++)
        {
          't': 'part',
          'id': id,
          'i': i,
          'n': count,
          'd': text.substring(
              i * partChars, min(text.length, (i + 1) * partChars)),
        },
    ];
  }

  static Uint8List encodePacket(Map<String, Object?> message) =>
      utf8.encode(jsonEncode(message));

  /// Parses one packet; null when it is not a JSON object with a type.
  static Map<String, Object?>? decodePacket(Uint8List data) {
    if (data.length > maxPacketBytes * 2) return null;
    try {
      final json = jsonDecode(utf8.decode(data));
      if (json is Map<String, Object?> && json['t'] is String) return json;
    } catch (_) {}
    return null;
  }
}

/// Puts [DjProtocol] parts back together, per sender.
class DjPartAssembler {
  final Map<String, _Pending> _pending = {};

  /// How long an incomplete message is kept.
  static const timeout = Duration(seconds: 30);

  /// Incomplete messages kept per sender; the oldest goes first.
  static const maxPendingPerSender = 3;

  /// Returns the whole message once [part] completes it.
  Map<String, Object?>? add(String sender, Map<String, Object?> part,
      {DateTime? now}) {
    now ??= DateTime.now();
    _pending.removeWhere((_, p) => now!.difference(p.started) > timeout);

    final id = part['id'];
    final index = part['i'];
    final count = part['n'];
    final data = part['d'];
    if (id is! String || id.length > 16) return null;
    if (index is! int || count is! int || data is! String) return null;
    if (count < 1 || count > DjProtocol.maxParts || index < 0 || index >= count) {
      return null;
    }
    if (data.length > DjProtocol.partChars) return null;

    final key = '$sender\n$id';
    var pending = _pending[key];
    if (pending == null) {
      final mine = _pending.entries
          .where((e) => e.key.startsWith('$sender\n'))
          .toList()
        ..sort((a, b) => a.value.started.compareTo(b.value.started));
      for (final old in mine.take(max(0, mine.length - maxPendingPerSender + 1))) {
        _pending.remove(old.key);
      }
      pending = _pending[key] = _Pending(count, now);
    }
    if (pending.parts.length != count) return null;
    pending.parts[index] = data;
    if (pending.parts.any((p) => p == null)) return null;
    _pending.remove(key);

    try {
      final json = jsonDecode(pending.parts.join());
      if (json is Map<String, Object?> && json['t'] is String) return json;
    } catch (_) {}
    return null;
  }
}

class _Pending {
  final List<String?> parts;
  final DateTime started;

  _Pending(int count, this.started) : parts = List.filled(count, null);
}
