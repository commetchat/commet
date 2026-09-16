// Image of a custom soundboard emoji, loaded from the homeserver like any
// other Matrix emoticon.
import 'package:commet/client/client.dart';
import 'package:commet/client/components/soundboard/soundboard_emoji.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:flutter/widgets.dart';

/// Null for unicode emoji, non-Matrix clients and malformed URIs.
ImageProvider? soundboardEmojiImage(SoundboardEmoji emoji, Client client) {
  final uri = Uri.tryParse(emoji.mxc ?? '');
  if (uri == null || uri.scheme != 'mxc' || client is! MatrixClient) {
    return null;
  }
  // Same settings as MatrixEmoticon, so the picker's cached image is reused.
  return MatrixMxcImage(uri, client.getMatrixClient(),
      fullResHeight: 100,
      doThumbnail: false,
      doFullres: true,
      autoLoadFullRes: true);
}
