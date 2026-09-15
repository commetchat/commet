import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:web/web.dart' as web;
// ignore: depend_on_referenced_packages
import 'package:webrtc_interface/webrtc_interface.dart' show Algorithm;
import 'e2ee.data_packet_cryptor.dart';
import 'e2ee.frame_cryptor.dart';
import 'e2ee.keyhandler.dart';
import 'e2ee.logger.dart';

@JS()
external web.DedicatedWorkerGlobalScope get self;

var participantCryptors = <FrameCryptor>[];
var participantDataCryptors = <E2EEDataPacketCryptor>[];
var keyProviders = <String, KeyProvider>{};

FrameCryptor getTrackCryptor(String participantIdentity, String trackId, KeyProvider keyProvider) {
  var cryptor = participantCryptors.firstWhereOrNull((c) => c.trackId == trackId);
  if (cryptor == null) {
    logger.info('creating new cryptor for $participantIdentity, trackId $trackId');

    cryptor = FrameCryptor(
      worker: self,
      participantIdentity: participantIdentity,
      trackId: trackId,
      keyHandler: keyProvider.getParticipantKeyHandler(participantIdentity),
    );
    //setupCryptorErrorEvents(cryptor);
    participantCryptors.add(cryptor);
  } else if (participantIdentity != cryptor.participantIdentity) {
    // assign new participant id to track cryptor and pass in correct key handler
    cryptor.setParticipant(participantIdentity, keyProvider.getParticipantKeyHandler(participantIdentity));
  }
  if (keyProvider.keyProviderOptions.sharedKey) {}
  return cryptor;
}

E2EEDataPacketCryptor getDataPacketCryptor(String participantIdentity, String dataCryptorId, KeyProvider keyProvider) {
  var cryptor = participantDataCryptors.firstWhereOrNull((c) => c.dataCryptorId == dataCryptorId);
  if (cryptor == null) {
    logger.info('creating new cryptor for $participantIdentity, dataCryptorId $dataCryptorId');

    cryptor = E2EEDataPacketCryptor(
      worker: self,
      participantIdentity: participantIdentity,
      dataCryptorId: dataCryptorId,
      keyHandler: keyProvider.getParticipantKeyHandler(participantIdentity),
    );
    //setupCryptorErrorEvents(cryptor);
    participantDataCryptors.add(cryptor);
  } else if (participantIdentity != cryptor.participantIdentity) {
    // assign new participant id to track cryptor and pass in correct key handler
    cryptor.setParticipant(participantIdentity, keyProvider.getParticipantKeyHandler(participantIdentity));
  }
  if (keyProvider.keyProviderOptions.sharedKey) {}
  return cryptor;
}

void unsetCryptorParticipant(String trackId) {
  participantCryptors.firstWhereOrNull((c) => c.trackId == trackId)?.unsetParticipant();
}

void unsetDataPacketCryptorParticipant(String dataCryptorId) {
  participantDataCryptors.firstWhereOrNull((c) => c.dataCryptorId == dataCryptorId)?.unsetParticipant();
}

