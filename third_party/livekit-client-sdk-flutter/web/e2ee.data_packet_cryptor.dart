import 'dart:async';
import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'e2ee.keyhandler.dart';
import 'e2ee.logger.dart';

class EncryptedPacket {
  EncryptedPacket({
    required this.data,
    required this.keyIndex,
    required this.iv,
  });

  Uint8List data;
  int keyIndex;
  Uint8List iv;
}

class E2EEDataPacketCryptor {
  E2EEDataPacketCryptor({
    required this.worker,
    required this.participantIdentity,
    required this.dataCryptorId,
    required this.keyHandler,
  });
  int sendCount_ = -1;
  String? participantIdentity;
  String? dataCryptorId;
  ParticipantKeyHandler keyHandler;
  KeyOptions get keyOptions => keyHandler.keyOptions;
  int currentKeyIndex = 0;
  final web.DedicatedWorkerGlobalScope worker;

  void setParticipant(String identity, ParticipantKeyHandler keys) {
    participantIdentity = identity;
    keyHandler = keys;
  }

  void unsetParticipant() {
    participantIdentity = null;
  }

  void setKeyIndex(int keyIndex) {
    logger.config('setKeyIndex for $participantIdentity, newIndex: $keyIndex');
    currentKeyIndex = keyIndex;
  }

  Uint8List makeIv({required int timestamp}) {
    final iv = ByteData(IV_LENGTH);

    // having to keep our own send count (similar to a picture id) is not ideal.
    if (sendCount_ == -1) {
      // Initialize with a random offset, similar to the RTP sequence number.
      sendCount_ = Random.secure().nextInt(0xffff);
    }

    final sendCount = sendCount_;
    final randomBytes = Random.secure().nextInt(max(0, 0xffffffff)).toUnsigned(32);

    iv.setUint32(0, randomBytes);
    iv.setUint32(4, timestamp);
    iv.setUint32(8, timestamp - (sendCount % 0xffff));

    sendCount_ = sendCount + 1;

    return iv.buffer.asUint8List();
  }

  void postMessage(Object message) {
    worker.postMessage(message.jsify());
  }

  Future<EncryptedPacket?> encrypt(
    ParticipantKeyHandler keys,
    Uint8List data,
  ) async {
    logger.fine('encodeFunction: buffer ${data.length}');

    final secretKey = keyHandler.getKeySet(currentKeyIndex)?.encryptionKey;
    final keyIndex = currentKeyIndex;

    if (secretKey == null) {
      logger.warning('encodeFunction: no secretKey for index $keyIndex, cannot encrypt');
      return null;
    }

    final iv = makeIv(timestamp: DateTime.timestamp().millisecondsSinceEpoch);

    final frameTrailer = ByteData(2);
    frameTrailer.setInt8(0, IV_LENGTH);
    frameTrailer.setInt8(1, keyIndex);

    try {
      final cipherText = await worker.crypto.subtle
          .encrypt(
            {
              'name': 'AES-GCM',
              'iv': iv,
            }.jsify() as web.AlgorithmIdentifier,
            secretKey,
            data.toJS,
          )
          .toDart as JSArrayBuffer;

      logger.finer(
          'encodeFunction: encrypted buffer: ${data.length}, cipherText: ${cipherText.toDart.asUint8List().length}');

      return EncryptedPacket(
        data: cipherText.toDart.asUint8List(),
        keyIndex: keyIndex,
        iv: iv,
      );
    } catch (e) {
      logger.warning('encodeFunction encrypt: e ${e.toString()}');
      rethrow;
    }
  }

  Future<Uint8List?> decrypt(
    ParticipantKeyHandler keys,
    EncryptedPacket encryptedPacket,
  ) async {
    var ratchetCount = 0;

    logger.fine('decodeFunction: data packet length ${encryptedPacket.data.length}');

    ByteBuffer? decrypted;
    KeySet? initialKeySet;
    final initialKeyIndex = currentKeyIndex;

    try {
      final ivLength = encryptedPacket.iv.length;
      final keyIndex = encryptedPacket.keyIndex;
      final iv = encryptedPacket.iv;
      final payload = encryptedPacket.data;
      initialKeySet = keyHandler.getKeySet(initialKeyIndex);

      logger.finer(
          'decodeFunction: start decrypting data packet length ${payload.length}, ivLength $ivLength, keyIndex $keyIndex, iv $iv');

      /// missingKey flow:
      /// tries to decrypt once, fails, tries to ratchet once and decrypt again,
      /// fails (does not save ratcheted key), bumps _decryptionFailureCount,
      /// if higher than failuretolerance hasValidKey is set to false, on next
      /// frame it fires a missingkey
      /// to throw missingkeys faster lower your failureTolerance
      if (initialKeySet == null || !keyHandler.hasValidKey) {
        return null;
      }
      var currentkeySet = initialKeySet;

      Future<void> decryptFrameInternal() async {
        decrypted = ((await worker.crypto.subtle
                .decrypt(
                  {
                    'name': 'AES-GCM',
                    'iv': iv,
                  }.jsify() as web.AlgorithmIdentifier,
                  currentkeySet.encryptionKey,
                  payload.toJS,
                )
                .toDart) as JSArrayBuffer)
            .toDart;
        logger.finer('decodeFunction::decryptFrameInternal: decrypted: ${decrypted!.asUint8List().length}');

        if (decrypted == null) {
          throw Exception('[decryptFrameInternal] could not decrypt');
        }
        logger.finer('decodeFunction::decryptFrameInternal: decrypted: ${decrypted!.asUint8List().length}');
        if (currentkeySet != initialKeySet) {
          logger.fine('decodeFunction::decryptFrameInternal: ratchetKey: decryption ok, newState: kKeyRatcheted');
          await keyHandler.setKeySetFromMaterial(currentkeySet, initialKeyIndex);
        }
      }

      Future<void> ratchetKeyInternal() async {
        if (ratchetCount >= keyOptions.ratchetWindowSize || keyOptions.ratchetWindowSize <= 0) {
          throw Exception('[ratchetKeyInternal] cannot ratchet anymore');
        }

        final newKeyBuffer = await keyHandler.ratchet(currentkeySet.material, keyOptions.ratchetSalt);
        final newMaterial = await keyHandler.ratchetMaterial(currentkeySet.material, newKeyBuffer.buffer);
        currentkeySet = await keyHandler.deriveKeys(newMaterial, keyOptions.ratchetSalt);
        ratchetCount++;
        await decryptFrameInternal();
      }

      try {
        /// gets frame -> tries to decrypt -> tries to ratchet (does this failureTolerance
        /// times, then says missing key)
        /// we only save the new key after ratcheting if we were able to decrypt something
        await decryptFrameInternal();
      } catch (e) {
        logger.finer('decodeFunction: kInternalError catch $e');
        await ratchetKeyInternal();
      }

      if (decrypted == null) {
        throw Exception('[decodeFunction] decryption failed even after ratcheting');
      }

      // we can now be sure that decryption was a success
      keyHandler.decryptionSuccess();

      logger.finer(
          'decodeFunction: decryption success, buffer length ${payload.length}, decrypted: ${decrypted!.asUint8List().length}');

      return decrypted!.asUint8List();
    } catch (e) {
      keyHandler.decryptionFailure();
      rethrow;
    }
  }
}
