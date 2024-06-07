import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'package:mime/mime.dart' as mime;

class Mime {
  static const displayableTypes = {
    "image/jpeg",
    "image/png",
    "image/gif",
    "image/bmp",
    "image/webp"
  };

  static const imageTypes = {
    "image/jpeg",
    "image/png",
    "image/gif",
    "image/webp",
    "image/bmp",
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

  static String? lookupType(String filepath, {Uint8List? data}) {
    var resolver = mime.MimeTypeResolver();
    resolver.addMagicNumber([0x42, 0x4d], "image/bmp");
    resolver.addMagicNumber([0x3c, 0x73, 0x76, 0x67], "image/svg+xml"); // '<svg

    return resolver.lookup(filepath, headerBytes: data);
  }
}
