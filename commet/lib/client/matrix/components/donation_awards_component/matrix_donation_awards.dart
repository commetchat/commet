import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:commet/client/components/donation_awards/donation_awards_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/debug/log.dart';
import 'package:crypto/crypto.dart';

class MatrixDonationAwardsComponent
    implements DonationAwardsComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixDonationAwardsComponent(this.client);

  static const String secretKey = "chat.commet.donation_awards_client_secret";

  @override
  Future<String?> getClientSecret() async {
    var existing = client.matrixClient.accountData[secretKey];
    if (existing != null) {
      var secret = existing.content["secret"];
      if (secret is String) {
        if (validateSecret(secret)) {
          Log.i("Re-using existing secret");
          return secret;
        }
      }
    } else {
      Log.i("Generating new client secret");
      var secret = generateSecret();
      await client.matrixClient.setAccountData(
          client.matrixClient.userID!, secretKey, {"secret": secret});
      return secret;
    }

    Log.e(
        "Failed to get client secret, one already exists, but it is not valid");

    return null;
  }

  String generateSecret() {
    var random = Random.secure();

    Uint8List randomPart = Uint8List(32);

    for (int i = 0; i < randomPart.length; i++) {
      randomPart[i] = random.nextInt(255);
    }

    final clientRandomString = _toHexString(randomPart);

    var hash =
        sha256.convert(AsciiEncoder().convert(client.matrixClient.userID!));

    var hashString = _toHexString(Uint8List.fromList(hash.bytes));

    var secret = "$hashString-$clientRandomString";

    assert(secret.length < 200);

    return secret;
  }

  String _toHexString(Uint8List bytes) {
    return bytes.fold<String>(
        '', (str, byte) => str + byte.toRadixString(16).padLeft(2, '0'));
  }

  bool validateSecret(String secret) {
    var split = secret.split("-");

    var hash = split[0];

    var correctHash =
        sha256.convert(AsciiEncoder().convert(client.matrixClient.userID!));

    var hashString = _toHexString(Uint8List.fromList(correctHash.bytes));

    if (hash != hashString) {
      return false;
    }

    var random = split[1];

    if (random.length != 64) {
      return false;
    }

    return true;
  }
}
