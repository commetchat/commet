import 'dart:convert';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/debug/log.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

class SecretClientIdentifier {
  String encryptedHash;
  String clientSecret;

  SecretClientIdentifier(
      {required this.encryptedHash, required this.clientSecret});
}

abstract class DonationAwardsComponent<T extends Client>
    implements Component<T> {
  Future<SecretClientIdentifier?> getClientSecret();

  Future<void> acceptAwards(List<Map<String, dynamic>> awards);
}

class DonationAward {
  ImageProvider image;
  String title;
  Map<String, dynamic> data;

  DonationAward({required this.image, required this.title, required this.data});

  static DonationAward fromJsonMatrix(
      Map<String, dynamic> data, MatrixClient client) {
    return DonationAward(
        data: data,
        image: MatrixMxcImage(
            Uri.parse(data["signed"]["content"]["image"]), client.matrixClient,
            doFullres: true, doThumbnail: false, autoLoadFullRes: true),
        title: data["signed"]["content"]["body"]);
  }
}

class DonationAwardsClient {
  Uri host;
  Client client;

  DonationAwardsClient(this.host, this.client);

  Future<List<DonationAward>?> getAwards(SecretClientIdentifier identifier,
      {DateTime? since}) async {
    var path = host.replace(path: "/awards", queryParameters: {
      if (since != null)
        "since": (since.millisecondsSinceEpoch / 1000).toInt().toString(),
      "client_reference_id": identifier.encryptedHash,
      "secret": identifier.clientSecret,
    });

    Log.d("Fetching url: $path");
    var result = await http.get(path);

    if (result.statusCode != 200) {
      Log.d("No new donations found");
      return null;
    }

    try {
      var response = jsonDecode(result.body) as List<dynamic>;
      var awards = response
          .map((i) => DonationAward.fromJsonMatrix(i, client as MatrixClient));

      Log.d(response);

      return awards.toList();
    } catch (e, s) {
      Log.onError(e, s);
      return null;
    }
  }
}
