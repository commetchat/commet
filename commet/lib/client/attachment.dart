import 'package:flutter/material.dart';

class Attachment {
  Attachment(this.url, this.name, {this.blurhash, this.mimeType, this.width, this.thumbnail, this.height});

  String url;
  String name;
  String? blurhash;
  String? mimeType;
  ImageProvider? thumbnail;
  double? width;
  double? height;

  double? get aspectRatio => (width != null && height != null) ? (width! / height!) : null;
}
