import 'dart:async';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/space_component.dart';
import 'package:commet/client/permissions.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/client/space_child.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:commet/debug/log.dart';

abstract class Space {
  late Key key = UniqueKey();

  String get identifier;

  Client get client;

  Permissions get permissions;

  String get displayName;

  ImageProvider? get avatar;

  List<Room> get rooms;

  List<Room> get roomsWithChildren {
    var result = List<Room>.from(rooms);
    List<Space> handledSpaces = List.empty(growable: true);

    for (var space in subspaces) {
      _addSubspaceRooms(result, space, handledSpaces);
    }

    return result;
  }

  void _addSubspaceRooms(
      List<Room> rooms, Space space, List<Space> handledSpaces) {
    rooms.addAll(space.rooms);
    handledSpaces.add(space);
    for (var subspace in space.subspaces) {
      if (handledSpaces.contains(subspace)) {
        var info = "";
        for (var i in handledSpaces) {
          info += " -> ${i.displayName}\n";
        }
        info += " -> ${subspace.displayName} <- this space is in a loop\n";

        Log.e("Detected recursive space hierarchy, this is not good!\n${info}");
      } else {
        if (handledSpaces.contains(subspace) == false) {
          _addSubspaceRooms(rooms, subspace, handledSpaces);
        }
      }
    }
  }

  List<Space> get subspaces;

  List<SpaceChild> get children;

  Future<void> setChildrenOrder(List<SpaceChild> children,
      {Function(double?)? onProgressChanged});

  bool get isTopLevel;

  String get topic;

  PushRule get pushRule;

  RoomVisibility get visibility;

  Color get color;

  String get developerInfo;

  Stream<void> get onUpdate;

  Stream<Room> get onChildRoomUpdated;

  Stream<int> get onRoomAdded;

  Stream<int> get onRoomRemoved;

  Stream<void> get onChildRoomsUpdated;

  Stream<int> get onChildRoomPreviewAdded;

  Stream<int> get onChildRoomPreviewRemoved;

  Stream<int> get onChildSpaceAdded;

  Stream<int> get onChildSpaceRemoved;

  Stream<void> get onChildRoomPreviewsUpdated;

  List<RoomPreview> get childPreviews;

  bool get fullyLoaded;

  String get localId => "${client.identifier}:$identifier";

  int get notificationCount => roomsWithChildren
      .where((element) => element.pushRule == PushRule.notify)
      .fold(
          0,
          (previousValue, element) =>
              previousValue + element.notificationCount);

  int get highlightedNotificationCount => roomsWithChildren
      .where((element) => element.pushRule != PushRule.dontNotify)
      .fold(
          0,
          (previousValue, element) =>
              previousValue + element.highlightedNotificationCount);

  int get displayNotificationCount =>
      pushRule == PushRule.notify ? notificationCount : 0;

  int get displayHighlightedNotificationCount =>
      pushRule == PushRule.dontNotify ? 0 : highlightedNotificationCount;

  bool containsRoom(String identifier);

  Future<List<RoomPreview>> fetchChildren();

  Future<Room> createRoom(String name, CreateRoomArgs args);

  /// Adds an existing room as a child of a space
  Future<void> setSpaceChildRoom(Room room);

  Future<void> setSpaceChildSpace(Space room);

  Future<void> removeChild(SpaceChild child);

  Future<void> setTopic(String topic);

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
