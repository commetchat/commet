import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notifier.dart';
import 'package:commet/client/components/url_preview/url_preview_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/room.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/rich_text/matrix_html_parser.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/utils/image/lod_image.dart';
import 'package:commet/utils/image_utils.dart';
import 'package:commet/utils/shortcuts_manager.dart';
import 'package:desktop_notifications/desktop_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_linux/src/model/hint.dart' as notif;
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart';
import 'package:markdown/markdown.dart';
import 'package:vector_math/vector_math.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:ui' as ui;

class LinuxNotifier implements Notifier {
  @override
  bool get hasPermission => true;

  static NotificationsClient client = NotificationsClient();

  @override
  bool get enabled => true;

  @override
  Future<bool> requestPermission() async {
    return true;
  }

  static LinuxFlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  static void backgroundNotificationResponse(NotificationResponse details) {}

  static const callAccept = "call.accept";
  static const callDecline = "call.decline";
  static const openRoom = "room.open";

  static int notificationId = 0;

  late LinuxServerCapabilities capabilities;

  static void notificationResponse(NotificationResponse details) {
    print("Received notification response!");
    final payload = jsonDecode(details.payload!) as Map<String, dynamic>;

    if (details.actionId == "inline-reply") {
      var clientId = payload['client_id'];
      var roomId = payload['room_id'];
      var eventId = payload['event_id'];
      var message = details.input;

      if (clientId == null) return;
      if (roomId == null) return;
      if (eventId == null) return;
      if (message == null) return;

      var client = clientManager!.getClient(clientId);

      if (client == null) return;

      if (message.trim().isNotEmpty) {
        client.getRoom(roomId)?.sendMessage(message: message.trim());
      }
      return;
    }

    if ([callAccept, openRoom].contains(details.actionId)) {
      final roomId = payload['room_id']!;
      EventBus.openRoom.add((roomId, null));
      windowManager.show();
      windowManager.focus();
    }

    if ([callAccept, callDecline].contains(details.actionId)) {
      final callId = payload['call_id'];
      final clientId = payload['client_id'];
      final session = clientManager?.callManager.currentSessions
          .where(
              (e) => e.sessionId == callId && e.client.identifier == clientId)
          .firstOrNull;

      if (session != null) {
        if (details.actionId == callAccept) {
          session.acceptCall(withMicrophone: true);
        }

        if (details.actionId == callDecline) {
          session.declineCall();
        }
      }
    }
  }

  @override
  Future<void> init() async {
    flutterLocalNotificationsPlugin = LinuxFlutterLocalNotificationsPlugin();

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    await flutterLocalNotificationsPlugin?.initialize(
        initializationSettingsLinux,
        onDidReceiveNotificationResponse: notificationResponse);

    capabilities = await flutterLocalNotificationsPlugin!.getCapabilities();
  }

  @override
  Future<void> notify(NotificationContent notification) async {
    switch (notification) {
      case MessageNotificationContent _:
        return displayMessageNotification(notification);
      case CallNotificationContent _:
        return displayCallNotification(notification);
      default:
    }
  }

  Future<void> displayMessageNotification(
      MessageNotificationContent content) async {
    var client = clientManager?.getClient(content.clientId);
    var room = client?.getRoom(content.roomId);

    if (room == null) {
      return;
    }

    var image = await ShortcutsManager.createAvatarImage(
        placeholderColor: room.getColorOfUser(content.senderId),
        placeholderText: content.senderName,
        imageProvider: content.senderImage,
        doCircleMask: true,
        shouldZoomOut: false);

    var bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final data = bytes!.buffer.asUint8List();

    String notificationBody = content.content;
    if (content.formatType != null && content.formattedContent != null) {
      var result = await convertFormattedContent(
          content.formattedContent!, content.formatType!, room);

      if (result != null) {
        notificationBody = result;
      }
    }

    var details = LinuxNotificationDetails(
      icon: ByteDataLinuxIcon(LinuxRawIconData(
          data: data,
          width: image.width,
          height: image.height,
          hasAlpha: true,
          channels: 4)),
      defaultActionName: openRoom,
      actions: [
        if (capabilities.otherCapabilities.contains("inline-reply"))
          LinuxNotificationAction(key: "inline-reply", label: "Reply")
      ],
      customHints: [
        notif.LinuxNotificationCustomHint('desktop-entry',
            notif.LinuxHintStringValue("chat.commet.commetapp")),
      ],
      category: LinuxNotificationCategory.imReceived,
    );

    var title = "${content.senderName} (${content.roomName})";
    if (content.isDirectMessage) {
      title = content.senderName;
    }

    var payload = {
      "room_id": content.roomId,
      "client_id": content.clientId,
      "event_id": content.eventId,
    };

    flutterLocalNotificationsPlugin?.show(
        notificationId++, title, notificationBody,
        notificationDetails: details, payload: jsonEncode(payload));
  }

