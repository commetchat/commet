import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart' as matrix;

import '../../utils/emoji/emoticon.dart';

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

  bool _isEmoji = true;
  bool _isSticker = true;

  @override
  bool get isEmoji => _isEmoji;

  @override
  bool get isSticker => _isSticker;

  MatrixEmoticon(this.emojiUrl, matrix.Client client,
      {required String shortcode, bool isEmoji = true, bool isSticker = true}) {
    _shortcode = shortcode;
    _isEmoji = isEmoji;
    _isSticker = isSticker;
    _image = MatrixMxcImage(emojiUrl, client, doThumbnail: false);
  }

  void setShortcode(String shortcode) {
    _shortcode = shortcode;
  }

  void setIsEmoji(bool value) {
    _isEmoji = value;
  }

  void setIsSticker(bool value) {
    _isSticker = value;
  }
}
