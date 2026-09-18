import 'dart:async';

import 'package:collection/collection.dart';
import 'package:commet/client/call_manager.dart';
import 'package:commet/client/components/activities/activities_component.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/matrix_sync_listener.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_call_membership.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/image_or_icon.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/matrix_api_lite/model/sync_update.dart';

class MatrixActivitiesComponent
    implements
        ActivitiesComponent<MatrixClient, MatrixRoom>,
        MatrixRoomSyncListener {
  @override
  MatrixClient client;

  @override
  MatrixRoom room;

  /// Injected for tests; otherwise resolved lazily from the global
  /// [clientManager], which is still null while rooms are first loaded.
  final CallManager? _injectedCallManager;

  MatrixActivitiesComponent(this.client, this.room, {CallManager? callManager})
      : _injectedCallManager = callManager;

  final StreamController _onParticipantsChanged = StreamController.broadcast();

  CallManager? get _callManager =>
      _injectedCallManager ?? clientManager?.callManager;

  final List<StreamSubscription> _callManagerSubs = [];
  final Map<VoipSession, StreamSubscription> _sessionSubs = {};
  bool _watchingCallManager = false;

  bool _isOurCall(VoipSession session) =>
      session.client == client && session.roomId == room.identifier;

  /// Our own call membership is only listed while a session for this room is
  /// registered with [CallManager] (see the filter in [getSessions]). The
  /// membership sync usually lands before the LiveKit session is registered,
  /// so the list must be recomputed when the session starts or ends too, and
  /// whenever its streams change (live badges, see [_applyCallStreams]).
  void _watchCallManager() {
    if (_watchingCallManager) return;
    final callManager = _callManager;
    if (callManager == null) return;
    _watchingCallManager = true;

    void watch(VoipSession session) {
      _sessionSubs[session] ??=
          session.onStateChanged.listen((_) => _onParticipantsChanged.add(()));
    }

    for (final session in callManager.currentSessions.where(_isOurCall)) {
      watch(session);
    }

    _callManagerSubs.add(callManager.currentSessions.onAdd.listen((session) {
      if (!_isOurCall(session)) return;
      watch(session);
      _onParticipantsChanged.add(());
    }));
    _callManagerSubs.add(callManager.currentSessions.onRemove.listen((session) {
      if (!_isOurCall(session)) return;
      _sessionSubs.remove(session)?.cancel();
      _onParticipantsChanged.add(());
    }));
  }

  static const callMemberStateEvent = "org.matrix.msc3401.call.member";

  @override
  List<RoomActivitySession> getSessions() {
    final state = room.matrixRoom.states[callMemberStateEvent];
    if (state == null) {
      return [];
    }

    List<RoomActivitySession> activities = List.empty(growable: true);
    final now = DateTime.now();

    for (var entry in state.entries) {
      if (entry.value.content.isEmpty) continue;

      var application = entry.value.content.tryGet<String>("application");
      if (application == null) continue;
      var activity =
          activities.firstWhereOrNull((i) => i.application == application);

      final event = entry.value;
      final sentAt = event is Event ? event.originServerTs : null;
      if (MatrixCallMembership.isExpired(event.content, sentAt, now)) {
        Log.i("Membership state is expired, skipping");
        continue;
      }

      // A call membership written by this device is only real while this
      // device is actually in the call; otherwise it is a leftover from a
      // previous run that was closed without hanging up.
      if (application == "m.call" &&
          entry.value.senderId == client.self?.identifier &&
          entry.value.content.tryGet<String>("device_id") ==
              client.matrixClient.deviceID &&
          _callManager?.getCallInRoom(client, room.identifier) == null) {
        continue;
      }

      if (activity == null) {
        var widgetComp = client.getComponent<WidgetComponent>();
        var widgets = widgetComp?.getWidgets(room);

        var widget = widgets?.firstWhereOrNull((i) => i.type == application);
        String? name = widget?.name;

        Log.i("Found widget for ${application} : ${name} ${widget}");

        bool thirdparty = true;

        var icon = widget?.icon ?? ImageOrIcon(icon: Icons.question_mark);

        if (application == "m.call") {
          thirdparty = false;
        }

        activity = RoomActivitySession(
            participants: Set(),
            application: application,
            appName: name,
            icon: icon,
            associatedWidget: widget,
            thirdparty: thirdparty);
        activities.add(activity);
      }

      activity.participants.add(entry.value.senderId);

      // Only full events: stripped state has no timestamp, so it never
      // expires and a stale LIVE badge would stay forever.
      if (application == "m.call" && event is Event) {
        final media = MatrixCallMembership.liveMediaOf(event.content);
        if (media.isNotEmpty) {
          activity.liveMedia
              .putIfAbsent(event.senderId, () => {})
              .addAll(media);
        }

        // Only for a membership that says anything about it: a client that
        // does not report its voice state must not read as unmuted.
        if (event.content.containsKey(MatrixCallMembership.voiceStateKey)) {
          activity.voiceState[event.senderId] =
              MatrixCallMembership.voiceStateOf(event.content);
        }
      }
    }

    final call = activities.firstWhereOrNull((a) => a.application == "m.call");
    final session = _callManager?.getCallInRoom(client, room.identifier);
    if (call != null && session != null) {
      _applyCallStreams(call, session);
    }

    return activities;
  }

  /// For people in our own call, LiveKit is right away what their
  /// memberships only say after a debounced write and a sync.
  static void _applyCallStreams(RoomActivitySession call, VoipSession session) {
    final inCall = <String, Set<LiveMedia>>{};
    final voice = <String, Set<VoiceState>>{};
    for (final stream in session.streams) {
      final media = inCall.putIfAbsent(stream.streamUserId, () => {});
      switch (stream.type) {
        case VoipStreamType.screenshare:
          media.add(LiveMedia.screen);
        case VoipStreamType.video:
          media.add(LiveMedia.camera);
        case VoipStreamType.audio:
          // Only the microphone says anything about muting: a muted camera
          // or screen share is not a muted member.
          voice[stream.streamUserId] = {
            if (stream.isMuted || stream.isDeafened) VoiceState.muted,
            if (stream.isDeafened) VoiceState.deafened,
          };
        case VoipStreamType.screenshareAudio:
          break;
      }
    }
    call.liveMedia.addAll(inCall);
    call.voiceState.addAll(voice);
  }

  @override
  Stream<void> get onSessionsChanged {
    _watchCallManager();
    return _onParticipantsChanged.stream;
  }

  @override
  onSync(JoinedRoomUpdate update) {
    // A limited sync delivers state changes in `state`, not the timeline.
    final events = [...?update.state, ...?update.timeline?.events];
    if (events.any((event) => event.type == callMemberStateEvent)) {
      _onParticipantsChanged.add(());
    }
  }

  @override
  Future<void> clearMemberships(RoomActivitySession session) async {
    final state = room.matrixRoom.states[callMemberStateEvent];
    if (state == null) {
      return;
    }

    for (var entry in state.entries) {
      if (entry.value.content.isEmpty) continue;

      var application = entry.value.content.tryGet<String>("application");
      if (application == null) continue;

      if (application != session.application) continue;

      if (entry.value.senderId != client.self!.identifier) continue;

      if (entry.value.content.isEmpty) continue;

      await room.matrixRoom.client.setRoomStateWithKey(
          room.identifier, callMemberStateEvent, entry.value.stateKey!, {});
    }
  }
}
