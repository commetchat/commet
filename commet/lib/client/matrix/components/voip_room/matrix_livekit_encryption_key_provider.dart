import 'dart:convert';
import 'dart:typed_data';

import 'package:commet/client/matrix/components/voip_room/matrix_voip_room_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/debug/log.dart';
import 'package:livekit_client/livekit_client.dart' hide KeyProvider;
import 'package:webrtc_interface/src/frame_cryptor.dart';

import 'package:matrix/matrix.dart' as mx;
import 'package:matrix/src/utils/crypto/crypto.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

class MatrixLivekitEncryptionKeyProvider implements BaseKeyProvider {
  mx.Room room;
  BaseKeyProvider _keyProvider;

  int indexCounter = 0;

  String? localParticipant;

  MatrixLivekitEncryptionKeyProvider(this._keyProvider, this.room) {
    room.client.onToDeviceEvent.stream.listen(onToDeviceEvent);
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

  void init(String localParticipantId) {
    localParticipant = localParticipantId;
    createNewKey();
  }

  void createNewKey() {
    var index = indexCounter % options.keyRingSize;
    indexCounter++;

    var bytes = secureRandomBytes(16);

    setRawKey(bytes, participantId: localParticipant!, keyIndex: index);

    sendKeyToParticipants(bytes, localParticipant!, index);
  }

  Future<void> sendKeyToParticipants(
      Uint8List bytes, String participantId, int keyIndex) async {
    final state = room.states[MatrixVoipRoomComponent.callMemberStateEvent];
    if (state == null) {
      return;
    }

    for (var event in state.values) {
      if (event.content.isEmpty) continue;

      var device = event.content.tryGet<String>("device_id");

      if (device == null) continue;

      if(event.senderId == room.client.userID && device == room.client.deviceID) {
        Log.i("Dont need to send key to ourself");
        continue;
      }

      final deviceKey =
          room.client.userDeviceKeys[event.senderId]?.deviceKeys[device];

      

      var content = {
        "keys": {
          "index": keyIndex,
          "key": base64Encode(bytes),
        },
        "member": {
          "claimed_device_id": room.client.deviceID!
        },
        "room_id": room.id,
        "sent_ts": DateTime.now().millisecondsSinceEpoch,
        "session": {
          "application": "m.call",
          "call_id": "",
          "scope": "m.room",
        }
      };

      Log.i("Sending keys: $content to ${deviceKey!.userId}");

      room.client.sendToDeviceEncrypted(
          [deviceKey], "io.element.call.encryption_keys", content);
    }
  }

  void onToDeviceEvent(mx.ToDeviceEvent event) {
    Log.i(
      "Received to device event: ${event.toJson()}",
    );

    if (event.type == "io.element.call.encryption_keys") {
      var data = event.content["keys"] as Map<String, dynamic>;
      Log.i("Setting encryption key");
      Log.i(data);

      var index = data["index"];
      var key = data["key"] as String;

      var b = base64Decode(key);

      var deviceId = (event.content["member"]
          as Map<String, dynamic>)["claimed_device_id"] as String;

      var participantId = event.senderId + ":" + deviceId;

      Log.i("Particpant: $participantId");

      setRawKey(b, participantId: participantId, keyIndex: index);
    }
  }
}
