import 'dart:async';

import 'package:collection/collection.dart';
import 'package:commet/client/components/activities/activities_component.dart';
import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/matrix_sync_listener.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/debug/log.dart';
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

  MatrixActivitiesComponent(this.client, this.room) {}

  StreamController _onParticipantsChanged = StreamController.broadcast();

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
  Stream<void> get onSessionsChanged => _onParticipantsChanged.stream;

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
