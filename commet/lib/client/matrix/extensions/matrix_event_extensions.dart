import 'package:matrix/matrix.dart';

extension MatrixExtensions on Event {
  String? get attachmentBlurhash => _getBlurhash();
  String? get attachmentName => _getAttachmentName();
  Uri? get videoThumbnailUrl => _getVideoThumbnailUrl();

  double? get attachmentWidth => _attachmentWidth();
  double? get attachmentHeight => _attachmentHeight();

  String? _getBlurhash() {
    var info = content.tryGet("info") as Map<String, dynamic>?;
    if (info == null) return null;

    return info.tryGet("xyz.amorgan.blurhash") as String?;
  }

  String? _getAttachmentName() {
    var info = content.tryGet("info") as Map<String, dynamic>?;
    if (info == null) return null;

    return info.tryGet("filename") as String?;
  }

  Uri? _getVideoThumbnailUrl() {
    var info = content.tryGet("info") as Map<String, dynamic>?;
    if (info == null) return null;

    var path = info.tryGet("thumbnail_url") as String?;
    if (path == null) return null;

    return Uri.parse(path);
  }

  double? _attachmentWidth() {
    var info = content.tryGet("info") as Map<String, dynamic>?;
    if (info == null) return null;

    dynamic width = info.tryGet("w");
    if (width == null) return null;

    return width.toDouble();
  }

  double? _attachmentHeight() {
    var info = content.tryGet("info") as Map<String, dynamic>?;
    if (info == null) return null;
    dynamic height = info.tryGet("h");
    if (height == null) return null;

    return height.toDouble();
  }
}
