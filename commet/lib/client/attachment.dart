import 'package:commet/cache/file_provider.dart';

class Attachment {
  Attachment(
      {required this.fileProvider,
      required this.name,
      this.blurhash,
      this.mimeType,
      this.width,
      this.thumbnail,
      this.height});

  FileProvider fileProvider;
  String name;
  String? blurhash;
  String? mimeType;
  FileProvider? thumbnail;
  double? width;
  double? height;

  double? get aspectRatio =>
      (width != null && height != null) ? (width! / height!) : null;
}