void main() async {
  // configure logs for debugging
  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((record) {
    print('[${record.loggerName}] ${record.level.name}: ${record.message}');
  });

  logger.info('Worker created');

  if (self.hasProperty('RTCTransformEvent'.toJS).toDart) {
    logger.info('setup RTCTransformEvent event handler');
    self.onrtctransform = (web.RTCTransformEvent event) {
      logger.info('Got onrtctransform event');
      final transformer = event.transformer;

      transformer.setProperty('handled'.toJS, true.toJS);

      final options = transformer.options as JSObject;
      final kind = options.getProperty('kind'.toJS) as JSString;
      final participantId = options.getProperty('participantId'.toJS) as JSString;
      final trackId = options.getProperty('trackId'.toJS) as JSString;
      final codec = options.getProperty('codec'.toJS) as JSString?;
      final msgType = options.getProperty('msgType'.toJS) as JSString;
      final keyProviderId = options.getProperty('keyProviderId'.toJS) as JSString;

      final keyProvider = keyProviders[keyProviderId.toDart];

      if (keyProvider == null) {
        logger.warning('KeyProvider not found for $keyProviderId');
        return;
      }

      final cryptor = getTrackCryptor(participantId.toDart, trackId.toDart, keyProvider);

      unawaited(cryptor.setupTransform(
        operation: msgType.toDart,
        readable: transformer.readable,
        writable: transformer.writable,
        trackId: trackId.toDart,
        kind: kind.toDart,
        codec: codec?.toDart,
        isReuse: false,
      ));
    }.toJS;
  }

  // ignore: prefer_function_declarations_over_variables
  final handleMessage = (web.MessageEvent e) async {
    final msg = e.data.dartify() as Map;
    final msgType = msg['msgType'];
    final msgId = msg['msgId'] as String?;
    logger.config('Got message $msgType, msgId $msgId');
    switch (msgType) {
      case 'keyProviderInit':
        {
          final options = msg['keyOptions'];
          final keyProviderId = msg['keyProviderId'] as String;
          final keyProviderOptions = KeyOptions(
              sharedKey: options['sharedKey'],
              ratchetSalt: Uint8List.fromList(base64Decode(options['ratchetSalt'] as String)),
              ratchetWindowSize: options['ratchetWindowSize'],
              failureTolerance: options['failureTolerance'] ?? -1,
              uncryptedMagicBytes: options['uncryptedMagicBytes'] != null
                  ? Uint8List.fromList(base64Decode(options['uncryptedMagicBytes'] as String))
                  : null,
              keyRingSze: options['keyRingSize'] ?? KEYRING_SIZE,
              discardFrameWhenCryptorNotReady: options['discardFrameWhenCryptorNotReady'] ?? false);
          logger.config('Init with keyProviderOptions:\n ${keyProviderOptions.toString()}');

          final keyProvider = KeyProvider(self, keyProviderId, keyProviderOptions);
          keyProviders[keyProviderId] = keyProvider;

          self.postMessage({
            'type': 'init',
            'msgId': msgId,
            'msgType': 'response',
          }.jsify());
          break;
        }
      case 'keyProviderDispose':
        {
          final keyProviderId = msg['keyProviderId'] as String;
          logger.config('Dispose keyProvider $keyProviderId');
          keyProviders.remove(keyProviderId);
          self.postMessage({
            'type': 'dispose',
            'msgId': msgId,
            'msgType': 'response',
          }.jsify());
        }
        break;
      case 'enable':
        {
          final enabled = msg['enabled'] as bool;
          final trackId = msg['trackId'] as String;

          final cryptors = participantCryptors.where((c) => c.trackId == trackId).toList();
          for (var cryptor in cryptors) {
            logger.config('Set enable $enabled for trackId ${cryptor.trackId}');
            cryptor.setEnabled(enabled);
          }
          self.postMessage({
            'type': 'cryptorEnabled',
            'enable': enabled,
            'msgId': msgId,
            'msgType': 'response',
          }.jsify());
        }
        break;
      case 'decode':
      case 'encode':
        {
          final kind = msg['kind'];
          final exist = msg['exist'] as bool;
          final participantId = msg['participantId'] as String;
          final trackId = msg['trackId'];
          final readable = msg['readableStream'] as web.ReadableStream;
          final writable = msg['writableStream'] as web.WritableStream;
          final keyProviderId = msg['keyProviderId'] as String;

          logger.config(
              'SetupTransform for kind $kind, trackId $trackId, participantId $participantId, ${readable.runtimeType} ${writable.runtimeType}}');

          final keyProvider = keyProviders[keyProviderId];
          if (keyProvider == null) {
            logger.warning('KeyProvider not found for $keyProviderId');
            self.postMessage({
              'type': 'cryptorSetup',
              'participantId': participantId,
              'trackId': trackId,
              'exist': exist,
              'operation': msgType,
              'error': 'KeyProvider not found',
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
            return;
          }

          final cryptor = getTrackCryptor(participantId, trackId, keyProvider);

          await cryptor.setupTransform(
            operation: msgType,
            readable: readable,
            writable: writable,
            trackId: trackId,
            kind: kind,
            isReuse: exist && msgType == 'decode',
          );

          self.postMessage({
            'type': 'cryptorSetup',
            'participantId': participantId,
            'trackId': trackId,
            'exist': exist,
            'operation': msgType,
            'msgId': msgId,
            'msgType': 'response',
          }.jsify());
          cryptor.lastError = CryptorError.kNew;
        }
        break;
      case 'removeTransform':
        {
          final trackId = msg['trackId'] as String;
          logger.config('Removing trackId $trackId');
          unsetCryptorParticipant(trackId);
          self.postMessage({
            'type': 'cryptorRemoved',
            'trackId': trackId,
            'msgId': msgId,
            'msgType': 'response',
          }.jsify());
        }
        break;
      case 'setKey':
      case 'setSharedKey':
        {
          final key = Uint8List.fromList(base64Decode(msg['key'] as String));
          final keyIndex = msg['keyIndex'] as int;
          final keyProviderId = msg['keyProviderId'] as String;
          final keyProvider = keyProviders[keyProviderId];
          if (keyProvider == null) {
            logger.warning('KeyProvider not found for $keyProviderId');
            self.postMessage({
              'type': 'setKey',
              'error': 'KeyProvider not found',
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
            return;
          }
          final keyProviderOptions = keyProvider.keyProviderOptions;
          if (keyProviderOptions.sharedKey) {
            logger.config('Set SharedKey keyIndex $keyIndex');
            await keyProvider.setSharedKey(key, keyIndex: keyIndex);
          } else {
            final participantId = msg['participantId'] as String;
            logger.config('Set key for participant $participantId, keyIndex $keyIndex');
            await keyProvider.getParticipantKeyHandler(participantId).setKey(key, keyIndex: keyIndex);
          }

          self.postMessage({
            'type': 'setKey',
            'participantId': msg['participantId'],
            'sharedKey': keyProviderOptions.sharedKey,
            'keyIndex': keyIndex,
            'msgId': msgId,
            'msgType': 'response',
          }.jsify());
        }
        break;
      case 'ratchetKey':
      case 'ratchetSharedKey':
        {
          final keyIndex = msg['keyIndex'];
          final participantId = msg['participantId'] as String;
          final keyProviderId = msg['keyProviderId'] as String;
          final keyProvider = keyProviders[keyProviderId];
          if (keyProvider == null) {
            logger.warning('KeyProvider not found for $keyProviderId');
            self.postMessage({
              'type': 'setKey',
              'error': 'KeyProvider not found',
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
            return;
          }
          final keyProviderOptions = keyProvider.keyProviderOptions;
          Uint8List? newKey;
          if (keyProviderOptions.sharedKey) {
            logger.config('RatchetKey for SharedKey, keyIndex $keyIndex');
            newKey = await keyProvider.getSharedKeyHandler().ratchetKey(keyIndex);
          } else {
            logger.config('RatchetKey for participant $participantId, keyIndex $keyIndex');
            newKey = await keyProvider.getParticipantKeyHandler(participantId).ratchetKey(keyIndex);
          }

          self.postMessage({
            'type': 'ratchetKey',
            'sharedKey': keyProviderOptions.sharedKey,
            'participantId': participantId,
            'newKey': newKey != null ? base64Encode(newKey) : '',
            'keyIndex': keyIndex,
            'msgId': msgId,
            'msgType': 'response',
          }.jsify());
        }
        break;
      case 'setKeyIndex':
        {
          final keyIndex = msg['index'];
          final trackId = msg['trackId'] as String;
          logger.config('Setup key index for track $trackId');
          final cryptors = participantCryptors.where((c) => c.trackId == trackId).toList();
          for (var c in cryptors) {
            logger.config('Set keyIndex for trackId ${c.trackId}');
            c.setKeyIndex(keyIndex);
          }

          self.postMessage({
            'type': 'setKeyIndex',
            'keyIndex': keyIndex,
            'msgId': msgId,
            'msgType': 'response',
          }.jsify());
        }
        break;
      case 'exportKey':
      case 'exportSharedKey':
        {
          final keyIndex = msg['keyIndex'] as int;
          final participantId = msg['participantId'] as String;
          final keyProviderId = msg['keyProviderId'] as String;
          final keyProvider = keyProviders[keyProviderId];
          if (keyProvider == null) {
            logger.warning('KeyProvider not found for $keyProviderId');
            self.postMessage({
              'type': 'setKey',
              'error': 'KeyProvider not found',
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
            return;
          }
          final keyProviderOptions = keyProvider.keyProviderOptions;
          Uint8List? key;
          if (keyProviderOptions.sharedKey) {
            logger.config('Export SharedKey keyIndex $keyIndex');
            key = await keyProvider.getSharedKeyHandler().exportKey(keyIndex);
          } else {
            logger.config('Export key for participant $participantId, keyIndex $keyIndex');
            key = await keyProvider.getParticipantKeyHandler(participantId).exportKey(keyIndex);
          }
          self.postMessage({
            'type': 'exportKey',
            'participantId': participantId,
            'keyIndex': keyIndex,
            'exportedKey': key != null ? base64Encode(key) : '',
            'msgId': msgId,
            'msgType': 'response',
          }.jsify());
        }
        break;
      case 'setSifTrailer':
        {
          final sifTrailer = Uint8List.fromList(base64Decode(msg['sifTrailer'] as String));
          final keyProviderId = msg['keyProviderId'] as String;
          final keyProvider = keyProviders[keyProviderId];
          if (keyProvider == null) {
            logger.warning('KeyProvider not found for $keyProviderId');
            self.postMessage({
              'type': 'setKey',
              'error': 'KeyProvider not found',
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
            return;
          }
          keyProvider.setSifTrailer(sifTrailer);
          logger.config('SetSifTrailer = $sifTrailer');
          for (var c in participantCryptors) {
            c.setSifTrailer(sifTrailer);
          }

          self.postMessage({
            'type': 'setSifTrailer',
            'msgId': msgId,
            'msgType': 'response',
          }.jsify());
        }
        break;
      case 'updateCodec':
        {
          final codec = msg['codec'] as String;
          final trackId = msg['trackId'] as String;
          logger.config('Update codec for trackId $trackId, codec $codec');
          final cryptor = participantCryptors.firstWhereOrNull((c) => c.trackId == trackId);
          cryptor?.updateCodec(codec);

          self.postMessage({
            'type': 'updateCodec',
            'msgId': msgId,
            'msgType': 'response',
          }.jsify());
        }
        break;
      case 'dispose':
        {
          final trackId = msg['trackId'] as String;
          logger.config('Dispose for trackId $trackId');
          final cryptor = participantCryptors.firstWhereOrNull((c) => c.trackId == trackId);
          if (cryptor != null) {
            cryptor.lastError = CryptorError.kDisposed;
            self.postMessage({
              'type': 'cryptorDispose',
              'participantId': cryptor.participantIdentity,
              'trackId': trackId,
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
          } else {
            self.postMessage({
              'type': 'cryptorDispose',
              'error': 'cryptor not found',
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
          }
        }
        break;
      case 'dataCryptorEncrypt':
        {
          final participantId = msg['participantId'] as String;
          final data = msg['data'] as Uint8List;
          final keyIndex = msg['keyIndex'] as int;
          final dataCryptorId = msg['dataCryptorId'] as String;
          final algorithmStr = msg['algorithm'] as String;
          final algorithm = Algorithm.values.firstWhereOrNull((a) => a.name == algorithmStr);
          if (algorithm == null) {
            self.postMessage({
              'type': 'dataCryptorEncrypt',
              'error': 'algorithm not found',
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
            return;
          }
          logger.config(
              'Encrypt for dataCryptorId $dataCryptorId, participantId $participantId, keyIndex $keyIndex, data length ${data.length}, algorithm $algorithmStr');
          final keyProviderId = msg['keyProviderId'] as String;
          final keyProvider = keyProviders[keyProviderId];
          if (keyProvider == null) {
            logger.warning('KeyProvider not found for $keyProviderId');
            self.postMessage({
              'type': 'dataCryptorEncrypt',
              'error': 'KeyProvider not found',
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
            return;
          }
          final cryptor = getDataPacketCryptor(participantId, dataCryptorId, keyProvider);
          try {
            final encryptedPacket = await cryptor.encrypt(cryptor.keyHandler, data);
            self.postMessage({
              'type': 'dataCryptorEncrypt',
              'participantId': participantId,
              'dataCryptorId': dataCryptorId,
              'data': encryptedPacket!.data,
              'keyIndex': encryptedPacket.keyIndex,
              'iv': encryptedPacket.iv,
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
          } catch (e) {
            logger.warning('Error encrypting data: $e');
            self.postMessage({
              'type': 'dataCryptorEncrypt',
              'error': e.toString(),
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
          }
        }
        break;
      case 'dataCryptorDecrypt':
        {
          final participantId = msg['participantId'] as String;
          final data = msg['data'] as Uint8List;
          final iv = msg['iv'] as Uint8List;
          final keyIndex = msg['keyIndex'] as int;
          final dataCryptorId = msg['dataCryptorId'] as String;
          final algorithmStr = msg['algorithm'] as String;
          final algorithm = Algorithm.values.firstWhereOrNull((a) => a.name == algorithmStr);
          if (algorithm == null) {
            self.postMessage({
              'type': 'dataCryptorDecrypt',
              'error': 'algorithm not found',
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
            return;
          }
          logger.config(
              'Decrypt for dataCryptorId $dataCryptorId, participantId $participantId, keyIndex $keyIndex, data length ${data.length}, algorithm $algorithmStr');
          final keyProviderId = msg['keyProviderId'] as String;
          final keyProvider = keyProviders[keyProviderId];
          if (keyProvider == null) {
            logger.warning('KeyProvider not found for $keyProviderId');
            self.postMessage({
              'type': 'dataCryptorDecrypt',
              'error': 'KeyProvider not found',
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
            return;
          }
          final cryptor = getDataPacketCryptor(participantId, dataCryptorId, keyProvider);
          try {
            final decryptedData = await cryptor.decrypt(
                cryptor.keyHandler,
                EncryptedPacket(
                  data: data,
                  keyIndex: keyIndex,
                  iv: iv,
                ));
            self.postMessage({
              'type': 'dataCryptorDecrypt',
              'participantId': participantId,
              'dataCryptorId': dataCryptorId,
              'data': decryptedData,
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
          } catch (e) {
            logger.warning('Error decrypting data: $e');
            self.postMessage({
              'type': 'dataCryptorDecrypt',
              'error': e.toString(),
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
          }
        }
        break;
      case 'dataCryptorDispose':
        {
          final dataCryptorId = msg['dataCryptorId'] as String;
          logger.config('Dispose for dataCryptorId $dataCryptorId');
          unsetDataPacketCryptorParticipant(dataCryptorId);
          self.postMessage({
            'type': 'dataCryptorDispose',
            'dataCryptorId': dataCryptorId,
            'msgId': msgId,
            'msgType': 'response',
          }.jsify());
        }
        break;
      default:
        logger.warning('Unknown message kind $msg');
    }
  };

  self.onmessage = (web.MessageEvent e) {
    unawaited(handleMessage(e));
  }.toJS;
}
