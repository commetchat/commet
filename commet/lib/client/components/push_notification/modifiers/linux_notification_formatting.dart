import 'package:commet/client/components/push_notification/linux/linux_notifier.dart';
import 'package:commet/client/components/push_notification/modifiers/notification_modifiers.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/client/components/url_preview/url_preview_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/room.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/rich_text/matrix_html_parser.dart';
import 'package:commet/utils/image/lod_image.dart';
import 'package:commet/utils/image_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart';
import 'package:markdown/markdown.dart';
import 'package:vector_math/vector_math.dart';
import 'dart:ui' as ui;

class NotificationModifierLinuxFormatting implements NotificationModifier {
  final double thumbnailImageSize = 100;

  @override
  Future<NotificationContent?> process(NotificationContent content) async {
    if (preferences.formatNotificationBody == false) {
      return content;
    }

    if (content is MessageNotificationContent &&
        content.formattedContent != null &&
        content.formatType != null) {
      final client = clientManager!.getClient(content.clientId);
      final room = client!.getRoom(content.roomId)!;

      var formattedContent = await convertFormattedContent(
        content.formattedContent!,
        content.formatType!,
        room,
      );

      final bool showImages =
          room.shouldPreviewMedia && preferences.showMediaInNotifications;

      if (showImages && content.attachedImage != null) {
        final uri = await prepareImageForInline(
          content.attachedImage!,
          "notification-attached-image-${content.eventId}-${thumbnailImageSize}px.png",
          thumbnailImageSize,
        );
        if (uri != null) {
          formattedContent = (formattedContent ?? "") + '\n<img src="${uri}"/>';
        }
      }

      if (formattedContent != null) {
        content.content = formattedContent;
      }
    }

    return content;
  }

  Future<String?> convertFormattedContent(
    String formattedContent,
    String format,
    Room room,
  ) async {
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
      result += await handleMatrixNode(
        node,
        room as MatrixRoom,
        emojiSize: bigEmoji ? 32 : 16,
        showImages: showImages,
      );
    }

    return result;
  }

  Future<String> handleMatrixNode(
    html.Node node,
    MatrixRoom room, {
    required double emojiSize,
    required bool showImages,
  }) async {
    String content = "";

    if (node is html.Element) {
      if (node.localName == "img") {
        return await handleMatrixImage(
          node,
          showImages,
          emojiSize,
          room,
          content,
        );
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
          content += await handleMatrixNode(
            child,
            room,
            emojiSize: emojiSize,
            showImages: showImages,
          );
        }

        content += "</$tag>";
      } else {
        for (var child in node.nodes) {
          content += await handleMatrixNode(
            child,
            room,
            emojiSize: emojiSize,
            showImages: showImages,
          );
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
        Uri? imagePath = await prepareImageForInline(
          prev.image!,
          "matrix-url-notification-${uri}-${thumbnailImageSize}px.png",
          thumbnailImageSize,
        );

        if (imagePath != null) {
          result += '\n<img src="${imagePath}"/>';
        }
      }

      result += "</a>";
      return result;
    }

    return '<a href="${uri}">${uri}</a>';
  }

  Future<String> handleMatrixImage(
    html.Element node,
    bool showImages,
    double emojiSize,
    MatrixRoom room,
    String content,
  ) async {
    final src = node.attributes["src"];
    final alt = node.attributes["alt"];

    LinuxServerCapabilities? capabilities;
    if (NotificationManager.notifier is LinuxNotifier) {
      capabilities =
          (NotificationManager.notifier as LinuxNotifier).capabilities;
    }

    if (capabilities?.bodyImages != true || showImages == false) {
      return "<i>$alt</i>";
    }

    if (src != null && src.startsWith("mxc://")) {
      String cacheId = "matrix-emoji-notification-${emojiSize}px:$src.png";
      var path = null; // await fileCache?.getFile(cacheId);

      if (path == null) {
        var img = MatrixMxcImage(
          Uri.parse(src),
          (room.client as MatrixClient).matrixClient,
          doFullres: true,
          doThumbnail: false,
        );

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
    ImageProvider image,
    String cacheId,
    double maxSize,
  ) async {
    final cached = await fileCache?.getFile(cacheId);
    if (cached != null) {
      return cached;
    }

    if (image case LODImageProvider _) {
      await image.fetchFullRes();
    }

    var i = await ImageUtils.imageProviderToImage(image);

    var recorder = ui.PictureRecorder();
    Canvas c = Canvas(recorder);

    var sizeVector = Vector2(i.width.toDouble(), i.height.toDouble());
    sizeVector.normalize();

    sizeVector = sizeVector * (maxSize / sizeVector.y);

    var size = Size(sizeVector.x, sizeVector.y);
    var center = Offset(size.width / 2, size.height / 2);

    c.drawImageRect(
      i,
      Rect.fromLTWH(0, 0, i.width.toDouble(), i.height.toDouble()),
      Rect.fromCenter(center: center, width: size.width, height: size.height),
      Paint()..filterQuality = FilterQuality.medium,
    );

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
    return convertMatrixHtml(html, room);
  }
}
