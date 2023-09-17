import 'dart:async';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/space_component.dart';
import 'package:commet/client/permissions.dart';
import 'package:commet/client/room_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class Space {
  late Key key = UniqueKey();

  String get identifier;

  Client get client;

  Permissions get permissions;

  String get displayName;

  ImageProvider? get avatar;

  List<Room> get rooms;

  String get topic;

  PushRule get pushRule;

  RoomVisibility get visibility;

  Color get color;

  String get developerInfo;

  Stream<void> get onUpdate;

  Stream<Room> get onChildUpdated;

  Stream<int> get onRoomAdded;

  Stream<int> get onRoomRemoved;

  Stream<void> get onChildrenUpdated;

  Stream<int> get onChildPreviewAdded;

  Stream<int> get onChildPreviewRemoved;

  Stream<void> get onChildPreviewsUpdated;

  List<RoomPreview> get childPreviews;

  bool get fullyLoaded;

  String get localId => "${client.identifier}:$identifier";

  int get notificationCount =>
      rooms.where((element) => element.pushRule == PushRule.notify).fold(
          0,
          (previousValue, element) =>
              previousValue + element.notificationCount);

  int get highlightedNotificationCount =>
      rooms.where((element) => element.pushRule != PushRule.dontNotify).fold(
          0,
          (previousValue, element) =>
              previousValue + element.highlightedNotificationCount);

  int get displayNotificationCount =>
      pushRule == PushRule.notify ? notificationCount : 0;

  int get displayHighlightedNotificationCount =>
      pushRule == PushRule.dontNotify ? 0 : highlightedNotificationCount;

  bool containsRoom(String identifier);

  Future<List<RoomPreview>> fetchChildren();

  Future<Room> createRoom(String name, RoomVisibility visibility);

  /// Adds an existing room as a child of a space
  Future<void> setSpaceChildRoom(Room room);

  /// Load extra information about the space, that is not necessarily required for functionality
  Future<void> loadExtra();

  Future<void> close();

  Future<void> setDisplayName(String newName);

  Future<void> changeAvatar(Uint8List bytes, String? mimeType);

  Future<void> setPushRule(PushRule rule);

  T? getComponent<T extends SpaceComponent>();

  @override
  bool operator ==(Object other) {
    if (other is! Space) return false;
    if (other.client != client) return false;
    if (identical(this, other)) return true;
    return identifier == other.identifier;
  }

  @override
  int get hashCode => identifier.hashCode;
}
