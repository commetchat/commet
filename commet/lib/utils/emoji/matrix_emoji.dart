import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart' as matrix;

import 'emoji.dart';

class MatrixEmoji implements Emoji {
  late MatrixMxcImage _image;
  late String? _shortcode;

  @override
  ImageProvider<Object> get image => _image;

  @override
  String? get shortcode => _shortcode;

  MatrixEmoji(Uri emojiUrl, matrix.Client client, {String? shortcode}) {
    _image = MatrixMxcImage(emojiUrl, client, doThumbnail: false);
  }
}
