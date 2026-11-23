import 'dart:async';

import 'package:collection/collection.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/activities/activities_component.dart';
import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/matrix_sync_listener.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/image_or_icon.dart';
import 'package:commet/utils/mime.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as mx;
import 'package:matrix/matrix_api_lite/model/sync_update.dart';
import 'package:matrix/matrix_api_lite/utils/try_get_map_extension.dart';
import 'package:tiamat/config/style/theme_json_converter.dart';

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
  List<RoomRealTimeActivitySession> getRealTimeSessions() {
    final state = room.matrixRoom.states[callMemberStateEvent];
    if (state == null) {
      return [];
    }

    List<RoomRealTimeActivitySession> activities = List.empty(growable: true);
    String? sessionId;

    for (var entry in state.entries) {
      if (entry.value.content.isEmpty) continue;

      var application = entry.value.content.tryGet<String>("application");
      String? webXdcSessionId;
      String? webXdcAppKey;

      if (application == "chat.commet.webxdc-adapter") {
        var webXdcMetadata = entry.value.content.tryGetMap(
          "chat.commet.webxdc-adapter.metadata",
        );
        if (webXdcMetadata != null) {
          webXdcSessionId = webXdcMetadata.tryGet<String>("session_id");
          webXdcAppKey = webXdcMetadata.tryGet<String>("application_key");
          sessionId = webXdcSessionId;
        }
      } else {
        sessionId = application;
      }

      if (application == null) continue;
      var activity = activities.firstWhereOrNull(
        (i) =>
            i.application == application &&
            i.associatedActivityInfo?.sessionId == sessionId,
      );

      var expires = entry.value.content.tryGet<int>("expires");

      if (expires != null) {
        if (entry.value case mx.Event ev) {
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

        var info = ActivityInfo(
          activityType: ActivityType.Widget,
          displayName: name ?? application,
          sessionId: application,
          icon: icon,
        );

        if (webXdcSessionId != null && webXdcAppKey != null) {
          var session = getWebxdcAppInfoFromStateKey(
            webXdcAppKey,
            webXdcSessionId,
          );
          if (session != null) {
            icon = session.icon;
            name = session.displayName;
          }

          info = ActivityInfo(
            activityType: ActivityType.WebXDC,
            displayName: name ?? application,
            sessionId: webXdcSessionId,
            icon: icon,
          );
        }

        activity = RoomRealTimeActivitySession(
          participants: Set(),
          application: application,
          appName: name,
          icon: icon,
          associatedActivityInfo: info,
          thirdparty: thirdparty,
        );
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
  Future<void> clearMemberships(RoomRealTimeActivitySession session) async {
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
        room.identifier,
        callMemberStateEvent,
        entry.value.stateKey!,
        {},
      );
    }
  }

  @override
  ActivityInfo? getInfoFromEvent(TimelineEvent event, Timeline timeline) {
    if (!(event is MatrixTimelineEvent)) return null;

    if (event.event.type == "chat.commet.webxdc-adapter.session_start") {
      String? key = event.event.content.tryGet("application_key");
      if (key == null) return null;

      return getWebxdcAppInfoFromStateKey(key, event.eventId);
    }

    if (event.event.type == "chat.commet.webxdc-adapter.update") {
      if (event.event.relationshipType == "chat.commet.webxdc-adapter.update" &&
          event.event.relationshipEventId != null) {
        var related = timeline.tryGetEvent(event.event.relationshipEventId!);

        if (related != null) {
          var result = getInfoFromEvent(related, timeline);

          var update = event.event.content.tryGetMap("update");
          String? info = update?.tryGet("info");
          info ??= update?.tryGet("summary");
          result?.status = info;

          return result;
        }
      }

      return null;
    }

    return null;
  }

  ActivityInfo? getWebxdcAppInfoFromStateKey(String key, String sessionId) {
    var applications = room.matrixRoom.states["chat.commet.webxdc-adapter.app"];

    if (applications == null) return null;

    var state = applications[key];

    if (state == null) return null;

    String? name = state.content.tryGet("name");
    String? imageUrl = state.content.tryGet("icon");
    String? imageMime = state.content.tryGet("icon_mime");
    ImageProvider? image;

    if (Mime.imageTypes.contains(imageMime) && imageUrl != null) {
      image = MatrixMxcImage(
        Uri.parse(imageUrl),
        (room.client as MatrixClient).matrixClient,
      );
    }

    return ActivityInfo(
      activityType: ActivityType.WebXDC,
      sessionId: sessionId,
      displayName: name ?? "Unknown App",
      status: "Activity started",
      icon: ImageOrIcon(icon: Icons.widgets, image: image),
    );
  }

  @override
  Future<void> openActivity(ActivityInfo activity, BuildContext context) async {
    bool isInActivity = WidgetComponent.currentSessions.any(
      (element) => room == element.room,
    );

    if (isInActivity == true) return;

    var confirm = await AdaptiveDialog.confirmation(
      context,
      prompt: "Open **${activity.displayName}**?",
    );

    if (confirm != true) return;

    switch (activity.activityType) {
      case ActivityType.Widget:
        var widgetsComp = room.client.getComponent<WidgetComponent>();
        var widgets = widgetsComp!.getWidgets(room);

        var widget = widgets.firstWhereOrNull(
          (i) => i.type == activity.sessionId,
        );

        widgetsComp.openWidget(widget!, room, context);

        break;
      case ActivityType.WebXDC:
        var widgetsComp = room.client.getComponent<WidgetComponent>();
        var widgets = widgetsComp!.getWidgets(room);

        var xdcWidget = widgets.firstWhereOrNull(
          (i) => i.type == "chat.commet.webxdc-adapter",
        ) as MatrixUserWidgetInfo;

        var info = MatrixUserWidgetInfo(
          id: xdcWidget.id,
          name: activity.displayName,
          stateKey: xdcWidget.stateKey,
          url: xdcWidget.url,
          type: xdcWidget.type,
          icon: activity.icon,
          roomId: xdcWidget.roomId,
          event: xdcWidget.event,
        );
        widgetsComp.openWidget(
          info,
          room,
          context,
          additionalAvailableArgs: {
            "\$chat.commet.webxdc-adapter.session_id": activity.sessionId,
          },
        );

        break;
    }
  }
}
