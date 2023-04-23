import 'package:matrix/matrix.dart';

class Mime {
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
