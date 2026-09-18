import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/client/components/voip/audio_processing/audio_processing_manager.dart';
import 'package:commet/client/components/voip/voip_component.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/stale_info.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:intl/intl.dart';
import 'package:media_kit/media_kit.dart';

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

  Player? player;
  Player? muteSoundPlayer;
  Player? unmuteSoundPlayer;

  void _onClientAdded(int index) {
    var client = clientManager.clients[index];

    var voip = client.getComponent<VoipComponent>();
    if (voip == null) {
      return;
    }

    voip.onSessionStarted.listen(onClientSessionStarted);
    voip.onSessionEnded.listen(onSessionEnded);
  }

  void _onClientRemoved(StalePeerInfo event) {}

  void onClientSessionStarted(VoipSession event) {
    var room = event.client.getRoom(event.roomId);
    currentSessions.add(event);

    AudioProcessingManager.instance.onSessionStarted(event);

    if (event.state == VoipState.incoming) {
      startRingtone();

      var member = room?.getMemberOrFallback(event.remoteUserId!);

      NotificationManager.notify(CallNotificationContent(
          title: notificationTitleIncomingCall(event.roomName),
          content: notificationContentUserIsCalling(
              event.remoteUserName ?? event.remoteUserId!),
          roomId: event.roomId,
          roomName: event.roomName,
          senderName: member?.displayName ?? event.remoteUserId!,
          roomImage: room?.avatar,
          callId: event.sessionId,
          senderId: event.remoteUserId!,
          senderImage: member?.avatar,
          senderImageId: member?.avatarId,
          roomImageId: room?.avatarId,
          clientId: event.client.identifier,
          isDirectMessage: event.client
                  .getComponent<DirectMessagesComponent>()
                  ?.isRoomDirectMessage(room!) ==
              true));
    }

    if (event.state == VoipState.outgoing) {
      startOutgoingTone();
    }

    if (event.state == VoipState.connected) {
      joinCallSound();
    }

    event.onConnectionStateChanged.listen((_) => onCallStateChanged(event));
  }

  void onSessionEnded(VoipSession event) {
    // By identity: LiveKit sessions all report an empty sessionId, so a late
    // hang up used to de-register the call the user had just rejoined
    // (issue #48).
    currentSessions.removeWhere((element) => identical(element, event));

    if (currentSessions.isEmpty) {
      AudioProcessingManager.instance.onSessionEnded();
    }

    if (currentSessions.where((e) => e.state == VoipState.incoming).isEmpty) {
      stopRingtone();
    }

    endCallSound();
  }

  VoipSession? getCallInRoom(Client client, String roomId) {
    return currentSessions
        .where(
            (element) => element.client == client && element.roomId == roomId)
        .firstOrNull;
  }

  void startRingtone() {
    // Let push notifications do the ringtone
    if (PlatformUtils.isAndroid) {
      return;
    }

    if (player?.state.playing == true) {
      return;
    }

    player = getSoundPlayer();
    player?.open(Media("asset:///assets/sound/ringtone_in.ogg"));
  }

  void startOutgoingTone() {
    if (player?.state.playing == true) {
      return;
    }

    player = getSoundPlayer();
    player?.open(Media("asset:///assets/sound/ringtone_out.ogg"));
    player?.setPlaylistMode(PlaylistMode.loop);
  }

  /// Someone joining or leaving is other people's noise, so a deafened user
  /// does not hear it. Our own still plays: a session we have just joined is
  /// never deafened, and by the time we leave ours is already dropped from
  /// [currentSessions]. Joining a second call while deafened in the first is
  /// silent, which is what a deafened user asked for.
  void joinCallSound() {
    if (isDeafened) return;
    player = getSoundPlayer();
    player?.open(Media("asset:///assets/sound/joined_call.ogg"));
    player?.setPlaylistMode(PlaylistMode.none);
  }

  bool get isDeafened => currentSessions.any((session) => session.isDeafened);

  void deafen() {
    for (var session in currentSessions) {
      session.setDeafened(true);
    }

    playMuteSound();
  }

  void undeafen() {
    for (var session in currentSessions) {
      session.setDeafened(false);
    }

    playUnmuteSound();
  }

  bool fakeDeafenToggle = false;
  void toggleDeafen() {
    var session = currentSessions.firstOrNull;

    if (session != null) {
      if (session.isDeafened) {
        undeafen();
      } else {
        deafen();
      }
    } else {
      fakeDeafenToggle = !fakeDeafenToggle;

      // just to give user feedback when not in a call
      if (fakeDeafenToggle) {
        playMuteSound();
      } else {
        playUnmuteSound();
      }
    }
  }

  void mute() {
    for (var session in currentSessions) {
      session.setMicrophoneMute(true);
    }

    playMuteSound();
  }

  bool fakeToggle = false;
  void toggleMute() {
    var session = currentSessions.firstOrNull;

    if (session != null) {
      if (session.isDeafened || session.isMicrophoneMuted) {
        unmute();
      } else {
        mute();
      }
    } else {
      fakeToggle = !fakeToggle;

      // just to give user feedback when not in a call
      if (fakeToggle) {
        playMuteSound();
      } else {
        playUnmuteSound();
      }
    }
  }

  void playMuteSound() {
    try {
      if (muteSoundPlayer == null) {
        muteSoundPlayer ??= Player(configuration: PlayerConfiguration());
        muteSoundPlayer?.open(Media("asset:///assets/sound/muted.ogg"));
        muteSoundPlayer?.setPlaylistMode(PlaylistMode.none);
      }

      muteSoundPlayer!.setVolume(preferences.notificationsVolume.value);
      muteSoundPlayer?.seek(Duration.zero);
      muteSoundPlayer?.play();
    } catch (_) {
      // Ignore audio playback errors in headless/test environments
    }
  }

  void unmute() {
    for (var session in currentSessions) {
      if (session.isDeafened) {
        session.setDeafened(false);
      } else {
        session.setMicrophoneMute(false);
      }
    }

    playUnmuteSound();
  }

  void playUnmuteSound() {
    try {
      if (unmuteSoundPlayer == null) {
        unmuteSoundPlayer ??= Player(configuration: PlayerConfiguration());
        unmuteSoundPlayer?.open(Media("asset:///assets/sound/unmuted.ogg"));
        unmuteSoundPlayer?.setPlaylistMode(PlaylistMode.none);
      }

      unmuteSoundPlayer!.setVolume(preferences.notificationsVolume.value);
      unmuteSoundPlayer?.seek(Duration.zero);
      unmuteSoundPlayer?.play();
    } catch (_) {
      // Ignore audio playback errors in headless/test environments
    }
  }

  void endCallSound() {
    if (isDeafened) return;
    player = getSoundPlayer();
    player?.open(Media("asset:///assets/sound/left_call.ogg"));
    player?.setPlaylistMode(PlaylistMode.none);
  }

  /// Releases the sound players. The client manager calls this when it is
  /// closed, which an app refresh does on every refresh.
  void dispose() {
    stopRingtone();
    muteSoundPlayer?.dispose();
    muteSoundPlayer = null;
    unmuteSoundPlayer?.dispose();
    unmuteSoundPlayer = null;
  }

  void stopRingtone() {
    player?.stop();
    player?.dispose();
    player = null;
  }

  void onCallStateChanged(VoipSession event) {
    if (event.state == VoipState.connected ||
        event.state == VoipState.connecting) {
      stopRingtone();
    }

    if (event.state == VoipState.connected) {
      joinCallSound();
    }
  }

  Player getSoundPlayer() {
    player ??= Player(configuration: PlayerConfiguration());
    player!.setVolume(preferences.notificationsVolume.value);

    return player!;
  }
}
