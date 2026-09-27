// Who has our media key in an encrypted voice room, and when we start using
// a new one.
//
// Every participant encrypts what it sends with a key of its own and hands
// it to the others in to-device messages. A receiver without our current
// key hears silence from us. The old key provider sent each key once,
// without waiting to see whether the send worked, started using it five
// seconds later regardless, and made a new one on every change to any call
// membership (a mute, going away, a screen share). One lost message meant
// silence until the next membership change, which in a quiet call could be
// never: the user had to leave and rejoin.
//
// [CallKeyDistributor] keeps a ledger instead (docs/voice-call-health.md):
// - a new key only when someone leaves (they must not hear what follows);
//   someone joining gets the key in use;
// - every member is sent every key it needs until a send to it works, with
//   backoff, and the key in use again every minute and whenever a member
//   asks for it (it cannot decrypt us);
// - a new key is used once everyone has it, or after [switchCap] at the
//   latest, so a member we cannot reach does not keep the others on a key
//   someone who left still has.
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:commet/debug/log.dart';

/// One device in the call.
class CallMember {
  const CallMember(this.userId, this.deviceId);

  final String userId;
  final String deviceId;

  /// Its LiveKit identity, which the frame cryptors are keyed by.
  String get participantId => "$userId:$deviceId";

  /// The member with LiveKit identity [participantId], null when it has no
  /// device part.
  static CallMember? fromParticipantId(String participantId) {
    // @user:server:DEVICE; the server part can hold colons (a port).
    final cut = participantId.lastIndexOf(':');
    if (cut <= 0 || participantId.indexOf(':') == cut) return null;
    return CallMember(
        participantId.substring(0, cut), participantId.substring(cut + 1));
  }

  @override
  bool operator ==(Object other) =>
      other is CallMember &&
      other.userId == userId &&
      other.deviceId == deviceId;

  @override
  int get hashCode => Object.hash(userId, deviceId);

  @override
  String toString() => participantId;
}

/// What the distributor does to the outside world.
abstract class CallKeyTransport {
  /// Sends our key [key] at [index] to [to]. Returns the members it went
  /// out to; the others (their device keys are not known yet) are tried
  /// again later. Throws when the send failed.
  Future<Set<CallMember>> sendKey(Set<CallMember> to, int index, Uint8List key);

  /// Starts encrypting what we send with [key] at [index].
  Future<void> useKey(int index, Uint8List key);
}

class _Key {
  _Key(this.index, this.bytes, this.createdAt);

  final int index;
  final Uint8List bytes;
  final DateTime createdAt;

  /// When the last member still missing it got it.
  DateTime? deliveredAt;
}

class _Need {
  _Need(this.nextAt);

  final Set<int> indices = {};
  DateTime nextAt;
  int attempts = 0;
}

class CallKeyDistributor {
  CallKeyDistributor({
    required CallKeyTransport transport,
    DateTime Function()? now,
    Random? random,
    this.keyRingSize = 256,
  })  : _transport = transport,
        _now = now ?? DateTime.now,
        _random = random ?? Random.secure();

  final CallKeyTransport _transport;
  final DateTime Function() _now;
  final Random _random;
  final int keyRingSize;

  /// A new key is used this long after the last member got it, the time
  /// its client takes to hand it to the frame decryptor.
  static const useKeyDelay = Duration(seconds: 2);

  /// A new key is used this long after it was made at the latest.
  static const switchCap = Duration(seconds: 10);

  /// Everyone is sent the key in use this often, whatever happened.
  static const announceEvery = Duration(seconds: 60);

  /// A member asking for our key more often than this is answered once.
  static const requestEvery = Duration(seconds: 5);

