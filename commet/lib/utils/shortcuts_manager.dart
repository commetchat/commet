import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:commet/client/room.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/custom_uri.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/utils/image/lod_image.dart';
import 'package:commet/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:flutter_shortcuts_new/flutter_shortcuts_new.dart';
import 'package:image/image.dart' as img;

enum ShortcutIconFormat {
  jpeg,
  png,
  rawRgba,
}

class ShortcutsManager {
  FlutterShortcuts? shortcuts;
  Future? loading;

  void init() {
    if (PlatformUtils.isAndroid) {
      shortcuts = FlutterShortcuts();
      loading = shortcuts!.initialize(debug: true);
      EventBus.onSelectedRoomChanged.stream.listen(onRoomOpenedInUI);

      shortcuts!
          .listenAction((action) => Log.i("Received shortcut action: $action"));
    }
  }

  Future<void> createShortcutForRoom(Room room) async {
    if (loading != null) await loading;

    var cachedAvatar = await getCachedAvatarImage(
        identifier: room.roomId,
        placeholderColor: room.defaultColor,
        placeholderText: room.displayName,
        format: ShortcutIconFormat.jpeg,
        doCircleMask: false,
        imageProvider: await room.getShortcutImage());

    String? icon;
    if (cachedAvatar != null) {
      var file = File(cachedAvatar.toFilePath());
      var bytes = await file.readAsBytes();
      icon = ShortcutMemoryIcon(jpegImage: bytes).toString();
    }

    var item = ShortcutItem(
        id: room.roomId,
        action:
            OpenRoomURI(roomId: room.roomId, clientId: room.client.identifier)
                .toString(),
        shortLabel: room.displayName,
        icon: icon,
        shortcutIconAsset: ShortcutIconAsset.memoryAsset,
        conversationShortcut: true);

    await shortcuts?.pushShortcutItem(shortcut: item);
  }

  Future<void> clearAllShortcuts() async {
    await shortcuts?.clearShortcutItems();
  }

  void onRoomOpenedInUI(Room? event) async {
    if (event == null) {
      return;
    }

    await createShortcutForRoom(event);
  }

  static Future<Uri?> getCachedAvatarImage(
      {required Color placeholderColor,
      required String placeholderText,
      required String identifier,
      required ShortcutIconFormat format,
      String? imageId,
      ImageProvider? imageProvider,
      bool shouldZoomOut = true,
      bool doCircleMask = true}) async {
    String avatarId = "shortcutAvatar_$identifier";

    if (imageProvider == null) {
      avatarId += "_placeholder";
    }

    if (imageId != null) {
      avatarId += "_${imageId}";
    }

    if (shouldZoomOut) {
      avatarId += "_zoomed";
    }

    if (doCircleMask) {
      avatarId += "_circle";
    }

    avatarId += switch (format) {
      ShortcutIconFormat.jpeg => ".jpg",
      ShortcutIconFormat.png => ".png",
      ShortcutIconFormat.rawRgba => ".bin",
    };

    Log.i("Getting cached avatar image for id: ${avatarId}");

    Uri? cachedAvatar = await fileCache?.getFile(avatarId);

    if (cachedAvatar != null) {
      Log.i("Cache hit");
      return cachedAvatar;
    }

    if (isHeadless) {
      Log.i(
          "Failed to find cached image, we are headless so continuing with no image");
      return null;
    }

    Log.i("Cache miss, generating image");

    var image = await createAvatarImage(
        placeholderColor: placeholderColor,
        placeholderText: placeholderText,
        imageProvider: imageProvider,
        doCircleMask: doCircleMask,
        shouldZoomOut: shouldZoomOut);

    late Uint8List data;

    switch (format) {
      case ShortcutIconFormat.jpeg:
        var bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
        var finalImage = img.Image.fromBytes(
            width: image.width,
            height: image.height,
            bytes: bytes!.buffer,
            format: img.Format.uint8,
            numChannels: 4,
            order: img.ChannelOrder.rgba);
        data = img.encodeJpg(finalImage);
        break;
      case ShortcutIconFormat.png:
        data = (await image.toByteData(format: ImageByteFormat.png))!
            .buffer
            .asUint8List();
        break;
      case ShortcutIconFormat.rawRgba:
        final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
        data = bytes!.buffer.asUint8List();
    }

    await fileCache?.putFile(avatarId, data);

    return cachedAvatar;
  }

