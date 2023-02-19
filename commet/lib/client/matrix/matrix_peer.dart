import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixPeer extends Peer {
  late matrix.Client _matrixClient;

  MatrixPeer(matrix.Client matrixClient, String userId) {
    _matrixClient = matrixClient;
    identifier = userId;
    init();
  }

  void init() async {
    try {
      var name = await _matrixClient.getDisplayName(identifier);
      if (name != null) displayName = name;

      var avatarUrl = await _matrixClient.getAvatarUrl(identifier);
      var url = avatarUrl!.getThumbnail(_matrixClient, width: 56, height: 56).toString();
      if (avatarUrl != null) avatar = NetworkImage(url);
    } catch (_) {
      print("Unable to retreive profile info for: " + identifier);
    }
  }
}
