import 'package:commet/client/client.dart';
import 'package:commet/client/components/room_component.dart';
import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/utils/image_or_icon.dart';

/// Media a participant is publishing that the room list shows (issue #9).
enum LiveMedia { screen, camera }

class RoomActivitySession {
  Set<String> participants;

  /// What each participant is publishing, for those who reported it or are
  /// in our own call. Participants without an entry publish nothing we know
  /// of.
  final Map<String, Set<LiveMedia>> liveMedia = {};

  String application;

  bool thirdparty;

  ImageOrIcon icon;

  String? knownName;
  String get name => knownName ?? application;

  UserWidgetInfo? associatedWidget;

  RoomActivitySession(
      {required this.participants,
      required this.application,
      this.thirdparty = true,
      required this.icon,
      this.associatedWidget,
      String? appName}) {
    this.knownName = appName;
  }
}

abstract class ActivitiesComponent<R extends Client, T extends Room>
    implements RoomComponent<R, T> {
  List<RoomActivitySession> getSessions();

  Stream<void> get onSessionsChanged;

  Future<void> clearMemberships(RoomActivitySession session);
}
