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
  String eventId;
  String roomId;
  String clientId;
  String roomName;
  bool isDirectMessage;
  ImageProvider? roomImage;
  ImageProvider? senderImage;
  ImageProvider? attachedImage;

  MessageNotificationContent({
    required String senderName,
    required this.roomName,
    required String content,
    required this.eventId,
    required this.roomId,
    required this.clientId,
    required this.isDirectMessage,
    this.roomImage,
    this.senderImage,
    this.attachedImage,
  }) : super(title: senderName, content: content);
}
