import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart' as matrix;

import '../../../components/emoticon/emoticon.dart';

class MatrixEmoticon implements Emoticon {
  late MatrixMxcImage _image;
  late String? _shortcode;
  @override
  String get slug => ":${shortcode!}:";

  @override
  ImageProvider<Object> get image => _image;

  @override
  String? get shortcode => _shortcode;

  Uri emojiUrl;

  late bool _isEmojiPack;
  late bool _isStickerPack;
  late bool _isMarkedEmoji;
  late bool _isMarkedSticker;

  @override
  bool get isEmoji => _isEmojiPack || _isMarkedEmoji;

  @override
  bool get isSticker => _isStickerPack || _isMarkedSticker;

  @override
  bool get isMarkedEmoji => _isMarkedEmoji;

  @override
  bool get isMarkedSticker => _isMarkedSticker;

  MatrixEmoticon(this.emojiUrl, matrix.Client client,
      {required String shortcode,
      bool isEmojiPack = true,
      bool isStickerPack = true,
      bool isMarkedSticker = false,
      bool isMarkedEmoji = false}) {
    _shortcode = shortcode;
    _isEmojiPack = isEmojiPack;
    _isStickerPack = isStickerPack;
    _isMarkedEmoji = isMarkedEmoji;
    _isMarkedSticker = isMarkedSticker;
    _image = MatrixMxcImage(emojiUrl, client, doThumbnail: false);
  }

  void setShortcode(String shortcode) {
    _shortcode = shortcode;
  }

  void markAsEmoji(bool value) {
    _isMarkedEmoji = value;
  }

  void markAsSticker(bool value) {
    _isMarkedSticker = value;
  }

  void markPackAsEmoji(bool value) {
    _isEmojiPack = value;
  }

  void markPackAsSticker(bool value) {
    _isStickerPack = value;
  }

  @override
  String get key => emojiUrl.toString();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is! MatrixEmoticon) {
      return false;
    }

    return other.key == other.key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}
