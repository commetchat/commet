import 'dart:io';
import 'dart:ui';

import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/room.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/custom_uri.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shortcuts/flutter_shortcuts.dart';
import 'dart:ui' as ui;

class ShortcutsManager {
  FlutterShortcuts? shortcuts;
  Future? loading;

  void init() {
    if (Platform.isAndroid) {
      shortcuts = FlutterShortcuts();
      loading = shortcuts!.initialize(debug: true);
    }

    EventBus.onRoomOpened.stream.listen(onRoomOpenedInUI);
  }

  Future<void> createShortcutForRoom(Room room) async {
    if (loading != null) await loading;

    var cachedAvatar = await getCachedAvatarImage(
        identifier: room.identifier,
        placeholderColor: room.defaultColor,
        placeholderText: room.displayName,
        imageProvider: room.avatar);

    var item = ShortcutItem(
        id: room.identifier,
        action: OpenRoomURI(
                roomId: room.identifier, clientId: room.client.identifier)
            .toString(),
        shortLabel: room.displayName,
        icon: cachedAvatar.toFilePath(),
        shortcutIconAsset: ShortcutIconAsset.flutterAsset,
        conversationShortcut: true);
    shortcuts?.pushShortcutItem(shortcut: item);
  }

  Future<void> clearAllShortcuts() async {
    await shortcuts?.clearShortcutItems();
  }

  void onRoomOpenedInUI(Room event) async {
    await createShortcutForRoom(event);
  }

  static Future<Uri> getCachedAvatarImage(
      {required Color placeholderColor,
      required String placeholderText,
      required String identifier,
      ImageProvider? imageProvider,
      bool shouldZoomOut = true}) async {
    String avatarId = "shortcutAvatar_$identifier";

    if (imageProvider == null) {
      avatarId += "_placeholder";
    }

    if (imageProvider is MatrixMxcImage) {
      avatarId += "_${imageProvider.identifier.toString()}";
    }

    if (shouldZoomOut) {
      avatarId += "_zoomed";
    }

    // Uri? cachedAvatar = await fileCache.getFile(avatarId);
//
    // if (cachedAvatar != null) {
    //   print("Using avatar file from cache: $cachedAvatar");
    //   return cachedAvatar;
    // }

    var image = await createAvatarImage(
        placeholderColor: placeholderColor,
        placeholderText: placeholderText,
        imageProvider: imageProvider,
        shouldZoomOut: shouldZoomOut);

    var bytes = (await image.toByteData(format: ImageByteFormat.png))!
        .buffer
        .asUint8List();
    var cachedAvatar = await fileCache.putFile(avatarId, bytes);

    return cachedAvatar;
  }

  static Future<ui.Image> createAvatarImage(
      {required Color placeholderColor,
      required String placeholderText,
      ImageProvider? imageProvider,
      bool shouldZoomOut = true}) async {
    PictureRecorder recorder = PictureRecorder();
    Canvas c = Canvas(recorder);

    var size = const Size(128, 128);
    var center = Offset(size.width / 2, size.height / 2);

    if (imageProvider != null) {
      c.drawColor(Colors.transparent, BlendMode.dstATop);
      var image = await ImageUtils.imageProviderToImage(imageProvider);

      double zoomAmount = 1.45;

      if (shouldZoomOut == false) {
        zoomAmount = 1;
      }

      c.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromCenter(
              center: center,
              width: size.width / zoomAmount,
              height: size.height / zoomAmount),
          Paint());
    } else {
      c.drawColor(placeholderColor, BlendMode.dstATop);
      const textStyle = TextStyle(
        color: Colors.white,
        fontSize: 30,
      );
      final textSpan = TextSpan(
        text: placeholderText.characters.first.toUpperCase(),
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(
        minWidth: 0,
        maxWidth: size.width,
      );
      final xCenter = (size.width - textPainter.width) / 2;
      final yCenter = (size.height - textPainter.height) / 2;
      final offset = Offset(xCenter, yCenter);
      textPainter.paint(c, offset);
    }

    // Mask image with a circle
    final Paint paint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 50
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.dstOut;

    double offset = 10;
    if (!shouldZoomOut) {
      offset = 40;
    }

    c.drawArc(
        Rect.fromCenter(
            center: center,
            width: size.height + offset,
            height: size.height + offset),
        0,
        360,
        false,
        paint);

    var pic = recorder.endRecording();
    var img = await pic.toImage(size.width.round(), size.height.round());

    return img;
  }
}
