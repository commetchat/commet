import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'package:mime/mime.dart' as mime;

class Mime {
  static const displayableImageTypes = {
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

  static const playableAudioTypes = {
    "audio/x-wav",
    "audio/ogg",
    "audio/wav",
    "audio/mp3",
    "audio/mpeg",
  };

  static bool isText(String mime) => mime.startsWith("text/");

  static const videoTypes = {
    "video/mp4",
    "video/mpeg",
    "video/webm",
    "video/quicktime"
  };

  static const archiveTypes = {
    "application/x-7z-compressed",
    "application/x-bzip",
    "application/x-bzip2",
    "application/gzip"
  };

  static const extensionToMime = {
    "jpeg": "image/jpeg",
    "jpg": "image/jpeg",
    "png": "image/png",
    "gif": "image/gif",
    "webp": "image/webp",
    "bmp": "image/bmp"
  };

  static String? fromExtenstion(String extension) {
    return extensionToMime.tryGet(extension);
  }

  static String? extensionFromMime(String mimeType) {
    for (var pair in extensionToMime.entries) {
      if (pair.value == mimeType) {
        return pair.key;
      }
    }

    return null;
  }

  static IconData toIcon(String? mimeType) {
    if (imageTypes.contains(mimeType)) return Icons.image;
    if (videoTypes.contains(mimeType)) return Icons.video_file_rounded;
    if (archiveTypes.contains(mimeType)) return Icons.folder_zip;
    if (playableAudioTypes.contains(mimeType)) return Icons.audio_file;
    return Icons.file_present;
  }

  static String? lookupType(String filepath, {Uint8List? data}) {
    var resolver = mime.MimeTypeResolver();
    resolver.addMagicNumber([0x42, 0x4d], "image/bmp");
    resolver.addMagicNumber([0x3c, 0x73, 0x76, 0x67], "image/svg+xml"); // '<svg
    var type = resolver.lookup(filepath);
    type ??= resolver.lookup(filepath, headerBytes: data);
    return type;
  }
}
