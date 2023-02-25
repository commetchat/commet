class Attachment {
  Attachment(this.url, this.name, {this.blurhash, this.mimeType, this.width, this.height});

  String url;
  String name;
  String? blurhash;
  String? mimeType;
  double? width;
  double? height;
}
