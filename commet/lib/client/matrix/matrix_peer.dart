import 'dart:math';

import 'package:commet/cache/cache_file_provider.dart';
import 'package:commet/client/client.dart';
import 'package:commet/cache/file_image.dart';
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

    userName = identifier.split('@').last.split(':').first;
    detail = identifier.split(':').last;
    var generatedColor = Random().nextInt(Colors.primaries.length);
    color = Colors.primaries[generatedColor];

    refreshAvatar();
  }

  Future<void> refreshAvatar() async {
    Uri? avatarUrl;
    try {
      avatarUrl = await _matrixClient.getAvatarUrl(identifier);
    } catch (_) {}

    if (avatarUrl != null) {
      avatar = FileImageProvider(
          CacheFileProvider.thumbnail(avatarUrl.toString(), () async {
        return (await _matrixClient.httpClient.get(
                avatarUrl!.getThumbnail(_matrixClient, width: 64, height: 64)))
            .bodyBytes;
      }));
    }
  }
}
