import 'dart:convert';
import 'dart:typed_data';

import 'package:commet/client/components/donation_awards/donation_awards_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:crypto/crypto.dart';

import 'package:cryptography/cryptography.dart';

class MatrixDonationAwardsComponent
    implements DonationAwardsComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixDonationAwardsComponent(this.client);

  static const String secretKey = "chat.commet.donations_client_secret";

  @override
  Future<SecretClientIdentifier?> getClientSecret() async {
    var existing = client.matrixClient.accountData[secretKey];

    if (existing != null) {
      var secret = existing.content["secret"];
      var encrypted_hash = existing.content["encrypted_id_hash"];

      if (secret is String && encrypted_hash is String) {
        if (validateSecret(secret)) {
          Log.i("Re-using existing secret");
          return SecretClientIdentifier(
              clientSecret: secret, encryptedHash: encrypted_hash);
        }
      }
    } else {
      Log.i("Generating new client secret");

      var secret = await generateSecret();
      var encryptedIdHash = await getEncryptedUsernameHash(secret);

      Log.i("Generated Secret: $secret");
      Log.i("Generated id hash: $encryptedIdHash");

      await client.matrixClient.setAccountData(client.matrixClient.userID!,
          secretKey, {"secret": secret, "encrypted_id_hash": encryptedIdHash});

      return SecretClientIdentifier(
          clientSecret: secret, encryptedHash: encryptedIdHash);
    }

    Log.e(
        "Failed to get client secret, one already exists, but it is not valid");

    return null;
  }

  Future<String> generateSecret() async {
    final algorithm = AesGcm.with128bits();
    final secretKey = await algorithm.newSecretKey();
    // final nonce = await algorithm.newNonce();

    final secretKeyBytes = Uint8List.fromList(await secretKey.extractBytes());
    // final nonceBytes = Uint8List.fromList(nonce);
    return TextUtils.toHexString(secretKeyBytes);
  }

  bool validateSecret(String secret) {
    // TODO: Reimplement validation
    return true;
  }

  Future<String> getEncryptedUsernameHash(String secret) async {
    final secretBytes = TextUtils.parseHexString(secret);

    final algorithm = AesGcm.with128bits();

    final secretKey = await algorithm.newSecretKeyFromBytes(secretBytes);

    var userIdHash =
        sha256.convert(AsciiEncoder().convert(client.matrixClient.userID!));

    Log.i(
        "Hash: ${TextUtils.toHexString(Uint8List.fromList(userIdHash.bytes))}");

    var nonce = await algorithm.newNonce();

    final encrypted = await algorithm.encrypt(userIdHash.bytes,
        secretKey: secretKey, nonce: nonce);

    final bytes = Uint8List.fromList(encrypted.cipherText);

    Log.i("Iv: ${Uint8List.fromList(nonce)}");
    Log.i("Secret: ${secretBytes}");
    Log.i("Ciphertext: ${bytes}");

    final encryptedUserIdHash = TextUtils.toHexString(
        Uint8List.fromList(bytes + Uint8List.fromList(encrypted.mac.bytes)));

    final iv = TextUtils.toHexString(Uint8List.fromList(nonce));

    return "${iv}_$encryptedUserIdHash";
  }
}
