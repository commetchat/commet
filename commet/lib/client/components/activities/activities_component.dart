import 'package:commet/client/client.dart';
import 'package:commet/client/components/room_component.dart';
import 'package:commet/utils/image_or_icon.dart';

class RoomActivitySession {
  Set<String> participants;

  String application;

  bool thirdparty;

  ImageOrIcon icon;

  String? knownName;
  String get name => knownName ?? application;

  RoomActivitySession(
      {required this.participants,
      required this.application,
      this.thirdparty = true,
      required this.icon,
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
