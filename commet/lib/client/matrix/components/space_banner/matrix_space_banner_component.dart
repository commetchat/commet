import 'dart:typed_data';

import 'package:commet/client/components/space_banner/space_banner_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_space.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/src/painting/image_provider.dart';

class MatrixSpaceBannerComponent
    implements SpaceBannerComponent<MatrixClient, MatrixSpace> {
  static const String key = "page.codeberg.everypizza.room.banner";

  @override
  ImageProvider<Object>? get banner {
    final state = space.matrixRoom.getState(key);
    if (state == null) return null;

    final url = state.content["url"] as String?;
    if (url == null) return null;

    return MatrixMxcImage(Uri.parse(url), client.matrixClient);
  }

  @override
  MatrixClient client;

  @override
  MatrixSpace space;

  MatrixSpaceBannerComponent(this.client, this.space);

  @override
  Future<void> setBanner(Uint8List data, {String? mimeType}) async {
    var uploadResponse =
        await client.matrixClient.uploadContent(data, contentType: mimeType);

    await client.matrixClient.setRoomStateWithKey(
      space.matrixRoom.id,
      key,
      '',
      {
        'url': uploadResponse.toString(),
        if (mimeType != null) 'mimetype': mimeType,
      },
    );
    space.notifyUpdate();
  }

  @override
  bool get canEditBanner => space.matrixRoom.canChangeStateEvent(key);
}
