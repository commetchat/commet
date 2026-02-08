import 'dart:async';

import 'package:commet/client/components/user_presence/user_presence_component.dart';
import 'package:commet/client/components/user_presence/user_presence_lifecycle_watcher.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/in_memory_cache.dart';
import 'package:matrix/matrix.dart';

class MatrixUserPresenceComponent
    implements UserPresenceComponent<MatrixClient> {
  @override
  MatrixClient client;

  StreamController<(String, UserPresence)> _controller =
      StreamController.broadcast();

  late InMemoryCache<DateTime> lastSeen;

  MatrixUserPresenceComponent(this.client) {
    client.matrixClient.onPresenceChanged.stream.listen(changed);

    client.matrixClient.onSync.stream.listen(onSync);
    lastSeen = InMemoryCache(maxRetention: Duration(minutes: 2));
    lastSeen.onRemove.listen(onLastSeenRemoved);

    UserPresenceLifecycleWatcher().init();
  }

  @override
  Future<UserPresence> getUserPresence(String userId) async {
    final presence = await client.matrixClient.fetchCurrentPresence(userId);

    if (presence.presence == PresenceType.offline &&
        presence.statusMsg == null &&
        presence.lastActiveTimestamp == null) {
      var seen = lastSeen.get(userId);
      if (seen != null) {
        if (DateTime.now().difference(seen).inMinutes < 3) {
          return UserPresence(UserPresenceStatus.online);
        }
      }
    }

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

  void onSync(SyncUpdate event) {
    if (event.rooms?.join != null) {
      for (var update in event.rooms!.join!.entries) {
        handleEvents(update.value.ephemeral);
        handleEvents(update.value.state);
        handleTimelineUpdate(update.value.timeline);
      }
    }
  }

  void handleEvents(List<BasicEvent>? events) {
    if (events == null) return;
    var time = DateTime.now();

    for (var event in events) {
      try {
        if (event.type == "m.typing") {
          handleTyping(event, time);
          return;
        }

        if (event.type == "m.receipt") {
          handleReadReceipt(event);
          return;
        }

        if (event.type == "m.room.member") {
          handleRoomMemberEvent(event);
          return;
        }

        Log.i("(Last Seen) unhandled event: ${event.type}");
      } catch (_) {}
    }
  }

  void handleTyping(BasicEvent event, DateTime time) {
    for (var id in event.content["user_ids"] as List<dynamic>) {
      sawUser(id, time);
    }
  }

  void handleReadReceipt(BasicEvent event) {
    for (var event in event.content.values) {
      var read = (event as Map<String, dynamic>)["m.read"];
      if (read == null) continue;

      for (var entry in (read as Map<String, dynamic>).entries) {
        var value = entry.value as Map<String, dynamic>;

        if (value.containsKey("ts")) {
          sawUser(entry.key,
              DateTime.fromMicrosecondsSinceEpoch((value["ts"] as int) * 1000));
        }
      }
    }
  }

  void handleTimelineUpdate(TimelineUpdate? timeline) async {
    if (timeline?.events == null) return;

    for (var event in timeline!.events!) {
      sawUser(event.senderId, event.originServerTs);
    }
  }

  void sawUser(String id, DateTime timestamp) {
    if (DateTime.now().difference(timestamp).inSeconds < 60) {
      var seen = lastSeen.get(id);

      if (seen == null) {
        lastSeen.put(id, timestamp);
      } else {
        if (timestamp.isAfter(seen)) {
          lastSeen.put(id, timestamp);
        }
      }

      _controller.add((id, UserPresence(UserPresenceStatus.online)));
    }
  }

  void onLastSeenRemoved(String event) async {
    final presence = await client.matrixClient.fetchCurrentPresence(event);
    if (presence.presence == PresenceType.offline) {
      _controller.add((event, UserPresence(UserPresenceStatus.offline)));
    }
  }

  void handleRoomMemberEvent(BasicEvent event) {}
}
