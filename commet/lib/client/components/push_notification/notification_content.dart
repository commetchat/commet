import 'package:commet/client/attachment.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event_message.dart';
import 'package:commet/client/timeline_events/timeline_event_sticker.dart';
import 'package:flutter/material.dart';

enum NotificationPriority { normal, low }

class NotificationContent {
  String title;
  String content;
  NotificationPriority priority;

  NotificationContent(
      {required this.title,
      required this.content,
      this.priority = NotificationPriority.normal});
}

class MessageNotificationContent extends NotificationContent {
  String get senderName => title;
  String senderId;
  String eventId;
  String roomId;
  String clientId;
  String roomName;
  String? formattedContent;
  String? formatType;
  bool isDirectMessage;
  ImageProvider? roomImage;
  ImageProvider? senderImage;
  ImageProvider? attachedImage;

  MessageNotificationContent({
    required String senderName,
    required this.senderId,
    required this.roomName,
    required super.content,
    required this.eventId,
    required this.roomId,
    required this.clientId,
    required this.isDirectMessage,
    this.formattedContent,
    this.formatType,
    this.roomImage,
    this.senderImage,
    this.attachedImage,
  }) : super(title: senderName);

  static Future<MessageNotificationContent?> fromEvent(
      TimelineEvent msg, Room room) async {
    var user = await room.fetchMember(msg.senderId);

    if (msg is TimelineEventMessage) {
      return MessageNotificationContent(
        senderName: user.displayName,
        senderImage: user.avatar,
        senderId: user.identifier,
        roomName: room.displayName,
        roomId: room.identifier,
        roomImage: await room.getShortcutImage(),
        content: msg.body ?? "Sent a message",
        clientId: room.client.identifier,
        eventId: msg.eventId,
        attachedImage:
            msg.attachments?.whereType<ImageAttachment>().firstOrNull?.image ??
                msg.attachments
                    ?.whereType<VideoAttachment>()
                    .firstOrNull
                    ?.thumbnail,
        formatType: msg.bodyFormat,
        formattedContent: msg.formattedBody,
        isDirectMessage: room.client
                .getComponent<DirectMessagesComponent>()
                ?.isRoomDirectMessage(room) ??
            false,
      );
    }

    if (msg is TimelineEventSticker) {
      return MessageNotificationContent(
        senderName: user.displayName,
        senderImage: user.avatar,
        senderId: user.identifier,
        roomName: room.displayName,
        roomId: room.identifier,
        roomImage: await room.getShortcutImage(),
        content: msg.stickerName,
        clientId: room.client.identifier,
        eventId: msg.eventId,
        attachedImage: msg.stickerImage,
        formattedContent: "",
        formatType: "chat.commet.custom.matrix_plain",
        isDirectMessage: room.client
                .getComponent<DirectMessagesComponent>()
                ?.isRoomDirectMessage(room) ??
            false,
      );
    }

    return null;
  }
}

class CallNotificationContent extends NotificationContent {
  String roomId;
  String senderId;
  String roomName;
  String clientId;
  String callId;

  bool isDirectMessage;

  ImageProvider? roomImage;
  ImageProvider? senderImage;

  CallNotificationContent({
    required this.roomId,
    required this.senderId,
    required this.roomName,
    required this.clientId,
    required this.callId,
    required this.isDirectMessage,
    this.senderImage,
    required super.title,
    required super.content,
    this.roomImage,
  });
}
