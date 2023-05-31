import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixPeer extends Peer {
  late matrix.Client _matrixClient;

  MatrixPeer(matrix.Client matrixClient, String userId) {
    _matrixClient = matrixClient;
    identifier = userId;
    displayName = userId;
    init();
  }

  void init() async {
    String? name;

    try {
      name = await _matrixClient.getDisplayName(identifier);
    } catch (_) {}
    if (name != null) displayName = name;

    hashColor("ABCDEFG");

    userName = identifier.split('@').last.split(':').first;
    detail = identifier.split(':').last;

    refreshAvatar();
  }

  Future<void> refreshAvatar() async {
    Uri? avatarUrl;
    try {
      avatarUrl = await _matrixClient.getAvatarUrl(identifier);
    } catch (_) {}

    if (avatarUrl != null) {
      avatar = MatrixMxcImage(avatarUrl, _matrixClient);
    }
  }

  // Matching color calculation that other clients use. Element, Cinny, Etc.
  // https://github.com/cinnyapp/cinny/blob/dev/src/util/colorMXID.js
  static Color hashColor(String userId) {
    int hash = 0;

    const colors = [
      Color.fromRGBO(54, 139, 214, 1),
      Color.fromRGBO(172, 59, 168, 1),
      Color.fromRGBO(3, 179, 129, 1),
      Color.fromRGBO(230, 79, 122, 1),
      Color.fromRGBO(255, 129, 45, 1),
      Color.fromRGBO(45, 194, 197, 1),
      Color.fromRGBO(92, 86, 245, 1),
      Color.fromRGBO(116, 209, 44, 1),
    ];

    for (int i = 0; i < userId.length; i++) {
      var chr = userId.codeUnitAt(i);
      hash = ((hash << 5) - hash) + chr;
      hash |= 0;
      hash = BigInt.from(hash).toSigned(32).toInt();
    }

    var index = hash.abs() % 8;

    return colors[index];
  }
}
