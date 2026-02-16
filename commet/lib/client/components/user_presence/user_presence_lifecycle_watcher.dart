import 'dart:async';

import 'package:commet/client/components/user_presence/user_presence_component.dart';
import 'package:commet/main.dart';
import 'package:flutter/widgets.dart';

class UserPresenceLifecycleWatcher {
  static final UserPresenceLifecycleWatcher _singleton =
      UserPresenceLifecycleWatcher._internal();

  UserPresenceLifecycleWatcher._internal();

  factory UserPresenceLifecycleWatcher() {
    return _singleton;
  }

  bool isInit = false;
  DateTime? lastUpdatedStatus = null;
  Timer? inactivityTimer;

  void init() {
    if (!isInit) {
      AppLifecycleListener(
        onResume: () {
          inactivityTimer?.cancel();
          inactivityTimer = null;
          setState(UserPresenceStatus.online);
        },
        onInactive: () {
          inactivityTimer = Timer(Duration(seconds: 15), () {
            setState(UserPresenceStatus.unavailable);
          });
        },
      );
    }

    isInit = true;
  }

  Future<void> setState(UserPresenceStatus state) async {
    final now = DateTime.now();

    if (lastUpdatedStatus != null) {
      if (now.difference(lastUpdatedStatus!).inSeconds < 10) {
        return;
      }
    }

    for (var client in clientManager.clients) {
      final component = client.getComponent<UserPresenceComponent>();
      if (component != null) {
        component.setStatus(state);
      }
    }
  
    lastUpdatedStatus = now;
  }
}
