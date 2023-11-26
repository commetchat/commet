import 'dart:io';
import 'dart:ui';

import 'package:commet/client/room.dart';
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

    var avatar = await room.getShortcutImage();

    var image = await createAvatarImage(
        placeholderColor: room.defaultColor,
        placeholderText: room.displayName,
        imageProvider: avatar);

    var bytes = (await image.toByteData(format: ImageByteFormat.png))
        ?.buffer
        .asUint8List();

    var icon =
        ShortcutMemoryIcon(jpegImage: bytes!.buffer.asUint8List()).toString();
    var type = ShortcutIconAsset.memoryAsset;

    var item = ShortcutItem(
        id: room.identifier,
        action: OpenRoomURI(
                roomId: room.identifier, clientId: room.client.identifier)
            .toString(),
        shortLabel: room.displayName,
        icon: icon,
        shortcutIconAsset: type,
        conversationShortcut: true);
    shortcuts?.pushShortcutItem(shortcut: item);
  }

  Future<void> clearAllShortcuts() async {
    await shortcuts?.clearShortcutItems();
  }

  void onRoomOpenedInUI(Room event) async {
    await createShortcutForRoom(event);
  }

  Future<ui.Image> createAvatarImage(
      {required Color placeholderColor,
      required String placeholderText,
      ImageProvider? imageProvider}) async {
    PictureRecorder recorder = PictureRecorder();
    Canvas c = Canvas(recorder);

    var size = const Size(128, 128);
    var center = Offset(size.width / 2, size.height / 2);

    // if we have an image, we are going to zoom it out a little and add a white border because android likes to zoom in on it. This reverses that!
    if (imageProvider != null) {
      c.drawColor(Colors.white, BlendMode.dstATop);
      var image = await ImageUtils.imageProviderToImage(imageProvider);

      c.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromCenter(
              center: center,
              width: size.width / 1.45,
              height: size.height / 1.45),
          Paint());

      final Paint paint = Paint()
        ..isAntiAlias = true
        ..strokeWidth = 40
        ..color = Colors.white
        ..style = PaintingStyle.stroke;

      c.drawArc(
          Rect.fromCenter(
              center: center, width: size.height, height: size.height),
          0,
          360,
          false,
          paint);
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

    var pic = recorder.endRecording();
    var img = await pic.toImage(size.width.round(), size.height.round());

    return img;
  }
}
