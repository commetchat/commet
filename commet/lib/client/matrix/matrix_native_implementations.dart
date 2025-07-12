import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart';
import 'package:matrix/matrix.dart'
    show NativeImplementationsIsolate, MatrixImageFileResizedResponse;

import 'package:blurhash_dart/blurhash_dart.dart';

class NativeImplementationsCustom extends NativeImplementationsIsolate {
  NativeImplementationsCustom(super.compute);

  @override
  FutureOr<MatrixImageFileResizedResponse?> calcImageMetadata(Uint8List bytes,
      {bool retryInDummy = false}) async {
    return await runInBackground(_calcImageMetadata, bytes);
  }

  MatrixImageFileResizedResponse? _calcImageMetadata(
    Uint8List bytes, {
    bool retryInDummy = false,
  }) {
    final image = decodeImage(bytes);
    if (image == null) return null;

    var blurhashImage = image;

    if (image.height * image.width > 128 * 128) {
      int? width;
      int? height;

      if (image.height > image.width) {
        height = 128;
      } else {
        width = 128;
      }

      blurhashImage =
          copyResize(image, width: width, height: height, maintainAspect: true);
    }

    String blurhash = BlurHash.encode(
      blurhashImage,
      numCompX: 4,
      numCompY: 3,
    ).hash;

    return MatrixImageFileResizedResponse(
      bytes: bytes,
      width: image.width,
      height: image.height,
      blurhash: blurhash,
    );
  }
}
