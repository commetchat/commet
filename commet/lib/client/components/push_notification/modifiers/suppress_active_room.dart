import 'package:commet/client/components/push_notification/modifiers/notification_modifiers.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/utils/event_bus.dart';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class NotificationModifierSuppressActiveRoom implements NotificationModifier {
  String? roomId = "";

  NotificationModifierSuppressActiveRoom() {
    EventBus.onSelectedRoomChanged.stream.listen((event) {
      roomId = event?.identifier;
    });
  }

  @override
  Future<NotificationContent?> process(NotificationContent content) async {
    if (content is! MessageNotificationContent) return content;
    if (roomId == null) return content;

    if (BuildConfig.DESKTOP) {
      if (!await windowManager.isFocused()) {
        return content;
      }
    } else {
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return content;
      }
    }

    if (content.roomId == roomId) return null;

    return content;
  }
}
