import 'dart:async';

import 'package:flutter/widgets.dart';
import 'dart:ui' as ui;

class ImageUtils {
  static Future<ui.Image> imageProviderToImage(ImageProvider provider) async {
    Completer<ui.Image> completer = Completer<ui.Image>();

    provider
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((info, synchronousCall) {
      if (!completer.isCompleted) {
        completer.complete(info.image);
      }
    }));
    return completer.future;
  }
}
