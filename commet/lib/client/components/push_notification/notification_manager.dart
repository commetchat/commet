import 'package:commet/client/components/push_notification/android/firebase_push_notifier.dart';
import 'package:commet/client/components/push_notification/android/unified_push_notifier.dart';
import 'package:commet/client/components/push_notification/linux/linux_notifier.dart';
import 'package:commet/client/components/push_notification/modifiers/notification_modifiers.dart';
import 'package:commet/client/components/push_notification/modifiers/suppress_active_room.dart';
import 'package:commet/client/components/push_notification/modifiers/suppress_other_device_active.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notifier.dart';
import 'package:commet/client/components/push_notification/windows/windows_notifier.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/platform_utils.dart';

class NotificationManager {
  static Notifier? _notifier;

  static Notifier? get notifier => _notifier;

  static final List<NotificationModifier> _modifiers =
      List.empty(growable: true);

  static Future<void>? notifierLoading;

  static Future<void> init() async {
    _notifier ??= _getNotifier();

    _modifiers.clear;
    addModifier(NotificationModifierSuppressActiveRoom());
    if (BuildConfig.ANDROID) {
      addModifier(NotificationModifierSuppressOtherActiveDevice());
    }

    notifierLoading = _notifier?.init();
  }

  static Notifier? _getNotifier() {
    if (PlatformUtils.isLinux) {
      return LinuxNotifier();
    }

    if (PlatformUtils.isWindows) {
      return WindowsNotifier();
    }

    if (PlatformUtils.isAndroid) {
      if (BuildConfig.ENABLE_GOOGLE_SERVICES) {
        return FirebasePushNotifier();
      }

      return UnifiedPushNotifier();
    }

    return null;
  }

  static void addModifier(NotificationModifier modifier) {
    _modifiers.add(modifier);
  }

  static void removeModifier(NotificationModifier modifier) {
    _modifiers.remove(modifier);
  }

  static Future<void> notify(NotificationContent notification,
      {bool bypassModifiers = false}) async {
    if (_notifier == null) return;

    NotificationContent? content = notification;

    if (!bypassModifiers) {
      for (var modifier in _modifiers) {
        content = await modifier.process(content!);
        if (content == null) return;
      }
    }

    await _notifier!.notify(notification);
  }
}
