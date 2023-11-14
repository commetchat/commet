import 'dart:io';
import 'dart:ui';

import 'package:commet/client/room.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/utils/image/lod_image.dart';
import 'package:commet/utils/image_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_shortcuts/flutter_shortcuts.dart';

class ShortcutsManager {
  FlutterShortcuts? shortcuts;
  Future? loading;

  void init() {
    if (Platform.isAndroid) {
      shortcuts = FlutterShortcuts();
      loading = shortcuts!.initialize(debug: true);
      shortcuts!.listenAction(receviedShortcutAction);
    }

    EventBus.onRoomOpened.stream.listen(onRoomOpenedInUI);
  }

  Future<void> createShortcutForRoom(Room room) async {
    if (loading != null) await loading;

    String icon = "assets/images/app_icon/app_icon_filled.png";
    ShortcutIconAsset type = ShortcutIconAsset.flutterAsset;

    var avatar = await room.getShortcutImage();

    if (avatar != null) {
      Uint8List? bytes;
      if (avatar is LODImageProvider) {
        bytes = await avatar.loadThumbnail?.call();
        print("using thumbnail for shortcut instead!");
      }

      if (bytes == null) {
        var image = await ImageUtils.imageProviderToImage(avatar);
        bytes = (await image.toByteData(format: ImageByteFormat.png))
            ?.buffer
            .asUint8List();
      }

      if (bytes == null) {
        return;
      }

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

  void onRoomOpenedInUI(Room event) async {
    await createShortcutForRoom(event);
  }
}
