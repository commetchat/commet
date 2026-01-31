import 'dart:convert';
import 'dart:typed_data';

import 'package:commet/debug/log.dart';
import 'package:livekit_client/livekit_client.dart' hide KeyProvider;
import 'package:webrtc_interface/src/frame_cryptor.dart';

import 'package:matrix/matrix.dart' as mx;

class MatrixLivekitEncryptionKeyProvider implements BaseKeyProvider {
  mx.Room room;
  Room? lkRoom;

  BaseKeyProvider _keyProvider;

  MatrixLivekitEncryptionKeyProvider(this._keyProvider, this.room) {
    room.client.onToDeviceEvent.stream.listen(onToDeviceEvent);
  }

  static Future<MatrixLivekitEncryptionKeyProvider> create(mx.Room room) async {
    var provider = await BaseKeyProvider.create(
      sharedKey: false,
      ratchetWindowSize: 10,
      keyRingSize: 255,
      failureTolerance: -1,
    );

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

  void onToDeviceEvent(mx.ToDeviceEvent event) {
    Log.i(
      "Received to device event: ${event.toJson()}",
    );

    if (event.type == "io.element.call.encryption_keys") {
      var data = event.content["keys"] as Map<String, dynamic>;

      var index = data["index"];
      var key = data["key"] as String;

      var b = base64Decode(key);

      var deviceId = (event.content["member"]
          as Map<String, dynamic>)["claimed_device_id"] as String;

      var participantId = event.senderId + ":" + deviceId;

      setRawKey(b, keyIndex: index, participantId: participantId);
    }
  }
}