  /// Spacing of the attempts to reach one member.
  static const retryBackoff = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(seconds: 60),
  ];

  Map<CallMember, DateTime?> _members = {};
  final Map<CallMember, _Need> _needs = {};
  final Map<CallMember, DateTime> _lastRequest = {};

  _Key? _current;
  _Key? _pending;
  late int _nextIndex = _random.nextInt(keyRingSize);
  DateTime? _nextAnnounce;

  bool _started = false;
  bool _disposed = false;
  bool _ticking = false;
  bool _again = false;

  /// The key index we encrypt with, null before [start].
  int? get currentIndex => _current?.index;

  /// A new key made and not in use yet.
  int? get pendingIndex => _pending?.index;

  /// The members that still need a key from us.
  Set<CallMember> get waiting => {
        for (final e in _needs.entries)
          if (e.value.indices.isNotEmpty) e.key
      };

  Set<CallMember> get members => _members.keys.toSet();

  /// Makes our first key, uses it at once (nobody can hear us before they
  /// have it anyway) and sends it to [members].
  Future<void> start(Map<CallMember, DateTime?> members) async {
    if (_started || _disposed) return;
    _started = true;
    _members = Map.of(members);
    final key = _newKey();
    _current = key;
    await _transport.useKey(key.index, key.bytes);
    for (final member in _members.keys) {
      _need(member, key.index);
    }
    _nextAnnounce = _now().add(announceEvery);
    await tick();
  }

  /// The call's members as the room state has them now (without this
  /// device), each with when it joined. Only changes to who is there count:
  /// a member rewriting its membership (a mute, a screen share, being away)
  /// is not one.
  void updateMembers(Map<CallMember, DateTime?> members) {
    if (_disposed) return;
    final before = _members;
    _members = Map.of(members);
    if (!_started) return;

    final left = before.keys.where((m) => !members.containsKey(m)).toList();
    final joined = members.keys.where((m) => !before.containsKey(m)).toList();
    // Joined again: a new session of the same device, which has none of
    // our keys.
    final rejoined = members.keys
        .where((m) =>
            before.containsKey(m) &&
            members[m] != null &&
            before[m] != null &&
            members[m] != before[m])
        .toList();

    for (final member in left) {
      _needs.remove(member);
      _lastRequest.remove(member);
    }
    for (final member in [...joined, ...rejoined]) {
      _needAll(member);
    }

    if (left.isNotEmpty) {
      // They must not hear what comes next. A key made for an earlier
      // leave and not in use yet may have reached them: it is dropped.
      final replaced = _pending;
      if (replaced != null) {
        for (final need in _needs.values) {
          need.indices.remove(replaced.index);
        }
      }
      final key = _pending = _newKey();
      Log.i("Voice keys: ${left.join(", ")} left, made key ${key.index}");
      for (final member in _members.keys) {
        _need(member, key.index);
      }
    }
    if (left.isNotEmpty || joined.isNotEmpty || rejoined.isNotEmpty) {
      _kick();
    }
  }

  /// [member] cannot decrypt us: sent what it needs again, at once.
  void keyRequested(CallMember member) {
    if (_disposed || !_started || !_members.containsKey(member)) return;
    final now = _now();
    final last = _lastRequest[member];
    if (last != null && now.difference(last) < requestEvery) return;
    _lastRequest[member] = now;
    Log.i("Voice keys: $member asked for our key");
    _needAll(member, at: now);
    _kick();
  }

  /// Sends what is due, and switches to a new key once it may be used.
  /// Called once a second and after every change.
  Future<void> tick() async {
    if (_disposed || !_started) return;
    if (_ticking) {
      _again = true;
      return;
    }
    _ticking = true;
    try {
      do {
        _again = false;
        await _tick();
      } while (_again && !_disposed);
    } finally {
      _ticking = false;
    }
  }

  void dispose() {
    _disposed = true;
    _needs.clear();
  }

  Future<void> _tick() async {
    var now = _now();
    final announce = _nextAnnounce;
    if (announce != null && !now.isBefore(announce)) {
      _nextAnnounce = now.add(announceEvery);
      for (final member in _members.keys) {
        _needAll(member, at: now);
      }
    }

    for (final key in [_current, _pending].nonNulls) {
      if (_disposed) return;
      final due = {
        for (final e in _needs.entries)
          if (e.value.indices.contains(key.index) &&
              !now.isBefore(e.value.nextAt))
            e.key,
      };
      if (due.isNotEmpty) await _send(key, due);
      if (_disposed) return;
      now = _now();
      if (!_needs.values.any((n) => n.indices.contains(key.index))) {
        key.deliveredAt ??= now;
      }
    }

    final pending = _pending;
    if (pending == null || _disposed) return;
    final delivered = pending.deliveredAt;
    final ready =
        delivered != null && !now.isBefore(delivered.add(useKeyDelay));
    final capped = !now.isBefore(pending.createdAt.add(switchCap));
    if (!ready && !capped) return;
    if (!ready) {
      Log.w("Voice keys: using key ${pending.index} before "
          "${needing(pending.index).join(", ")} got it; still sending it "
          "to them");
    }
    _current = pending;
    _pending = null;
    await _transport.useKey(pending.index, pending.bytes);
    // Whoever still misses it keeps being sent it, as the key in use.
  }

  Future<void> _send(_Key key, Set<CallMember> due) async {
    Set<CallMember> reached;
    try {
      reached = await _transport.sendKey(due, key.index, key.bytes);
    } catch (e, s) {
      Log.onError(e, s, content: "Voice keys: could not send key ${key.index}");
      reached = const {};
    }
    if (_disposed) return;
    final now = _now();
    final missed = due.difference(reached);
    if (missed.isNotEmpty) {
      Log.w("Voice keys: key ${key.index} did not reach ${missed.join(", ")}; "
          "trying again");
    }
    for (final member in due) {
      final need = _needs[member];
      if (need == null) continue;
      if (reached.contains(member)) {
        need.indices.remove(key.index);
        if (need.indices.isEmpty) {
          _needs.remove(member);
        } else {
          need.nextAt = now;
        }
      } else {
        need.attempts++;
        need.nextAt =
            now.add(retryBackoff[min(need.attempts, retryBackoff.length) - 1]);
      }
    }
  }

  _Key _newKey() {
    final index = _nextIndex;
    _nextIndex = (_nextIndex + 1) % keyRingSize;
    final bytes =
        Uint8List.fromList(List<int>.generate(16, (_) => _random.nextInt(256)));
    return _Key(index, bytes, _now());
  }

  void _need(CallMember member, int index, {DateTime? at}) {
    final need = _needs.putIfAbsent(member, () => _Need(at ?? _now()));
    need.indices.add(index);
    // Not everyone has it any more.
    final pending = _pending;
    if (pending != null && pending.index == index) pending.deliveredAt = null;
    if (at != null) {
      need.nextAt = at;
      need.attempts = 0;
    }
  }

  void _needAll(CallMember member, {DateTime? at}) {
    for (final key in [_current, _pending].nonNulls) {
      _need(member, key.index, at: at ?? _now());
    }
  }

  void _kick() {
    Future<void>.microtask(tick);
  }

  /// The members of [members] that still need [index], for tests.
  Set<CallMember> needing(int index) => {
        for (final e in _needs.entries)
          if (e.value.indices.contains(index)) e.key
      };

  /// The key bytes at [index] if it is ours and current or pending, for
  /// tests.
  Uint8List? keyAt(int index) => [_current, _pending]
      .nonNulls
      .firstWhereOrNull((k) => k.index == index)
      ?.bytes;
}
