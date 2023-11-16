import 'dart:io';

import 'package:commet/utils/notification/android/firebase_push_notifier.dart';
import 'package:commet/utils/notification/linux/linux_notifier.dart';
import 'package:commet/utils/notification/notification_content.dart';
import 'package:commet/utils/notification/notification_modifiers.dart';
import 'package:commet/utils/notification/notifier.dart';
import 'package:commet/utils/notification/windows/windows_notifier.dart';

class NotificationManager {
  final Notifier? _notifier = Platform.isLinux
      ? LinuxNotifier()
      : Platform.isWindows
          ? WindowsNotifier()
          : Platform.isAndroid
              ? FirebasePushNotifier()
              : null;

  final List<NotificationModifier> _modifiers = List.empty(growable: true);

  Future<void> init() async {
    addModifier(NotificationModifierDontNotifyActiveRoom());
    await _notifier?.init();
  }

  void addModifier(NotificationModifier modifier) {
    _modifiers.add(modifier);
  }

  void removeModifier(NotificationModifier modifier) {
    _modifiers.remove(modifier);
  }

  Future<void> notify(NotificationContent notification,
      {bool bypassModifiers = false}) async {
    if (_notifier == null) return;

    NotificationContent? content = notification;

    if (!bypassModifiers) {
      for (var modifier in _modifiers) {
        content = modifier.process(content!);
        if (content == null) return;
      }
    }

    await _notifier!.notify(notification);
  }
}
