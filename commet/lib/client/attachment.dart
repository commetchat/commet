import 'package:commet/cache/file_provider.dart';
import 'package:flutter/material.dart';

abstract class Attachment {
  late String name;
}

class ImageAttachment implements Attachment {
  final ImageProvider image;
  final double? width;
  final double? height;
  @override
  String name;

  double get aspectRatio =>
      (width != null && height != null) ? (width! / height!) : 1;

  ImageAttachment(this.image, {required this.name, this.width, this.height});
}

class VideoAttachment implements Attachment {
  final ImageProvider? thumbnail;
  final FileProvider videoFile;
  final double? width;
  final double? height;
  @override
  String name;

  double get aspectRatio =>
      (width != null && height != null) ? (width! / height!) : 1;

  VideoAttachment(this.videoFile,
      {required this.name, this.thumbnail, this.width, this.height});
}

class FileAttachment implements Attachment {
  @override
  String name;
  int? fileSize;
  String? mimeType;
  FileProvider provider;
  FileAttachment(this.provider,
      {required this.name, this.fileSize, this.mimeType});
}
