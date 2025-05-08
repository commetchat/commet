import 'dart:io';
import 'dart:typed_data';

import 'package:commet/cache/file_provider.dart';
import 'package:commet/utils/mime.dart';
import 'package:flutter/material.dart';

import 'package:mime/mime.dart' as mime;

abstract class Attachment {
  late String name;
}

abstract class ProcessedAttachment {}

class PendingFileAttachment {
  String? name;
  String? path;
  Uint8List? data;
  String? mimeType;
  int? size;

  Uint8List? thumbnailFile;
  String? thumbnailMime;
  Size? dimensions;
  Duration? length;

  PendingFileAttachment(
      {this.name, this.path, this.data, this.mimeType, this.size}) {
    assert(path != null || data != null);

    mimeType ??= Mime.lookupType(path ?? name ?? "", data: data);
  }

  Future<void> resolve() async {
    if (data != null) return;

    if (path != null) {
      var file = File(path!);
      if (await file.exists()) {
        data = await file.readAsBytes();
        mimeType = mime.lookupMimeType(file.path, headerBytes: data);
      }
    }
  }

  ImageProvider? getAsImage() {
    if (Mime.imageTypes.contains(mimeType)) {
      if (data != null) {
        return Image.memory(data!).image;
      } else {
        return Image.file(File(path!)).image;
      }
    }

    return null;
  }
}

class FileAttachment implements Attachment {
  @override
  String name;
  int? fileSize;
  String? mimeType;
  FileProvider file;
  FileAttachment(this.file, {required this.name, this.fileSize, this.mimeType});
}

class ImageAttachment extends FileAttachment {
  final ImageProvider image;
  final double? width;
  final double? height;

  double get aspectRatio =>
      (width != null && height != null) ? (width! / height!) : 1;

  ImageAttachment(
    this.image,
    super.file, {
    required super.name,
    required super.mimeType,
    super.fileSize,
    this.width,
    this.height,
  });
}

class VideoAttachment extends FileAttachment {
  final ImageProvider? thumbnail;
  final double? width;
  final double? height;

  double get aspectRatio =>
      (width != null && height != null) ? (width! / height!) : 1;

  VideoAttachment(super.file,
      {required super.name,
      required super.mimeType,
      this.thumbnail,
      this.width,
      this.height,
      super.fileSize});
}
