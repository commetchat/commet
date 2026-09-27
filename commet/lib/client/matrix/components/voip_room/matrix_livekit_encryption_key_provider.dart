import 'dart:async';
import 'dart:typed_data';

import 'package:commet/client/matrix/components/voip_room/call_key_distributor.dart';
import 'package:commet/client/matrix/components/voip_room/call_key_messages.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_voip_room_component.dart';
import 'package:commet/debug/log.dart';
import 'package:livekit_client/livekit_client.dart' hide KeyProvider;
import 'package:webrtc_interface/src/frame_cryptor.dart';

import 'package:matrix/matrix.dart' as mx;
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart' as lk;

/// Media keys of an encrypted voice room: ours go out to everyone in the
/// call through [CallKeyDistributor], theirs come in as to-device messages.
/// See docs/voice-call-health.md.
class MatrixLivekitEncryptionKeyProvider
    implements BaseKeyProvider, CallKeyTransport {
  mx.Room room;
  final BaseKeyProvider _keyProvider;

  lk.Room? _lkRoom;

  String? localParticipant;

  late final List<StreamSubscription> subs;

  late final CallKeyDistributor distributor =
      CallKeyDistributor(transport: this, keyRingSize: options.keyRingSize);

  late final IncomingCallKeys _incoming = IncomingCallKeys(
      apply: (member, index, key) =>
          setRawKey(key, participantId: member.participantId, keyIndex: index));

  Timer? _tick;
  bool _disposed = false;

  MatrixLivekitEncryptionKeyProvider(this._keyProvider, this.room) {
    subs = [
      room.client.onToDeviceEvent.stream.listen(onToDeviceEvent),
      room.client.onSync.stream.listen(onSync),
    ];
  }

  void dispose() {
    Log.i("Disposing key provider");
    _disposed = true;
    _tick?.cancel();
    distributor.dispose();
    for (var sub in subs) {
      sub.cancel();
    }
  }

  static Future<MatrixLivekitEncryptionKeyProvider> create(mx.Room room) async {
    final rtc.KeyProviderOptions options = rtc.KeyProviderOptions(
        sharedKey: false,
        ratchetSalt: Uint8List.fromList(defaultRatchetSalt.codeUnits),
        ratchetWindowSize: 10,
        uncryptedMagicBytes: Uint8List.fromList(defaultMagicBytes.codeUnits),
        failureTolerance: -1,
        keyRingSize: 256,
        keyDerivationAlgorithm: KeyDerivationAlgorithm.kHKDF,
        discardFrameWhenCryptorNotReady:
            defaultDiscardFrameWhenCryptorNotReady);

    final keyProvider =
        await rtc.frameCryptorFactory.createDefaultKeyProvider(options);

    var provider = BaseKeyProvider(keyProvider, options);

    Log.i("Created livekit encryption key provider");

    return MatrixLivekitEncryptionKeyProvider(provider, room);
  }

  @override
  Future<Uint8List> exportKey(String participantId, int? keyIndex) {
    return _keyProvider.exportKey(participantId, keyIndex);
  }

  @override
  Future<Uint8List> exportSharedKey({int? keyIndex}) {
    return _keyProvider.exportSharedKey(keyIndex: keyIndex);
  }

  @override
  int getLatestIndex(String participantId) {
    return _keyProvider.getLatestIndex(participantId);
  }

  @override
  KeyProvider get keyProvider => _keyProvider.keyProvider;

  @override
  KeyProviderOptions get options => _keyProvider.options;

  @override
  Future<Uint8List> ratchetKey(String participantId, int? keyIndex) {
    return _keyProvider.ratchetKey(participantId, keyIndex);
  }

  @override
  Future<Uint8List> ratchetSharedKey({int? keyIndex}) {
    return _keyProvider.ratchetSharedKey(keyIndex: keyIndex);
  }

  @override
  Future<void> setKey(String key, {String? participantId, int? keyIndex}) {
    return _keyProvider.setKey(key,
        participantId: participantId, keyIndex: keyIndex);
  }

  @override
  Future<void> setRawKey(Uint8List key,
      {String? participantId, int? keyIndex}) {
    return _keyProvider.setRawKey(key,
        participantId: participantId, keyIndex: keyIndex);
  }

  @override
  Future<void> setSharedKey(String key, {int? keyIndex}) {
    return _keyProvider.setSharedKey(key, keyIndex: keyIndex);
  }

  @override
  Future<void> setSifTrailer(Uint8List trailer) {
    return _keyProvider.setSifTrailer(trailer);
  }

  @override
  Uint8List? get sharedKey => _keyProvider.sharedKey;

  void init(String localParticipantId, lk.Room livekitRoom) {
    localParticipant = localParticipantId;
    _lkRoom = livekitRoom;

    distributor.start(currentMembers()).catchError((Object e, StackTrace s) {
      Log.onError(e, s, content: "Voice keys: could not start");
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_disposed) distributor.tick();
    });
  }

  /// Who is in the call now, from the room state: every live membership of
  /// the room's call but this device's.
  Map<CallMember, DateTime?> currentMembers() {
    final state = room.states[MatrixVoipRoomComponent.callMemberStateEvent];
    return callMembersFromState(
      [
        for (final event in state?.values ?? const <mx.StrippedStateEvent>[])
          (
            sender: event.senderId,
            content: event.content,
            sentAt: event is mx.Event ? event.originServerTs : null,
          ),
      ],
      ownUserId: room.client.userID!,
      ownDeviceId: room.client.deviceID!,
      now: DateTime.now(),
    );
  }

  String? _curve25519Of(CallMember member) => room
      .client
      .userDeviceKeys[member.userId]
      ?.deviceKeys[member.deviceId]
      ?.curve25519Key;

  @override
  Future<Set<CallMember>> sendKey(
      Set<CallMember> to, int index, Uint8List key) async {
    final devices = <mx.DeviceKeys>[];
    final reached = <CallMember>{};
    final unknown = <String>{};
    for (final member in to) {
      final device = room
          .client.userDeviceKeys[member.userId]?.deviceKeys[member.deviceId];
      if (device == null) {
        unknown.add(member.userId);
      } else {
        devices.add(device);
        reached.add(member);
      }
    }
    if (unknown.isNotEmpty) {
      // A device that just joined (a fresh login) whose keys have not been
      // downloaded yet: ask for them, and the next attempt reaches it.
      Log.w("Voice keys: no device keys yet for ${unknown.join(", ")}");
      unawaited(room.client
          .updateUserDeviceKeys(additionalUsers: unknown)
          .catchError((Object e, StackTrace s) {
        Log.onError(e, s, content: "Voice keys: could not fetch device keys");
      }));
    }
    if (devices.isEmpty) return reached;
    await room.client.sendToDeviceEncrypted(
        devices,
        callKeysEventType,
        callKeyContent(
          roomId: room.id,
          ownDeviceId: room.client.deviceID!,
          index: index,
          key: key,
          now: DateTime.now(),
        ));
    // The SDK drops, without a word, blocked devices and those it could not
    // start an olm session with (no one-time keys): only a device we hold a
    // session with was sent the key. The others are tried again.
    final olm = room.client.encryption?.olmManager.olmSessions;
    bool sent(mx.DeviceKeys d) =>
        !d.blocked && (olm?[d.curve25519Key]?.isNotEmpty ?? false);
    reached.removeWhere((member) {
      final device = room
          .client.userDeviceKeys[member.userId]?.deviceKeys[member.deviceId];
      return device == null || !sent(device);
    });
    Log.i("Voice keys: sent key $index to ${reached.join(", ")}");
    return reached;
  }

  @override
  Future<void> useKey(int index, Uint8List key) async {
    final local = localParticipant;
    if (local == null) return;
    await setRawKey(key, participantId: local, keyIndex: index);
    await _lkRoom?.e2eeManager?.setKeyIndex(index, participantIdentity: local);
    Log.i("Voice keys: encrypting with key $index");
  }

  final Map<String, DateTime> _requested = {};

  /// How often we ask one participant for its key.
  static const requestEvery = Duration(seconds: 10);

  /// We cannot decrypt [participantIdentity] (LiveKit reports a missing key
  /// or failed decryption): ask it for its key. A roscord client sends it
  /// at once; without this we waited for its next scheduled resend.
  Future<void> requestKeyFrom(String participantIdentity) async {
    if (_disposed) return;
    final member = CallMember.fromParticipantId(participantIdentity);
    if (member == null) return;
    final now = DateTime.now();
    final last = _requested[participantIdentity];
    if (last != null && now.difference(last) < requestEvery) return;
    _requested[participantIdentity] = now;
    final device =
        room.client.userDeviceKeys[member.userId]?.deviceKeys[member.deviceId];
    if (device == null) {
      Log.w("Voice keys: cannot ask $member for its key, no device keys");
      return;
    }
    Log.i("Voice keys: cannot decrypt $member, asking it for its key");
    await room.client.sendToDeviceEncrypted(
        [device],
        callKeyRequestEventType,
        callKeyRequestContent(
            roomId: room.id, ownDeviceId: room.client.deviceID!));
  }

  void onToDeviceEvent(mx.ToDeviceEvent event) {
    if (event.type != callKeysEventType &&
        event.type != callKeyRequestEventType) {
      return;
    }
    final message = CallToDevice(
      type: event.type,
      sender: event.senderId,
      content: event.content,
      encrypted: event.encryptedContent != null,
      senderKey: event.encryptedContent?["sender_key"] as String?,
    );

    final request = parseCallKeyRequest(message,
        roomId: room.id, deviceCurve25519: _curve25519Of);
    if (request != null) {
      distributor.keyRequested(request);
      return;
    }

    final key = CallKeyMessage.parse(message,
        roomId: room.id, deviceCurve25519: _curve25519Of);
    if (key == null) {
      // Another room's call, or not one we can trust.
      if (event.content["room_id"] == room.id) {
        Log.w("Voice keys: ignored a key message from ${event.senderId}");
      }
      return;
    }
    Log.i("Voice keys: got key ${key.index} of ${key.from}");
    _incoming
        .receive(key, fromMember: distributor.members.contains(key.from))
        .catchError((Object e, StackTrace s) {
      Log.onError(e, s, content: "Voice keys: could not set a key");
    });
  }

  void onSync(mx.SyncUpdate event) {
    if (_disposed) return;
    final roomUpdate = event.rooms?.join?[room.id];
    if (roomUpdate == null) return;

    bool touches(List<mx.BasicEvent>? events) =>
        events?.any(
            (e) => e.type == MatrixVoipRoomComponent.callMemberStateEvent) ??
        false;
    // A gappy sync puts membership changes in the state section.
    if (!touches(roomUpdate.timeline?.events) && !touches(roomUpdate.state)) {
      return;
    }

    final members = currentMembers();
    distributor.updateMembers(members);
    _incoming
        .membersChanged(members.keys.toSet())
        .catchError((Object e, StackTrace s) {
      Log.onError(e, s, content: "Voice keys: could not set a held key");
    });
  }
}
