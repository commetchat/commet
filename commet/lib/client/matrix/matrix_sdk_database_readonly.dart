import 'dart:typed_data';

import 'package:matrix/matrix.dart';

class MatrixSdkDatabaseReadonly extends MatrixSdkDatabase {
  MatrixSdkDatabaseReadonly(
    super.name, {
    super.database,
    super.idbFactory,
    super.maxFileSize = 0,
    super.fileStoragePath,
    super.deleteFilesAfterDuration,
  });

  @override
  Future<int> insertClient(
      String name,
      String homeserverUrl,
      String token,
      String userId,
      String? deviceId,
      String? deviceName,
      String? prevBatch,
      String? olmAccount) async {
    return 0;
  }

  @override
  Future<void> storePrevBatch(String prevBatch) async {}

  @override
  Future<void> storePresence(String userId, CachedPresence presence) async {}

  @override
  Future<void> storeAccountData(String type, String content) async {}

  @override
  Future<void> deleteOldFiles(int savedAt) async {}

  @override
  Future<void> addSeenDeviceId(
      String userId, String deviceId, String publicKeys) async {}

  @override
  Future<void> addSeenPublicKey(String publicKey, String deviceId) async {}

  @override
  Future<void> storeUserDeviceKey(String userId, String deviceId,
      String content, bool verified, bool blocked, int lastActive) async {}

  @override
  Future<void> storeEventUpdate(EventUpdate eventUpdate, Client client) async {}

  @override
  Future<void> storeFile(Uri mxcUri, Uint8List bytes, int time) async {}

  @override
  Future<void> storeInboundGroupSession(
      String roomId,
      String sessionId,
      String pickle,
      String content,
      String indexes,
      String allowedAtIndex,
      String senderKey,
      String senderClaimedKey) async {}

  @override
  Future<void> storeOlmSession(String identityKey, String sessionId,
      String pickle, int lastReceived) async {}

  @override
  Future<void> storeOutboundGroupSession(
      String roomId, String pickle, String deviceIds, int creationTime) async {}

  @override
  Future<void> storeRoomUpdate(
      String roomId, SyncRoomUpdate roomUpdate, Client client) async {}

  @override
  Future<void> storeSSSSCache(
      String type, String keyId, String ciphertext, String content) async {}

  @override
  Future<void> storeSyncFilterId(String syncFilterId) async {}

  @override
  Future<void> storeUserCrossSigningKey(String userId, String publicKey,
      String content, bool verified, bool blocked) async {}

  @override
  Future<void> storeUserDeviceKeysInfo(String userId, bool outdated) async {}
}
