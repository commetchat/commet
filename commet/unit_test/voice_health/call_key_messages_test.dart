// The media key messages of an encrypted voice room: who is in the call to
// be sent our key, which incoming keys are taken (only this room's call,
// only encrypted, only from the device that claims them, in the order they
// were sent), and keys that arrive before their sender's membership.
import 'dart:convert';
import 'dart:typed_data';

import 'package:commet/client/matrix/components/voip_room/call_key_distributor.dart';
import 'package:commet/client/matrix/components/voip_room/call_key_messages.dart';
import 'package:flutter_test/flutter_test.dart';

const _room = '!voice:example.org';
const _bob = CallMember('@bob:example.org', 'BOB');

Map<String, dynamic> _membership(String device,
        {String application = 'm.call',
        String callId = '',
        int? createdTs,
        int? expires}) =>
    {
      'application': application,
      'call_id': callId,
      'device_id': device,
      if (expires != null) 'expires': expires,
      if (createdTs != null) 'created_ts': createdTs,
    };

CallToDevice _key({
  int index = 3,
  String key = 'AAECAwQFBgcICQoLDA0ODw==',
  String room = _room,
  bool encrypted = true,
  String device = 'BOB',
  String? senderKey = 'curve-bob',
  Map<String, dynamic>? session,
  int? sentTs,
}) =>
    CallToDevice(
      type: callKeysEventType,
      sender: '@bob:example.org',
      encrypted: encrypted,
      senderKey: senderKey,
      content: {
        'keys': {'index': index, 'key': key},
        'member': {'claimed_device_id': device},
        'room_id': room,
        if (sentTs != null) 'sent_ts': sentTs,
        'session': session ??
            {'application': 'm.call', 'call_id': '', 'scope': 'm.room'},
      },
    );

