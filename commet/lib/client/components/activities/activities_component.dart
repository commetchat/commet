import 'package:commet/client/client.dart';
import 'package:commet/client/components/room_component.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/utils/image_or_icon.dart';
import 'package:flutter/material.dart';

class RoomRealTimeActivitySession {
  Set<String> participants;

  String application;

  bool thirdparty;

  ImageOrIcon icon;

  String? knownName;
  String get name => knownName ?? application;

  ActivityInfo? associatedActivityInfo;

  RoomRealTimeActivitySession({
    required this.participants,
    required this.application,
    this.thirdparty = true,
    required this.icon,
    this.associatedActivityInfo,
    String? appName,
  }) {
    this.knownName = appName;
  }
}

enum ActivityType { Widget, WebXDC }

class ActivityInfo {
  ActivityType activityType;

  String displayName;

  String sessionId;

  ImageOrIcon icon;

  String? status;

  ActivityInfo({
    required this.activityType,
    required this.displayName,
    required this.sessionId,
    required this.icon,
    this.status,
  });
}

abstract class ActivitiesComponent<R extends Client, T extends Room>
    implements RoomComponent<R, T> {
  List<RoomRealTimeActivitySession> getRealTimeSessions();

  Stream<void> get onSessionsChanged;

  Future<void> clearMemberships(RoomRealTimeActivitySession session);

  ActivityInfo? getInfoFromEvent(TimelineEvent event, Timeline timeline);

  Future<void> openActivity(ActivityInfo activity, BuildContext context);
}
