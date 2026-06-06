import 'package:commet/client/client.dart';
import 'package:commet/client/components/room_component.dart';

class RoomActivitySession {
  Set<String> participants;

  String application;

  bool thirdparty;

  String? knownName;
  String get name => knownName ?? application;

  RoomActivitySession(
      {required this.participants,
      required this.application,
      this.thirdparty = true,
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
