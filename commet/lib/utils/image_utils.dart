import 'dart:async';

import 'package:flutter/widgets.dart';
import 'dart:ui' as ui;

class ImageUtils {
  static Future<ui.Image> imageProviderToImage(ImageProvider provider) async {
    Completer<ui.Image> completer = Completer<ui.Image>();

    var listener = (ImageStreamListener((info, synchronousCall) {
      if (!completer.isCompleted) {
        completer.complete(info.image);
      }
    }));

    var stream = provider.resolve(const ImageConfiguration());

    stream.addListener(listener);

    try {
      var result = await completer.future;
      stream.removeListener(listener);

      return result;
    } catch (_) {
      stream.removeListener(listener);
    }

    throw UnimplementedError();
  }
}
