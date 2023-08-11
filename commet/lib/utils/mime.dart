import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class Mime {
  static const displayableTypes = {"image/jpeg", "image/png", "image/gif"};

  static const imageTypes = {
    "image/jpeg",
    "image/png",
    "image/gif",
    "image/webp"
  };

  static const videoTypes = {"video/mp4", "video/mpeg"};

  static const archiveTypes = {
    "application/x-7z-compressed",
    "application/x-bzip",
    "application/x-bzip2",
    "application/gzip"
  };

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

  static IconData toIcon(String? mimeType) {
    if (imageTypes.contains(mimeType)) return Icons.image;
    if (videoTypes.contains(mimeType)) return Icons.video_file_rounded;
    if (archiveTypes.contains(mimeType)) return Icons.folder_zip_outlined;

    return Icons.file_present;
  }
}
