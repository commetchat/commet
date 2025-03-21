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
  bool isDirectMessage;
  ImageProvider? roomImage;
  ImageProvider? senderImage;
  ImageProvider? attachedImage;

  MessageNotificationContent({
    required String senderName,
    required this.senderId,
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
