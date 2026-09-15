// Copyright 2024 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../logger.dart';

const defaultRatchetSalt = 'LKFrameEncryptionKey';
const defaultMagicBytes = 'LK-ROCKS';
const defaultRatchetWindowSize = 16;
const defaultFailureTolerance = -1;
const defaultKeyRingSize = 16;
const defaultDiscardFrameWhenCryptorNotReady = false;

class KeyInfo {
  final String participantId;
  final int keyIndex;
  final Uint8List key;
  KeyInfo({
    required this.participantId,
    required this.keyIndex,
    required this.key,
  });
}

abstract class KeyProvider {
  Future<void> setSharedKey(String key, {int? keyIndex});
  Future<Uint8List> ratchetSharedKey({int? keyIndex});
  Future<Uint8List> exportSharedKey({int? keyIndex});
  Future<void> setKey(String key, {String? participantId, int? keyIndex});
  Future<void> setRawKey(Uint8List key, {String? participantId, int? keyIndex});
  Future<Uint8List> ratchetKey(String participantId, int? keyIndex);
  Future<Uint8List> exportKey(String participantId, int? keyIndex);
  Future<void> setSifTrailer(Uint8List trailer);
  rtc.KeyProvider get keyProvider;
}

class BaseKeyProvider implements KeyProvider {
  final Map<String, int> _latestSetIndex = {};
  final Map<String, Map<int, Uint8List>> _keys = {};

  int getLatestIndex(String participantId) {
    return _latestSetIndex[participantId] ?? 0;
  }

  Uint8List? _sharedKey;
  final rtc.KeyProviderOptions options;
  final rtc.KeyProvider _keyProvider;
  @override
  rtc.KeyProvider get keyProvider => _keyProvider;

  Uint8List? get sharedKey => _sharedKey;

  BaseKeyProvider(this._keyProvider, this.options);

  static Future<BaseKeyProvider> create({
    bool sharedKey = true,
    String? ratchetSalt,
    String? uncryptedMagicBytes,
    int? ratchetWindowSize,
    int? failureTolerance,
    int? keyRingSize,
    bool? discardFrameWhenCryptorNotReady,
  }) async {
    final rtc.KeyProviderOptions options = rtc.KeyProviderOptions(
        sharedKey: sharedKey,
        ratchetSalt: Uint8List.fromList((ratchetSalt ?? defaultRatchetSalt).codeUnits),
        ratchetWindowSize: ratchetWindowSize ?? defaultRatchetWindowSize,
        uncryptedMagicBytes: Uint8List.fromList((uncryptedMagicBytes ?? defaultMagicBytes).codeUnits),
        failureTolerance: failureTolerance ?? defaultFailureTolerance,
        keyRingSize: keyRingSize ?? defaultKeyRingSize,
        discardFrameWhenCryptorNotReady: defaultDiscardFrameWhenCryptorNotReady);
    final keyProvider = await rtc.frameCryptorFactory.createDefaultKeyProvider(options);
    return BaseKeyProvider(keyProvider, options);
  }

  @override
  Future<void> setSharedKey(String key, {int? keyIndex}) async {
    _sharedKey = Uint8List.fromList(key.codeUnits);
    return _keyProvider.setSharedKey(key: _sharedKey!, index: keyIndex ?? 0);
  }

  @override
  Future<Uint8List> ratchetSharedKey({int? keyIndex}) async {
    if (_sharedKey == null) {
      throw Exception('shared key not set');
    }
    _sharedKey = await _keyProvider.ratchetSharedKey(index: keyIndex ?? 0);
    return _sharedKey!;
  }

  @override
  Future<Uint8List> exportSharedKey({int? keyIndex}) async {
    if (_sharedKey == null) {
      throw Exception('shared key not set');
    }
    return _keyProvider.exportSharedKey(index: keyIndex ?? 0);
  }

  @override
  Future<Uint8List> ratchetKey(String participantId, int? keyIndex) =>
      _keyProvider.ratchetKey(participantId: participantId, index: keyIndex ?? 0);

  @override
  Future<Uint8List> exportKey(String participantId, int? keyIndex) =>
      _keyProvider.exportKey(participantId: participantId, index: keyIndex ?? 0);

  @override
  Future<void> setKey(String key, {String? participantId, int? keyIndex}) async {
    if (options.sharedKey) {
      return setSharedKey(key, keyIndex: keyIndex);
    }
    final keyInfo = KeyInfo(
      participantId: participantId ?? '',
      keyIndex: keyIndex ?? 0,
      key: Uint8List.fromList(key.codeUnits),
    );
    return _setKey(keyInfo);
  }

  @override
  Future<void> setRawKey(Uint8List key, {String? participantId, int? keyIndex}) async {
    return setKey(String.fromCharCodes(key), participantId: participantId, keyIndex: keyIndex);
  }

  Future<void> _setKey(KeyInfo keyInfo) async {
    if (!_keys.containsKey(keyInfo.participantId)) {
      _keys[keyInfo.participantId] = {};
    }
    logger.info('_setKey for ${keyInfo.participantId}, idx: ${keyInfo.keyIndex}, key: ${base64Encode(keyInfo.key)}');
    _keys[keyInfo.participantId]![keyInfo.keyIndex] = keyInfo.key;
    _latestSetIndex[keyInfo.participantId] = keyInfo.keyIndex;
    await _keyProvider.setKey(
      participantId: keyInfo.participantId,
      index: keyInfo.keyIndex,
      key: keyInfo.key,
    );
  }

  @override
  Future<void> setSifTrailer(Uint8List trailer) async {
    return _keyProvider.setSifTrailer(trailer: trailer);
  }
}