  static Future<ui.Image> createAvatarImage(
      {required Color placeholderColor,
      required String placeholderText,
      ImageProvider? imageProvider,
      bool shouldZoomOut = true,
      bool doCircleMask = true}) async {
    PictureRecorder recorder = PictureRecorder();
    Canvas c = Canvas(recorder);

    var size = const Size(128, 128);
    var center = Offset(size.width / 2, size.height / 2);

    if (shouldZoomOut) {
      double scale = 0.7;
      c.scale(scale);
      c.translate(
          (size.width * 1 / scale) * 0.5, (size.height * 1 / scale) * 0.5);

      c.translate(-size.width / 2, -size.height / 2);
    }

    if (imageProvider != null) {
      c.drawColor(Colors.transparent, BlendMode.dstATop);

      if (imageProvider is LODImageProvider) {
        await imageProvider.fetchFullRes();
      }

      var image = await ImageUtils.imageProviderToImage(imageProvider);

      var smallestDimension = min(image.width, image.height).toDouble();
      c.drawImageRect(
          image,
          Rect.fromCenter(
              center: Offset(
                  image.width.toDouble() / 2, image.height.toDouble() / 2),
              width: smallestDimension,
              height: smallestDimension),
          Rect.fromCenter(
              center: center, width: size.width, height: size.height),
          Paint()..filterQuality = FilterQuality.medium);
    } else {
      c.drawColor(placeholderColor, BlendMode.dstATop);
      const textStyle = TextStyle(
        color: Colors.white,
        fontSize: 50,
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

    if (doCircleMask) {
      double width = 500;

      // Mask image with a circle
      final Paint paint = Paint()
        ..isAntiAlias = true
        ..strokeWidth = width
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..blendMode = BlendMode.dstOut;

      c.drawArc(
          Rect.fromCenter(
              center: center,
              width: size.height + width,
              height: size.height + width),
          0,
          360,
          false,
          paint);
    }

    var pic = recorder.endRecording();
    var img = await pic.toImage(size.width.round(), size.height.round());

    return img;
  }

  static Future<ui.Image> combineRoomAndUserImages(
      ui.Image roomImage, ui.Image userImage) async {
    var recorder = ui.PictureRecorder();
    Canvas c = Canvas(recorder);

    var size = const Size(128, 128);

    var circleSize = size.height / 1.5;

    var roomSize = circleSize * 0.8;

    var targetRect = Rect.fromLTWH(
        size.width - roomSize, size.height - roomSize, roomSize, roomSize);
    var path = Path();
    path.addArc(targetRect, 0, 90);
    c.drawShadow(path.shift(Offset(-5, -5)), Color(0xff000000), 6, true);

    var userSize = circleSize * 1.2;
    var userRect = Rect.fromLTWH(0, 0, userSize, userSize);

    c.drawImageRect(
        roomImage,
        Rect.fromLTWH(
            0, 0, roomImage.width.toDouble(), roomImage.height.toDouble()),
        targetRect,
        Paint());

    var userPath = Path();
    userPath.addArc(userRect, 0, 360);

    c.drawShadow(userPath, Color(0xff000000), 5, true);
    c.drawShadow(userPath.shift(Offset(5, 5)), Color(0xff000000), 5, true);

    c.drawImageRect(
        userImage,
        Rect.fromLTWH(
            0, 0, userImage.width.toDouble(), userImage.height.toDouble()),
        userRect,
        Paint());

    var pic = recorder.endRecording();
    var img = await pic.toImage(size.width.round(), size.height.round());

    return img;
  }
}
