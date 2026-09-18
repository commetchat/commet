import 'dart:async';

import 'package:commet/client/components/user_presence/user_presence_component.dart';
import 'package:commet/client/components/user_presence/user_presence_lifecycle_watcher.dart';
import 'package:commet/client/matrix/components/read_receipts/matrix_read_receipt_component.dart';
import 'package:commet/client/matrix/components/typing_indicators/matrix_typing_indicators_component.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_call_membership.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_voip_room_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/main.dart';
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
    lastSeen = InMemoryCache(
        maxRetention: Duration(minutes: 2),
        pollFrequency: Duration(seconds: 100));
    lastSeen.onRemove.listen(onLastSeenRemoved);

    UserPresenceLifecycleWatcher().init();
  }

  @override
  bool get usePublicReadReceipts {
    var publicReadReceipts = client
        .matrixClient
        .accountData[MatrixReadReceiptComponent.publicReadReceiptsKey]
        ?.content["enabled"];
    return publicReadReceipts is bool ? publicReadReceipts : true;
  }

  @override
  Future<void> setUsePublicReadReceipts(bool value) async {
    await client.matrixClient.setAccountData(
      client.matrixClient.userID!,
      MatrixReadReceiptComponent.publicReadReceiptsKey,
      {"enabled": value},
    );
    client.matrixClient.receiptsPublicByDefault = value;
  }

  @override
  bool get typingIndicatorEnabled {
    var publicTypingIndicator = client
        .matrixClient
        .accountData[MatrixTypingIndicatorsComponent.publicTypingIndicatorKey]
        ?.content["enabled"];
    return publicTypingIndicator is bool ? publicTypingIndicator : true;
  }

  @override
  Future<void> setTypingIndicatorEnabled(bool value) async =>
      await client.matrixClient.setAccountData(
        client.matrixClient.userID!,
        MatrixTypingIndicatorsComponent.publicTypingIndicatorKey,
        {"enabled": value},
      );

  @override
  Future<UserPresence> getUserPresence(String userId) async {
    final presence = await client.matrixClient.fetchCurrentPresence(userId);

    if (presence.presence == PresenceType.offline && isInCall(userId)) {
      return convertPresence(presence)..status = UserPresenceStatus.online;
    }

    if (presence.presence == PresenceType.offline &&
        presence.statusMsg == null &&
        presence.lastActiveTimestamp == null) {
      var seen = lastSeen.get(userId);
      if (seen != null) {
        if (DateTime.now().difference(seen).inSeconds < 120) {
          return UserPresence(UserPresenceStatus.online);
        }
      }
    }

    return convertPresence(presence);
  }

  /// Whether [userId] is in a voice call: by a live call membership in any
  /// room we share, or by being connected to a call we are in. Homeservers
  /// that don't share presence (matrix.org) report everyone as offline, and
  /// someone in a call is plainly online.
  bool isInCall(String userId) {
    final now = DateTime.now();
    for (final room in client.matrixClient.rooms) {
      final memberships =
          room.states[MatrixVoipRoomComponent.callMemberStateEvent];
      if (memberships == null) continue;
      for (final event in memberships.values) {
        if (event.senderId != userId) continue;
        if (event.content["application"] == null) continue;
        final sentAt = event is Event ? event.originServerTs : null;
        if (MatrixCallMembership.isExpired(event.content, sentAt, now)) {
          continue;
        }
        return true;
      }
    }

    final sessions = clientManager?.callManager.currentSessions ?? const [];
    return sessions.any((session) =>
        session.client == client &&
        session.streams.any((stream) => stream.streamUserId == userId));
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
        handleCallMemberships(update.value);
      }
    }
  }

  /// Joining or leaving a call changes whether someone counts as online
  /// (see [isInCall]).
  void handleCallMemberships(JoinedRoomUpdate update) async {
    final senders = {
      for (final event in [...?update.state, ...?update.timeline?.events])
        if (event.type == MatrixVoipRoomComponent.callMemberStateEvent)
          event.senderId,
    };
    for (final sender in senders) {
      _controller.add((sender, await getUserPresence(sender)));
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

  void sawUser(String id, DateTime timestamp) async {
    final presence = await client.matrixClient
        .fetchCurrentPresence(id, fetchOnlyFromCached: true);

    if (presence.presence != PresenceType.offline ||
        presence.statusMsg != null) {
      return;
    }

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
    final presence = await client.matrixClient
        .fetchCurrentPresence(event, fetchOnlyFromCached: true);
    if (presence.presence == PresenceType.offline && !isInCall(event)) {
      _controller.add((event, UserPresence(UserPresenceStatus.offline)));
    }
  }

  void handleRoomMemberEvent(BasicEvent event) {}
}
