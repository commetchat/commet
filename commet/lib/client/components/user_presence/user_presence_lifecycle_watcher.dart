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

  void init() {
    if (!isInit) {
      AppLifecycleListener(
        onResume: () => setState(UserPresenceStatus.online),
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

    if (clientManager != null) {
      for (var client in clientManager!.clients) {
        final component = client.getComponent<UserPresenceComponent>();
        if (component != null) {
          component.setStatus(UserPresenceStatus.online);
        }
      }
    }

    lastUpdatedStatus = now;
  }
}
