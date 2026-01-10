import 'dart:async';

import 'package:commet/client/components/user_presence/user_presence_component.dart';
import 'package:commet/client/components/user_presence/user_presence_lifecycle_watcher.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:matrix/matrix.dart';

class MatrixUserPresenceComponent
    implements UserPresenceComponent<MatrixClient> {
  @override
  MatrixClient client;

  StreamController<(String, UserPresence)> _controller =
      StreamController.broadcast();

  MatrixUserPresenceComponent(this.client) {
    client.matrixClient.onPresenceChanged.stream.listen(changed);
    UserPresenceLifecycleWatcher().init();
  }

  @override
  Future<UserPresence> getUserPresence(String userId) async {
    final presence = await client.matrixClient.fetchCurrentPresence(userId);
    return convertPresence(presence);
  }

  UserPresence convertPresence(CachedPresence presence) {
    final status = switch (presence.presence) {
      PresenceType.offline => UserPresenceStatus.offline,
      PresenceType.online => UserPresenceStatus.online,
      PresenceType.unavailable => UserPresenceStatus.unavailable,
    };

    UserPresenceMessage? message = null;

    if (presence.statusMsg != null) {
      message = UserPresenceMessage(
          presence.statusMsg!, PresenceMessageType.userCustom);
    }

    return UserPresence(status, message: message);
  }

  void changed(CachedPresence event) {
    _controller.add((event.userid, convertPresence(event)));
  }

  @override
  Stream<(String, UserPresence)> get onPresenceChanged => _controller.stream;

  @override
  Future<void> setStatus(UserPresenceStatus status,
      {String? message, bool clearMessage = false}) async {
    final self = client.self!.identifier;

    final current = await client.matrixClient.getPresence(self);

    await client.matrixClient.setPresence(
        self,
        statusMsg: clearMessage ? null : message ?? current.statusMsg,
        switch (status) {
          UserPresenceStatus.offline => PresenceType.offline,
          UserPresenceStatus.unknown => PresenceType.offline,
          UserPresenceStatus.online => PresenceType.online,
          UserPresenceStatus.unavailable => PresenceType.unavailable,
        });
  }
}
