import 'package:commet/client/alert.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/push_notification/firebase_push_notifier.dart';
import 'package:commet/client/components/push_notification/android/android_notifier.dart';
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
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/link_utils.dart';

class NotificationManager {
  static Notifier? _notifier;

  static Notifier? get notifier => _notifier;

  static final List<NotificationModifier> _modifiers =
      List.empty(growable: true);

  static Future<void>? notifierLoading;

  static Future<void> init({bool isBackgroundService = false}) async {
    Log.i("Initializing NotificationManager");
    Log.i("Existing notifier: $_notifier");
    _notifier ??= _getNotifier(isBackgroundService: isBackgroundService);

    _modifiers.clear;
    addModifier(NotificationModifierSuppressActiveRoom());
    if (BuildConfig.ANDROID) {
      addModifier(NotificationModifierSuppressOtherActiveDevice());

      Log.i(
          "Did the notification background service succeed: ${preferences.didLastForegroundServiceRunSucceed}");

      if (preferences.didLastForegroundServiceRunSucceed == false) {
        var alert = Alert(
          AlertType.warning,
          messageGetter: () =>
              "The last attempt to start the notification updating service failed. Push notifications will not be updated in the background until this is resolved. Tap for more info",
          titleGetter: () => "Couldn't update notifications in background",
          action: () => LinkUtils.open(Uri.parse(
              "https://commet.chat/troubleshoot/android-background-service-failed/")),
        );

        clientManager?.alertManager.addAlert(alert);
        preferences.setLastForegroundServiceRunSucceeded(null);
      }
    }

    notifierLoading = _notifier?.init();
  }

  static Notifier? _getNotifier({bool isBackgroundService = false}) {
    if (PlatformUtils.isLinux) {
      return LinuxNotifier();
    }

    if (PlatformUtils.isWindows) {
      return WindowsNotifier();
    }

    if (PlatformUtils.isAndroid) {
      // We dont want the background service to actually listen for incoming notifications
      // The main isolate will listen and pass messages to the service
      if (isBackgroundService) {
        return AndroidNotifier();
      } else {
        if (BuildConfig.ENABLE_GOOGLE_SERVICES) {
          return FirebasePushNotifier();
        }

        return UnifiedPushNotifier();
      }
    }

    if (PlatformUtils.isIOS) {
      return FirebasePushNotifier();
    }

    return null;
  }

  static void addModifier(NotificationModifier modifier) {
    _modifiers.add(modifier);
  }

  static void removeModifier(NotificationModifier modifier) {
    _modifiers.remove(modifier);
  }

  static Future<void> clearNotifications(Room room) async {
    await notifier?.clearNotifications(room);
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
