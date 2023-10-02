import 'package:commet/client/room.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/utils/notification/linux/linux_notifier.dart';
import 'package:commet/utils/notification/notifier.dart';
import 'package:commet/utils/notification/windows/windows_notifier.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  messageReceived,
  invitationReceived,
}

class NotificationContent {
  String title;
  String content;
  NotificationType type;
  Room? sentFrom;
  TimelineEvent? event;
  ImageProvider? image;

  NotificationContent(this.title, this.content, this.type,
      {this.sentFrom, this.event, this.image});
}

typedef NotificationModifier = Future<NotificationContent?> Function(
    NotificationContent content);

class NotificationManager {
  final Notifier? _notifier = BuildConfig.LINUX
      ? LinuxNotifier()
      : BuildConfig.WINDOWS
          ? WindowsNotifier()
          : null;

  final List<NotificationModifier> _modifiers = List.empty(growable: true);

  void addModifier(NotificationModifier modifier) {
    _modifiers.add(modifier);
  }

  void removeModifier(NotificationModifier modifier) {
    _modifiers.remove(modifier);
  }

  Future<void> notify(NotificationContent notification) async {
    NotificationContent? content = notification;
    print("Sending notification");

    for (var modifier in _modifiers) {
      content = await modifier(content!);

      if (content == null) return;
    }

    await _notifier?.notify(notification);
  }
}
