import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
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

  AudioPlayer? player;

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
    currentSessions.add(event);

    if (event.state == VoipState.incoming) {
      startRingtone();

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
    } else {
      startOutgoingTone();
    }

    event.onStateChanged.listen((_) => onCallStateChanged(event));
  }

  void _onSessionEnded(VoipSession event) {
    currentSessions
        .removeWhere((element) => element.sessionId == event.sessionId);

    if (currentSessions.where((e) => e.state == VoipState.incoming).isEmpty) {
      stopRingtone();
    }
  }

  VoipSession? getCallInRoom(Client client, String roomId) {
    return currentSessions
        .where(
            (element) => element.client == client && element.roomId == roomId)
        .firstOrNull;
  }

  void startRingtone() {
    if (player?.state == PlayerState.playing) {
      return;
    }

    player ??= AudioPlayer();
    player?.setReleaseMode(ReleaseMode.loop);
    player?.play(
      AssetSource("sound/ringtone_in.ogg"),
    );
  }

  void startOutgoingTone() {
    if (player?.state == PlayerState.playing) {
      return;
    }

    player ??= AudioPlayer();
    player?.setReleaseMode(ReleaseMode.loop);
    player?.play(AssetSource("sound/ringtone_out.ogg"));
  }

  void stopRingtone() {
    player?.stop();
    player?.dispose();
    player = null;
  }

  onCallStateChanged(VoipSession event) {
    if (event.state == VoipState.connected ||
        event.state == VoipState.connecting) {
      stopRingtone();
    }
  }
}