  Future<void> displayCallNotification(CallNotificationContent content) async {
    var client = clientManager?.getClient(content.clientId);
    var room = client?.getRoom(content.roomId);

    if (room == null) {
      return;
    }

    var image = await ShortcutsManager.createAvatarImage(
        placeholderColor: room.getColorOfUser(content.senderId),
        placeholderText: content.roomName,
        imageProvider: content.senderImage,
        doCircleMask: true,
        shouldZoomOut: false);

    var bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final data = bytes!.buffer.asUint8List();

    var details = LinuxNotificationDetails(
        icon: ByteDataLinuxIcon(LinuxRawIconData(
            data: data,
            width: image.width,
            height: image.height,
            hasAlpha: true,
            channels: 4)),
        defaultActionName: openRoom,
        category: LinuxNotificationCategory.imReceived,
        timeout: const LinuxNotificationTimeout.expiresNever(),
        urgency: LinuxNotificationUrgency.critical,
        actions: const [
          LinuxNotificationAction(key: callAccept, label: "Accept"),
          LinuxNotificationAction(key: callDecline, label: "Decline"),
        ]);

    var payload = {
      "room_id": content.roomId,
      "client_id": content.clientId,
      "call_id": content.callId
    };

    flutterLocalNotificationsPlugin?.show(0, content.title, content.content,
        notificationDetails: details, payload: jsonEncode(payload));
  }

  Future<ui.Image> determineImage(ImageProvider provider) async {
    if (provider is LODImageProvider) {
      var data = await provider.loadThumbnail?.call();
      var mem = MemoryImage(data!);
      return await ImageUtils.imageProviderToImage(mem);
    }

    return await ImageUtils.imageProviderToImage(provider);
  }

  @override
  Map<String, dynamic>? extraRegistrationData() {
    return null;
  }

  @override
  Future<String?> getToken() async {
    return null;
  }

  @override
  bool get needsToken => false;

  @override
  Future<void> clearNotifications(Room room) async {}

  @override
  Future<String?> convertFormattedContent(
      String formattedContent, String format, Room room) async {
    if (format == "org.matrix.custom.html" && room is MatrixRoom) {
      return convertMatrixHtml(formattedContent, room);
    }

    if (format == "chat.commet.custom.matrix_plain") {
      return convertPlainText(formattedContent, room);
    }

    return null;
  }

  Future<String?> convertMatrixHtml(String formattedContent, Room room) async {
    final parser = HtmlParser(formattedContent);
    final document = parser.parse();

    bool bigEmoji = shouldDoBigEmoji(document);

    String result = "";

    final bool showImages =
        room.shouldPreviewMedia && preferences.showMediaInNotifications;

    for (var node in document.nodes) {
      result += await handleMatrixNode(node, room as MatrixRoom,
          emojiSize: bigEmoji ? 32 : 16, showImages: showImages);
    }

    print(result);

    return result;
  }

  Future<String> handleMatrixNode(html.Node node, MatrixRoom room,
      {required double emojiSize, required bool showImages}) async {
    String content = "";

    if (node is html.Element) {
      if (node.localName == "img") {
        return await handleMatrixImage(
            node, showImages, emojiSize, room, content);
      }

      if (node.localName == "mx-reply") {
        return "";
      }

      if (node.localName == "a") {
        return await handleMatrixLinks(node, room);
      }

      String tag = switch (node.localName!) {
        "em" => "i",
        "b" => "b",
        "strong" => "b",
        "i" => "i",
        "img" => "img",
        "pre" => "i",
        "code" => "i",
        _ => "",
      };

      if (tag != "") {
        content += "<$tag>";

        for (var child in node.nodes) {
          content += await handleMatrixNode(child, room,
              emojiSize: emojiSize, showImages: showImages);
        }

        content += "</$tag>";
      } else {
        for (var child in node.nodes) {
          content += await handleMatrixNode(child, room,
              emojiSize: emojiSize, showImages: showImages);
        }
      }
    } else {
      if (node is html.Text) {
        content += node.text;
      }
    }

    return content;
  }

