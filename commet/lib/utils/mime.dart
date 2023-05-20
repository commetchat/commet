import 'package:matrix/matrix.dart';

class Mime {
  static const displayableTypes = {"image/jpeg", "image/png", "image/gif"};

  static const imageTypes = {
    "image/jpeg",
    "image/png",
    "image/gif",
    "image/webp"
  };

  static const videoTypes = {"video/mp4"};

  static String? fromExtenstion(String extension) {
    var types = {
      "jpeg": "image/jpeg",
      "jpg": "image/jpeg",
      "png": "image/png",
      "gif": "image/gif",
      "webp": "image/webp",
      "bmp": "image/bmp"
    };
    return types.tryGet(extension);
  }
}
