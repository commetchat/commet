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

  Uri emojiUrl;

  @override
  String get identifier => emojiUrl.toString();

  MatrixEmoji(this.emojiUrl, matrix.Client client, {String? shortcode}) {
    _image = MatrixMxcImage(emojiUrl, client, doThumbnail: false);

    _shortcode = shortcode;

    if (!Emoji.knownEmoji.containsKey(identifier)) {
      Emoji.knownEmoji[identifier] = this;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is! MatrixEmoji) {
      return false;
    }

    return other.emojiUrl == emojiUrl;
  }

  @override
  int get hashCode {
    return emojiUrl.hashCode;
  }
}
