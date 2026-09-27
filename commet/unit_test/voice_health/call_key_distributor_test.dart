// Our media key in an encrypted voice room: everyone in the call can
// decrypt us whatever happens to the messages that carry it (a send that
// fails, one that is lost, a member we cannot reach yet), a new key is only
// made when someone leaves, and never used before it had its chance to
// arrive.
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:commet/client/matrix/components/voip_room/call_key_distributor.dart';
import 'package:flutter_test/flutter_test.dart';

const _alice = CallMember('@alice:example.org', 'ALICE');
const _bob = CallMember('@bob:example.org', 'BOB');
const _carol = CallMember('@carol:example.org', 'CAROL');

/// Our client, the network between us and the others, and what each of
/// them holds of our keys.
class _Call implements CallKeyTransport {
  DateTime now = DateTime(2026, 9, 26, 12);
  late final distributor =
      CallKeyDistributor(transport: this, now: () => now, random: Random(7));

  /// The sends fail (no network, the homeserver answers an error).
  bool failing = false;

  /// The sends "work" but the messages never arrive.
  bool losing = false;

  /// Members whose device keys we do not know yet.
  final Set<CallMember> unknownDevices = {};

  /// What each member received of our keys.
  final Map<CallMember, Map<int, Uint8List>> received = {};

  int? inUse;
  final List<int> used = [];
  int sends = 0;

  @override
  Future<Set<CallMember>> sendKey(
      Set<CallMember> to, int index, Uint8List key) async {
    sends++;
    if (failing) throw Exception('M_UNKNOWN: the homeserver is down');
    final reached = to.difference(unknownDevices);
    if (!losing) {
      for (final member in reached) {
        (received[member] ??= {})[index] = Uint8List.fromList(key);
      }
    }
    return reached;
  }

  @override
  Future<void> useKey(int index, Uint8List key) async {
    inUse = index;
    used.add(index);
  }

  /// Whether [member] can decrypt what we send now.
  bool canHear(CallMember member) {
    final index = inUse;
    if (index == null) return false;
    final ours = distributor.keyAt(index);
    final theirs = received[member]?[index];
    return ours != null &&
        theirs != null &&
        const ListEquality<int>().equals(ours, theirs);
  }

  Future<void> start(Set<CallMember> members) =>
      distributor.start({for (final m in members) m: DateTime(2026)});

  void members(Set<CallMember> members, {Map<CallMember, DateTime>? joined}) =>
      distributor.updateMembers(
          {for (final m in members) m: joined?[m] ?? DateTime(2026)});

  Future<void> run(int seconds) async {
    for (var i = 0; i < seconds; i++) {
      now = now.add(const Duration(seconds: 1));
      await distributor.tick();
    }
  }
}

