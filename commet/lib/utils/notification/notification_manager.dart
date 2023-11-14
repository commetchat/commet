import 'dart:io';

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
          : null;

  final List<NotificationModifier> _modifiers = List.empty(growable: true);

  void init() {
    addModifier(NotificationModifierDontNotifyActiveRoom());
  }

  void addModifier(NotificationModifier modifier) {
    _modifiers.add(modifier);
  }

  void removeModifier(NotificationModifier modifier) {
    _modifiers.remove(modifier);
  }

  Future<void> notify(NotificationContent notification) async {
    NotificationContent? content = notification;

    for (var modifier in _modifiers) {
      content = modifier.process(content!);
      if (content == null) return;
    }

    await _notifier?.notify(notification);
  }
}
