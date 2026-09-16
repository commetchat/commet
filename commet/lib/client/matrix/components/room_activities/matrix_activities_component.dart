import 'dart:async';

import 'package:collection/collection.dart';
import 'package:commet/client/call_manager.dart';
import 'package:commet/client/components/activities/activities_component.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/matrix_sync_listener.dart';
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
  bool _watchingCallManager = false;

  /// Our own call membership is only listed while a session for this room is
  /// registered with [CallManager] (see the filter in [getSessions]). The
  /// membership sync usually lands before the LiveKit session is registered,
  /// so the list must be recomputed when the session starts or ends too.
  void _watchCallManager() {
    if (_watchingCallManager) return;
    final callManager = _callManager;
    if (callManager == null) return;
    _watchingCallManager = true;

    void onSessionChanged(VoipSession session) {
      if (session.client == client && session.roomId == room.identifier) {
        _onParticipantsChanged.add(());
      }
    }

    _callManagerSubs
        .add(callManager.currentSessions.onAdd.listen(onSessionChanged));
    _callManagerSubs
        .add(callManager.currentSessions.onRemove.listen(onSessionChanged));
  }

  static const callMemberStateEvent = "org.matrix.msc3401.call.member";

  @override
  List<RoomActivitySession> getSessions() {
    final state = room.matrixRoom.states[callMemberStateEvent];
    if (state == null) {
      return [];
    }

    List<RoomActivitySession> activities = List.empty(growable: true);

    for (var entry in state.entries) {
      if (entry.value.content.isEmpty) continue;

      var application = entry.value.content.tryGet<String>("application");
      if (application == null) continue;
      var activity =
          activities.firstWhereOrNull((i) => i.application == application);

      var expires = entry.value.content.tryGet<int>("expires");

      if (expires != null) {
        if (entry.value case Event ev) {
          var expire = ev.originServerTs.add(Duration(milliseconds: expires));

          if (DateTime.now().millisecondsSinceEpoch >
              expire.millisecondsSinceEpoch) {
            Log.i("Membership state is expired, skipping");
            continue;
          }
        }
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
    }

    return activities;
  }

  @override
  Stream<void> get onSessionsChanged {
    _watchCallManager();
    return _onParticipantsChanged.stream;
  }

  @override
  onSync(JoinedRoomUpdate update) {
    if (update.timeline?.events == null) {
      return;
    }

    for (var event in update.timeline!.events!) {
      if (event.type == callMemberStateEvent) {
        _onParticipantsChanged.add(());
      }
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