void main() {
  group('who is in the call', () {
    final now = DateTime(2026, 9, 26, 12);

    Map<CallMember, DateTime?> members(
            List<
                    ({
                      String sender,
                      Map<String, dynamic> content,
                      DateTime? sentAt
                    })>
                state) =>
        callMembersFromState(state,
            ownUserId: '@me:example.org', ownDeviceId: 'ME', now: now);

    test('live memberships of the room\'s call, without this device', () {
      final result = members([
        (sender: '@bob:example.org', content: _membership('BOB'), sentAt: now),
        (sender: '@me:example.org', content: _membership('ME'), sentAt: now),
        (
          sender: '@me:example.org',
          content: _membership('LAPTOP'),
          sentAt: now
        ),
      ]);
      expect(result.keys, {
        _bob,
        const CallMember('@me:example.org', 'LAPTOP'),
      });
    });

    test('left, expired, other applications and calls are not in it', () {
      final result = members([
        (sender: '@a:example.org', content: {}, sentAt: now),
        (
          sender: '@b:example.org',
          content: _membership('B', expires: 1000),
          sentAt: now.subtract(const Duration(hours: 1))
        ),
        (
          sender: '@c:example.org',
          content: _membership('C', application: 'm.other'),
          sentAt: now
        ),
        (
          sender: '@d:example.org',
          content: _membership('D', callId: 'another'),
          sentAt: now
        ),
      ]);
      expect(result, isEmpty);
    });

    test('a member joined when its membership says, rewrites or not', () {
      final joined = DateTime(2026, 9, 26, 11);
      final result = members([
        (
          sender: '@bob:example.org',
          content: _membership('BOB', createdTs: joined.millisecondsSinceEpoch),
          sentAt: now
        ),
      ]);
      expect(result[_bob], joined);
    });
  });

  group('incoming keys', () {
    test('a key for this room\'s call is taken', () {
      final key = CallKeyMessage.parse(_key(sentTs: 5), roomId: _room);
      expect(key, isNotNull);
      expect(key!.from, _bob);
      expect(key.index, 3);
      expect(key.key, base64Decode('AAECAwQFBgcICQoLDA0ODw=='));
      expect(key.sentTs, 5);
    });

    test('another room\'s key is not (it would overwrite the same index)', () {
      expect(
          CallKeyMessage.parse(_key(room: '!other:example.org'), roomId: _room),
          isNull);
    });

    test('another call\'s key is not', () {
      expect(
          CallKeyMessage.parse(
              _key(session: {'application': 'm.call', 'call_id': 'x'}),
              roomId: _room),
          isNull);
    });

    test('an unencrypted key is not: anyone can send one', () {
      expect(
          CallKeyMessage.parse(_key(encrypted: false), roomId: _room), isNull);
    });

    test('a key from a device other than the one it claims is not', () {
      expect(
          CallKeyMessage.parse(_key(senderKey: 'curve-mallory'),
              roomId: _room, deviceCurve25519: (_) => 'curve-bob'),
          isNull);
      expect(
          CallKeyMessage.parse(_key(),
              roomId: _room, deviceCurve25519: (_) => 'curve-bob'),
          isNotNull);
    });

    test('malformed keys are not', () {
      expect(CallKeyMessage.parse(_key(index: 256), roomId: _room), isNull);
      expect(CallKeyMessage.parse(_key(index: -1), roomId: _room), isNull);
      expect(CallKeyMessage.parse(_key(key: '%%%'), roomId: _room), isNull);
      expect(CallKeyMessage.parse(_key(key: ''), roomId: _room), isNull);
      expect(CallKeyMessage.parse(_key(device: ''), roomId: _room), isNull);
    });

    test('a request for our key names who asks', () {
      final request = CallToDevice(
        type: callKeyRequestEventType,
        sender: '@bob:example.org',
        encrypted: true,
        content: callKeyRequestContent(roomId: _room, ownDeviceId: 'BOB'),
      );
      expect(parseCallKeyRequest(request, roomId: _room), _bob);
      expect(
          parseCallKeyRequest(request, roomId: '!other:example.org'), isNull);
    });

    // Exactly what roscord sent before this change
    // (MatrixLivekitEncryptionKeyProvider.sendKeyToParticipants): people
    // who have not updated still have to be heard.
    test('a key from an older roscord is taken', () {
      final key = CallKeyMessage.parse(
          const CallToDevice(
            type: 'io.element.call.encryption_keys',
            sender: '@bob:example.org',
            encrypted: true,
            content: {
              'keys': {'index': 0, 'key': 'AAECAwQFBgcICQoLDA0ODw=='},
              'member': {'claimed_device_id': 'BOB'},
              'room_id': _room,
              'sent_ts': 1790000000000,
              'session': {
                'application': 'm.call',
                'call_id': '',
                'scope': 'm.room',
              },
            },
          ),
          roomId: _room);
      expect(key?.from, _bob);
      expect(key?.index, 0);
    });

    test('what we send is what we take', () {
      final content = callKeyContent(
          roomId: _room,
          ownDeviceId: 'BOB',
          index: 7,
          key: Uint8List.fromList(List.generate(16, (i) => i)),
          now: DateTime(2026));
      final key = CallKeyMessage.parse(
          CallToDevice(
              type: callKeysEventType,
              sender: '@bob:example.org',
              content: content,
              encrypted: true),
          roomId: _room);
      expect(key?.index, 7);
      expect(key?.key, List.generate(16, (i) => i));
    });
  });

  group('applying keys', () {
    late List<String> applied;
    late DateTime now;
    late IncomingCallKeys incoming;

    setUp(() {
      applied = [];
      now = DateTime(2026, 9, 26);
      incoming = IncomingCallKeys(
        now: () => now,
        apply: (member, index, key) async =>
            applied.add('$member $index ${key.first}'),
      );
    });

    CallKeyMessage key(int index, int first, {int? sentTs}) =>
        CallKeyMessage(_bob, index, Uint8List.fromList([first, 0]), sentTs);

    test('keys from members are applied', () async {
      await incoming.receive(key(1, 9), fromMember: true);
      expect(applied, ['@bob:example.org:BOB 1 9']);
    });

    test('an older key arriving late does not replace a newer one', () async {
      await incoming.receive(key(1, 2, sentTs: 200), fromMember: true);
      await incoming.receive(key(1, 1, sentTs: 100), fromMember: true);
      expect(applied, ['@bob:example.org:BOB 1 2']);
    });

    test('a key from someone not in the call yet waits for them', () async {
      await incoming.receive(key(1, 9), fromMember: false);
      expect(applied, isEmpty);
      await incoming.membersChanged({_bob});
      expect(applied, ['@bob:example.org:BOB 1 9']);
    });

    test('a held key is dropped after a while', () async {
      await incoming.receive(key(1, 9), fromMember: false);
      now = now.add(IncomingCallKeys.holdFor + const Duration(seconds: 1));
      await incoming.membersChanged({_bob});
      expect(applied, isEmpty);
    });
  });
}
