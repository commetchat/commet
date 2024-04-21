import 'dart:async';

import 'package:commet/debug/log.dart';
import 'package:commet/service/background_service_task.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class BackgroundServiceTaskNotification extends BackgroundServiceTask {
  String roomId;
  String eventId;

  BackgroundServiceTaskNotification(this.roomId, this.eventId);
}

class BackgroundNotificationsManager {
  ServiceInstance instance;

  BackgroundNotificationsManager(this.instance);

  void onReceived(Map<String, dynamic>? event) {
    Log.i("Received background notification data: $event");

    var i = 0;
    Timer.periodic(Duration(seconds: 5), (timer) {
      i += 1;

      Log.i("Doing stuff in background: $i");
      if (i > 20) {
        timer.cancel();
        instance.stopSelf();
      }
    });
  }
}
