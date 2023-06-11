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

  MatrixEmoticon(Uri emojiUrl, matrix.Client client,
      {required String shortcode}) {
    _shortcode = shortcode;
    _image = MatrixMxcImage(emojiUrl, client, doThumbnail: false);
  }

  void setShortcode(String shortcode) {
    _shortcode = shortcode;
  }
}
