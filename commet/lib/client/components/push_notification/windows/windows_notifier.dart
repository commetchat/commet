import 'dart:async';
import 'dart:io';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notifier.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/utils/shortcuts_manager.dart';
import 'package:desktop_notifications/desktop_notifications.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:win_toast/win_toast.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path/path.dart' as p;

class WindowsNotifier implements Notifier {
  @override
  bool get hasPermission => true;

  @override
  bool get enabled => true;

  @override
  bool get needsToken => false;

  static NotificationsClient client = NotificationsClient();

  @override
  Future<void> init() async {
    final dir = await getTemporaryDirectory();
    var file = p.join(dir.path, "chat.commet.app", "commet_app_icon.png");

    ByteData data = await rootBundle
        .load("assets/images/app_icon/app_icon_transparent_cropped.png");

    var imageFile = File(file);
    imageFile.createSync(recursive: true);
    imageFile.writeAsBytes(data.buffer.asInt8List());
    var uri = Uri.file(file, windows: true);

    await WinToast.instance().initialize(
      aumId: 'chat.commet.app.windows-a33bc9ba',
      displayName: 'Commet',
      iconPath: uri.toString(),
      clsid: '7685C041-9D17-4112-8FC4-386743A3D53E',
    );

    WinToast.instance().setActivatedCallback(onActivated);
    WinToast.instance().setDismissedCallback(onDismissed);
  }

  static void onActivated(ActivatedEvent event) {
    var text = Uri.decodeQueryComponent(event.argument);
    var args = Uri.splitQueryString(text);

    switch (args['action']) {
      case 'reply':
        var clientId = args['client_id'];
        var roomId = args['room_id'];
        var eventId = args['event_id'];
        var message = event.userInput['reply'];

        if (clientId == null) return;
        if (roomId == null) return;
        if (eventId == null) return;
        if (message == null) return;

        var client = clientManager!.getClient(clientId);

        if (client == null) return;

        if (message.trim().isNotEmpty) {
          client.getRoom(roomId)?.sendMessage(message: message.trim());
        }

        break;
      case 'open_room':
        var roomId = args['room_id'];
        if (roomId == null) return;

        EventBus.openRoom.add((roomId, null));
        windowManager.show();
    }
  }

  static void onDismissed(DismissedEvent event) {}

  @override
  Future<bool> requestPermission() async {
    return true;
  }

  @override
  Future<void> notify(NotificationContent notification) async {
    switch (notification.runtimeType) {
      case MessageNotificationContent:
        return displayMessageNotification(
            notification as MessageNotificationContent);
      default:
    }
  }

  Future<void> displayMessageNotification(
      MessageNotificationContent content) async {
    String? avatarFilePath;

    var client = clientManager?.getClient(content.clientId);
    var room = client?.getRoom(content.roomId);

    if (room == null) {
      return;
    }

    var avatar = await ShortcutsManager.getCachedAvatarImage(
        placeholderColor: room.getColorOfUser(content.senderId),
        placeholderText: content.senderName,
        identifier: content.senderId,
        shouldZoomOut: false,
        imageProvider: content.senderImage);

    avatarFilePath = avatar == null ? "" : avatar.toFilePath();

    // ignore: prefer_function_declarations_over_variables
    var f = (String string) => Uri.encodeComponent(string);

    var title = "${content.senderName} (${content.roomName})";
    if (content.isDirectMessage) {
      title = content.senderName;
    }

    var xml = """
<?xml version="1.0" encoding="UTF-8"?>
<toast launch="action=open_room&amp;client_id=${f(content.clientId)}&amp;room_id=${f(content.roomId)}&amp;event_id=${f(content.eventId)}">
   <visual>
      <binding template="ToastGeneric">
         <text>$title</text>
         <text>${content.content}</text>
         <image placement='appLogoOverride' src='$avatarFilePath' hint-crop='circle'/>
      </binding>
   </visual>
   <actions>
      <input id="reply" type="text" placeHolderContent="Send a reply..." />
      <action content="Reply" activationType="background" arguments="action=reply&amp;client_id=${f(content.clientId)}&amp;room_id=${f(content.roomId)}&amp;event_id=${f(content.eventId)}" />
   </actions>
</toast>
  """;
    WinToast.instance().showCustomToast(xml: xml);
  }

  @override
  Map<String, dynamic>? extraRegistrationData() {
    return null;
  }

  @override
  Future<String?> getToken() async {
    return null;
  }
}
