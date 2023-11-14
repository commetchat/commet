import 'dart:io';
import 'dart:ui';

import 'package:commet/client/room.dart';
import 'package:commet/utils/image_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_shortcuts/flutter_shortcuts.dart';

class ShortcutsManager {
  FlutterShortcuts? shortcuts;
  Future? loading;

  ShortcutsManager() {
    if (Platform.isAndroid) {
      shortcuts = FlutterShortcuts();
      loading = shortcuts!.initialize(debug: true);
      shortcuts!.listenAction(receviedShortcutAction);
    }
  }

  Future<void> createShortcutForRoom(Room room) async {
    if (loading != null) await loading;

    String icon = "assets/images/app_icon/app_icon_filled.png";
    ShortcutIconAsset type = ShortcutIconAsset.flutterAsset;

    var avatar = await room.getShortcutImage();
    if (avatar != null) {
      var image = await ImageUtils.imageProviderToImage(avatar);
      var bytes = await image.toByteData(format: ImageByteFormat.png);
      icon =
          ShortcutMemoryIcon(jpegImage: bytes!.buffer.asUint8List()).toString();
      type = ShortcutIconAsset.memoryAsset;
    }

    f(String string) => Uri.encodeComponent(string);

    var item = ShortcutItem(
        id: room.identifier,
        action:
            "commet://open_room?room_id=${f(room.identifier)}&client_id=${room.client.identifier}",
        shortLabel: room.displayName,
        icon: icon,
        shortcutIconAsset: type,
        conversationShortcut: true);
    shortcuts?.pushShortcutItem(shortcut: item);
  }

  Future<void> clearAllShortcuts() async {
    await shortcuts?.clearShortcutItems();
  }

  void receviedShortcutAction(String action) {
    if (kDebugMode) {
      print("Received shortcut action: $action");
    }
  }
}
