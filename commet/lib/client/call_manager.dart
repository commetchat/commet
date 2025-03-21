import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/client/components/voip/voip_component.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/stale_info.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:intl/intl.dart';

class CallManager {
  ClientManager clientManager;
  final StreamController<VoipSession> _onSessionStarted =
      StreamController.broadcast();

  String notificationContentUserIsCalling(String user) => Intl.message(
      "$user is calling!",
      desc:
          "Notification body content for when receiving an incoming call from another user",
      args: [user],
      name: "notificationContentUserIsCalling");

  String notificationTitleIncomingCall(String roomName) =>
      Intl.message("Incoming Call! ($roomName)",
          desc: "Notification title for when a call is being received",
          args: [roomName],
          name: "notificationTitleIncomingCall");

  Stream<VoipSession> get onSessionStarted => _onSessionStarted.stream;

  NotifyingList<VoipSession> currentSessions =
      NotifyingList.empty(growable: true);

  CallManager(this.clientManager) {
    clientManager.onClientAdded.stream.listen(_onClientAdded);
    clientManager.onClientRemoved.stream.listen(_onClientRemoved);
  }

  void _onClientAdded(int index) {
    var client = clientManager.clients[index];

    var voip = client.getComponent<VoipComponent>();
    if (voip == null) {
      return;
    }

    voip.onSessionStarted.listen(_onClientSessionStarted);
    voip.onSessionEnded.listen(_onSessionEnded);
  }

  void _onClientRemoved(StalePeerInfo event) {}

  void _onClientSessionStarted(VoipSession event) {
    var room = event.client.getRoom(event.roomId);
    NotificationManager.notify(CallNotificationContent(
        title: notificationTitleIncomingCall(event.roomName),
        content: notificationContentUserIsCalling(
            event.remoteUserName ?? event.remoteUserId!),
        roomId: event.roomId,
        roomName: event.roomName,
        roomImage: room?.avatar,
        callId: event.sessionId,
        senderId: event.remoteUserId!,
        senderImage: room?.getMemberOrFallback(event.remoteUserId!).avatar,
        clientId: event.client.identifier,
        isDirectMessage: event.client
                .getComponent<DirectMessagesComponent>()
                ?.isRoomDirectMessage(room!) ==
            true));

    currentSessions.add(event);
  }

  void _onSessionEnded(VoipSession event) {
    currentSessions
        .removeWhere((element) => element.sessionId == event.sessionId);
  }

  VoipSession? getCallInRoom(Client client, String roomId) {
    return currentSessions
        .where(
            (element) => element.client == client && element.roomId == roomId)
        .firstOrNull;
  }
}