  Future<String> handleMatrixLinks(html.Element node, MatrixRoom room) async {
    final url = node.attributes["href"];
    if (url == null) return "";

    var uri = Uri.parse(url);

    if (!(uri.scheme == "https" || uri.scheme == "https")) {
      return "";
    }

    final preview = room.client.getComponent<UrlPreviewComponent>();

    bool shouldGetPreview = preview?.shouldGetPreviewsInRoom(room) == true &&
        preferences.previewUrlsInNotifications;

    if (!shouldGetPreview) {
      return '<a href="${uri}">${uri}</a>';
    }

    var prev = await preview!.getPreviewForUrl(room, uri);

    bool useUserText = node.text.trim() != "" && node.text != url;

    if (prev?.title != null) {
      var title = prev!.title!;
      const maxLength = 50;
      if (title.length > maxLength) {
        title = title.substring(0, maxLength) + "...";
      }

      String result =
          '<a href="${uri}"> ${useUserText ? node.text : ""} <i>"${title}"</i> <i>(${uri.authority})</i>';

      if (prev.image != null &&
          room.shouldPreviewMedia &&
          preferences.showMediaInNotifications) {
        final double imgSize = 100;
        Uri? imagePath = await prepareImageForInline(prev.image!,
            "matrix-url-notification-${uri}-${imgSize}px.png", imgSize);

        if (imagePath != null) {
          result += '\n<img src="${imagePath}"/>';
        }
      }

      result += "</a>";
      return result;
    }

    return '<a href="${uri}">${uri}</a>';
  }

  Future<String> handleMatrixImage(html.Element node, bool showImages,
      double emojiSize, MatrixRoom room, String content) async {
    final src = node.attributes["src"];
    final alt = node.attributes["alt"];

    if (capabilities.bodyImages == false || showImages == false) {
      return "<i>$alt</i>";
    }

    if (src != null && src.startsWith("mxc://")) {
      String cacheId = "matrix-emoji-notification-${emojiSize}px:$src.png";
      var path = null; // await fileCache?.getFile(cacheId);

      if (path == null) {
        var img = MatrixMxcImage(
            Uri.parse(src), (room.client as MatrixClient).matrixClient,
            doFullres: true, doThumbnail: false);

        path = await prepareImageForInline(img, cacheId, emojiSize);
      }

      String result = '<img src="$path" ';

      if (alt != null) {
        result += 'alt="$alt"';
      }

      result += "/>";

      return result;
    }
    return content;
  }

  Future<Uri?> prepareImageForInline(
      ImageProvider image, String cacheId, double maxSize) async {
    final cached = await fileCache?.getFile(cacheId);
    if (cached != null) {
      return cached;
    }

    var i = await ImageUtils.imageProviderToImage(image);

    var recorder = ui.PictureRecorder();
    Canvas c = Canvas(recorder);

    var sizeVector = Vector2(i.width.toDouble(), i.height.toDouble());
    sizeVector.normalize();

    sizeVector = sizeVector * (maxSize / sizeVector.y);

    var size = Size(sizeVector.x, sizeVector.y);
    var center = Offset(size.width / 2, size.height / 2);

    var smallestDimension = min(i.width, i.height).toDouble();

    c.drawImageRect(
        i,
        Rect.fromCenter(
            center: Offset(i.width.toDouble() / 2, i.height.toDouble() / 2),
            width: smallestDimension,
            height: smallestDimension),
        Rect.fromCenter(center: center, width: size.width, height: size.height),
        Paint()..filterQuality = FilterQuality.medium);

    var pic = recorder.endRecording();

    var resized = await pic.toImage(size.width.round(), size.height.round());

    var resultBytes = await resized.toByteData(format: ui.ImageByteFormat.png);

    return fileCache?.putFile(cacheId, resultBytes!.buffer.asUint8List());
  }

  Future<String?> convertPlainText(String formattedContent, Room room) async {
    final html = markdownToHtml(formattedContent,
        extensionSet: ExtensionSet(
          [],
          [AutolinkExtensionSyntax()],
        ));
    print(html);

    return convertMatrixHtml(html, room);
  }
}
