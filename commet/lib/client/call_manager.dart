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
import 'package:commet/debug/log.dart';
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

  /// Screen share and camera sounds: a player of their own, so one does not
  /// cut off someone's join sound.
  Player? cueSoundPlayer;

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

    // The join path leaves the other channels before it starts this one,
    // but two joins close together each look around before either has
    // registered. This is the backstop: whatever else is live when a
    // session the user is actually in appears, goes. A call that is merely
    // ringing is not one they are in, and must not empty the room they are
    // standing in.
    if (event.state != VoipState.incoming) {
      leaveOtherCalls(client: event.client, roomId: event.roomId)
          .catchError((Object e, StackTrace s) {
        Log.onError(e, s, content: "Could not leave the other calls");
      });
    }

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
    // By equality, not sessionId: LiveKit sessions all report an empty
    // sessionId, so a late hang up used to de-register the call the user had
    // just rejoined (issue #48), and a LiveKit session is only equal to
    // itself. Not by identity either: MatrixVoipComponent hands out a new
    // MatrixVoipSession for every event about a call, equal by call id, and
    // a legacy call never left the list.
    currentSessions.removeWhere((element) => element == event);

    AudioProcessingManager.instance.onSessionEnded(event);

    if (currentSessions.where((e) => e.state == VoipState.incoming).isEmpty) {
      stopRingtone();
    }

    endCallSound();
  }

  /// Which of [sessions] joining [roomId] on [client] has to end, so a
  /// person is only ever in one voice channel.
  ///
  /// The room being joined is not in the list: the component leaving and
  /// rejoining its own room has its own path through that (issue #48). Nor
  /// is a session that is still ringing — an incoming call is not one they
  /// are in, and hanging it up would decline it on their behalf — or one
  /// that has already ended.
  static List<VoipSession> callsToLeave(
    Iterable<VoipSession> sessions,
    Client client,
    String roomId,
  ) =>
      sessions
          .where((session) =>
              !(session.client == client && session.roomId == roomId) &&
              session.state != VoipState.incoming &&
              session.state != VoipState.ended)
          .toList();

  /// Ends every voice session [callsToLeave] names.
  ///
  /// One that will not end does not hold up the join: better to be in the
  /// room they asked for than in neither.
  Future<void> leaveOtherCalls({
    required Client client,
    required String roomId,
  }) async {
    final others = callsToLeave(currentSessions, client, roomId);

    await Future.wait(others.map((session) async {
      try {
        Log.i("Leaving ${session.roomName} to join another voice channel");
        await session.hangUpCall();
      } catch (e, s) {
        Log.onError(e, s, content: "Could not leave ${session.roomName}");
      }
    }));
  }

  /// Leaves every call the user is in, for the disconnect control outside
  /// the window. A call that is only ringing is not one they are in: it goes
  /// on ringing rather than being declined on their behalf.
  Future<void> disconnect() async {
    final calls = currentSessions
        .where((session) =>
            session.state != VoipState.incoming &&
            session.state != VoipState.ended)
        .toList();

    await Future.wait(calls.map((session) async {
      try {
        Log.i("Disconnecting from ${session.roomName}");
        await session.hangUpCall();
      } catch (e, s) {
        Log.onError(e, s, content: "Could not leave ${session.roomName}");
      }
    }));
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

  /// Unmuting a deafened session undeafens it too, and opens the mic even if
  /// it was muted before deafening: the session does both (DeafenRule).
  /// Undeafening instead would put that earlier mute back.
  void unmute() {
    for (var session in currentSessions) {
      session.setMicrophoneMute(false);
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

  /// Someone in the call started sharing their screen. Like joining, it is
  /// the room's noise: not for a deafened user.
  void screenShareStartedSound() => _playCue("screenshare_started.ogg");

  /// Someone in the call turned their camera on.
  void cameraOnSound() => _playCue("camera_on.ogg");

  void _playCue(String sound) {
    if (isDeafened) return;
    try {
      cueSoundPlayer ??= Player(configuration: PlayerConfiguration());
      cueSoundPlayer!.setVolume(preferences.notificationsVolume.value);
      cueSoundPlayer!.open(Media("asset:///assets/sound/$sound"));
    } catch (e) {
      Log.w("Could not play a call sound: $e");
    }
  }

  /// Releases the sound players. The client manager calls this when it is
  /// closed, which an app refresh does on every refresh.
  void dispose() {
    stopRingtone();
    muteSoundPlayer?.dispose();
    muteSoundPlayer = null;
    unmuteSoundPlayer?.dispose();
    unmuteSoundPlayer = null;
    cueSoundPlayer?.dispose();
    cueSoundPlayer = null;
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

  /// Null where no player can be made (media_kit not initialised, as in
  /// tests): a call sound that cannot play must not get in the way of the
  /// bookkeeping around it, such as releasing the voice DSP when a call ends.
  Player? getSoundPlayer() {
    try {
      player ??= Player(configuration: PlayerConfiguration());
      player!.setVolume(preferences.notificationsVolume.value);
    } catch (e) {
      Log.w("Could not play a call sound: $e");
    }
    return player;
  }
}