void main() {
  test('everyone can hear us from the start', () async {
    final call = _Call();
    await call.start({_alice, _bob});
    expect(call.canHear(_alice), isTrue);
    expect(call.canHear(_bob), isTrue);
  });

  test('a membership rewrite (mute, away, screen share) makes no new key',
      () async {
    final call = _Call();
    await call.start({_alice, _bob});
    final first = call.inUse;
    for (var i = 0; i < 20; i++) {
      call.members({_alice, _bob});
      await call.run(3);
    }
    expect(call.used, [first]);
    expect(call.canHear(_alice), isTrue);
  });

  test('someone joining gets the key in use, no new key', () async {
    final call = _Call();
    await call.start({_alice});
    call.members({_alice, _bob});
    await call.run(1);
    expect(call.used, hasLength(1));
    expect(call.canHear(_bob), isTrue);
  });

  test('someone leaving gets a new key made, which they never receive',
      () async {
    final call = _Call();
    await call.start({_alice, _bob});
    final first = call.inUse!;
    call.members({_alice});
    await call.run(1);
    expect(call.inUse, first, reason: 'not before it had time to arrive');
    await call.run(3);
    expect(call.inUse, isNot(first));
    expect(call.canHear(_alice), isTrue);
    expect(call.canHear(_bob), isFalse);
  });

  test('a key that could not be sent is not used, and is sent again', () async {
    final call = _Call();
    await call.start({_alice, _bob, _carol});
    final first = call.inUse!;
    call.failing = true;
    call.members({_alice, _bob});
    await call.run(8);
    expect(call.inUse, first,
        reason: 'the old key still works for everyone who is left');
    expect(call.canHear(_alice), isTrue);

    call.failing = false;
    await call.run(20);
    expect(call.inUse, isNot(first));
    expect(call.canHear(_alice), isTrue);
    expect(call.canHear(_bob), isTrue);
  });

  test('a new key nobody can be sent is used after the cap, and still sent',
      () async {
    final call = _Call();
    await call.start({_alice, _bob, _carol});
    final first = call.inUse!;
    call.failing = true;
    call.members({_alice, _bob});
    await call.run(11);
    expect(call.inUse, isNot(first), reason: 'carol must not keep hearing us');
    expect(call.canHear(_alice), isFalse);

    call.failing = false;
    await call.run(70);
    expect(call.canHear(_alice), isTrue);
    expect(call.canHear(_bob), isTrue);
    expect(call.canHear(_carol), isFalse);
  });

  test('a member whose device keys are not known yet gets it once they are',
      () async {
    final call = _Call();
    await call.start({_alice});
    call.unknownDevices.add(_bob);
    call.members({_alice, _bob});
    await call.run(5);
    expect(call.canHear(_bob), isFalse);
    call.unknownDevices.clear();
    await call.run(20);
    expect(call.canHear(_bob), isTrue);
  });

  test('a key lost on the way arrives with the next announcement', () async {
    final call = _Call();
    call.losing = true;
    await call.start({_alice, _bob});
    expect(call.canHear(_alice), isFalse);
    call.losing = false;
    await call.run(CallKeyDistributor.announceEvery.inSeconds + 1);
    expect(call.canHear(_alice), isTrue);
    expect(call.canHear(_bob), isTrue);
  });

  test('a member that asks for our key gets it at once', () async {
    final call = _Call();
    call.losing = true;
    await call.start({_alice, _bob});
    call.losing = false;
    call.distributor.keyRequested(_alice);
    await call.run(1);
    expect(call.canHear(_alice), isTrue);
    expect(call.canHear(_bob), isFalse,
        reason: 'only who asked, the others wait for the announcement');
  });

  test('requests are answered at most every few seconds', () async {
    final call = _Call();
    await call.start({_alice});
    final before = call.sends;
    for (var i = 0; i < 10; i++) {
      call.distributor.keyRequested(_alice);
      await Future<void>.delayed(Duration.zero);
    }
    await call.run(1);
    expect(call.sends - before, 1);
  });

  test('someone who is not in the call cannot ask for our key', () async {
    final call = _Call();
    await call.start({_alice});
    final before = call.sends;
    call.distributor.keyRequested(_carol);
    await call.run(1);
    expect(call.sends, before);
    expect(call.received[_carol], isNull);
  });

  test('two leaves close together: only the last key is used', () async {
    final call = _Call();
    await call.start({_alice, _bob, _carol});
    call.members({_alice, _bob});
    await call.run(1);
    final firstNew = call.distributor.pendingIndex;
    call.members({_alice});
    await call.run(5);
    expect(call.used, isNot(contains(firstNew)),
        reason: 'bob may have got that one before he left');
    expect(call.canHear(_alice), isTrue);
    expect(call.canHear(_bob), isFalse);
  });

  test('a device that joined again is sent the key again', () async {
    final call = _Call();
    await call.start({_alice, _bob});
    call.received.remove(_bob); // a new session of bob's app
    call.members({_alice, _bob}, joined: {_bob: DateTime(2026, 9, 26, 13)});
    await call.run(1);
    expect(call.canHear(_bob), isTrue);
  });

  test('alone in the call a leave still makes and uses a new key', () async {
    final call = _Call();
    await call.start({_alice});
    final first = call.inUse!;
    call.members({});
    await call.run(3);
    expect(call.inUse, isNot(first));
  });

  test('key indices go round the ring', () async {
    final call = _Call();
    await call.start({_alice, _bob});
    for (var i = 0; i < 300; i++) {
      call.members({_alice});
      await call.run(3);
      call.members({_alice, _bob});
      await call.run(1);
    }
    expect(call.used.every((i) => i >= 0 && i < 256), isTrue);
    expect(call.used.toSet().length, 256);
    expect(call.canHear(_alice), isTrue);
    expect(call.canHear(_bob), isTrue);
  });

  test('two calls do not start on the same key index', () async {
    final a = CallKeyDistributor(transport: _Call(), random: Random(1));
    final b = CallKeyDistributor(transport: _Call(), random: Random(2));
    await a.start({});
    await b.start({});
    expect(a.currentIndex, isNot(b.currentIndex));
  });

  test('nothing is sent once disposed', () async {
    final call = _Call();
    await call.start({_alice, _bob});
    call.members({_alice});
    call.distributor.dispose();
    final before = call.sends;
    await call.run(120);
    expect(call.sends, before);
  });

  test('participant ids of members, with a port in the server name', () {
    expect(CallMember.fromParticipantId('@bob:example.org:BOB'), _bob);
    expect(CallMember.fromParticipantId('@a:host:8448:DEV'),
        const CallMember('@a:host:8448', 'DEV'));
    expect(CallMember.fromParticipantId('@a:host'), isNull);
    expect(_bob.participantId, '@bob:example.org:BOB');
  });
}
