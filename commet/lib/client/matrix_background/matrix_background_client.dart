import 'dart:typed_data';

import 'package:commet/client/auth.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/matrix/database/matrix_database.dart';
import 'package:commet/client/matrix_background/matrix_background_direct_messages_component.dart';
import 'package:commet/client/matrix_background/matrix_background_room.dart';
import 'package:commet/client/profile.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/stored_stream_controller.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart' as matrix;
import 'package:matrix_dart_sdk_drift_db/database.dart';
import 'package:matrix_dart_sdk_drift_db/matrix_dart_sdk_drift_db.dart';

class MatrixBackgroundClient implements Client {
  @override
  Profile? self;
  String databaseId;

  @override
  String get identifier => "background_matrix_client:${databaseId}";

  late MatrixSdkDriftDatabase database;
  late matrix.MatrixApi api;

  List<RoomDataData> allRooms = List.empty();
  List<PreloadRoomStateData> preloadRoomStates = List.empty();
  List<NonPreloadRoomStateData> nonPreloadRoomStates = List.empty();
  List<AccountDataData> accountData = List.empty();

  late final List<Component<MatrixBackgroundClient>> componentsInternal;

  MatrixBackgroundClient({required this.databaseId}) {
    componentsInternal = [
      MatrixBackgroundClientDirectMessagesComponent(this),
    ];
  }

  @override
  List<Room> get singleRooms => [];

  @override
  List<Space> get spaces => [];

  @override
  int? get maxFileSize => 0;

  @override
  Stream<int> get onPeerAdded => Stream.empty();

  @override
  Stream<int> get onRoomAdded => Stream.empty();

  @override
  Stream<int> get onRoomRemoved => Stream.empty();

  @override
  Stream<int> get onSpaceAdded => Stream.empty();

  @override
  Stream<int> get onSpaceRemoved => Stream.empty();

  @override
  Stream<void> get onSync => Stream.empty();

  @override
  List<Peer> get peers => [];

  @override
  List<Room> get rooms => [];

  @override
  StoredStreamController<ClientConnectionStatusUpdate>
      get connectionStatusChanged =>
          StoredStreamController<ClientConnectionStatusUpdate>.new();

  @override
  Future<void> init(bool loadingFromCache,
      {bool isBackgroundService = false}) async {
    final db = await getMatrixDatabase(databaseId);
    if (db is MatrixSdkDriftDatabase) {
      database = db;
    }

    final account = await database.getClient(databaseId);
    Log.i("Got client info: ${account}");

    var homeserver = Uri.parse(account!['homeserver_url']);
    var accessToken = account['token'];

    api = matrix.MatrixApi(
      httpClient: http.Client(),
      homeserver: homeserver,
      accessToken: accessToken,
    );

    accountData = await database.db.select(database.db.accountData).get();

    allRooms = await database.db.select(database.db.roomData).get();

    preloadRoomStates =
        await database.db.select(database.db.preloadRoomState).get();

    nonPreloadRoomStates =
        await database.db.select(database.db.nonPreloadRoomState).get();
  }

  @override
  Widget buildDebugInfo() {
    throw UnimplementedError();
  }

  @override
  Future<void> close() {
    throw UnimplementedError();
  }

  @override
  Future<Room> createRoom(CreateRoomArgs args) {
    throw UnimplementedError();
  }

  @override
  Future<Space> createSpace(CreateRoomArgs args) {
    throw UnimplementedError();
  }

  @override
  Future<LoginResult> executeLoginFlow(LoginFlow flow) {
    throw UnimplementedError();
  }

  @override
  List<T>? getAllComponents<T extends Component<Client>>() {
    return null;
  }

  @override
  T? getComponent<T extends Component>() {
    for (var component in componentsInternal) {
      if (component is T) return component as T;
    }

    return null;
  }

  @override
  Iterable<Room> getEligibleRoomsForSpace(Space space) {
    throw UnimplementedError();
  }

  @override
  Future<Profile?> getProfile(String identifier) {
    throw UnimplementedError();
  }

  @override
  Room? getRoom(String identifier) {
    var data = allRooms.firstWhere((e) => e.roomId == identifier);
    var preload =
        preloadRoomStates.where((e) => e.roomId == identifier).toList();
    var nonPreload =
        nonPreloadRoomStates.where((e) => e.roomId == identifier).toList();
    return MatrixBackgroundRoom(
      this,
      roomId: identifier,
      data: data,
      preloadState: preload,
      nonPreloadState: nonPreload,
    );
  }

  @override
  Future<RoomPreview?> getRoomPreview(String address) {
    throw UnimplementedError();
  }

  @override
  Space? getSpace(String identifier) {
    throw UnimplementedError();
  }

  @override
  Future<RoomPreview?> getSpacePreview(String address) {
    throw UnimplementedError();
  }

  @override
  bool hasPeer(String identifier) {
    throw UnimplementedError();
  }

  @override
  bool hasRoom(String identifier) {
    return allRooms.any((e) => e.roomId == identifier);
  }

  @override
  bool hasSpace(String identifier) {
    throw UnimplementedError();
  }

  @override
  bool isLoggedIn() {
    throw UnimplementedError();
  }

  @override
  Future<Room> joinRoom(String address) {
    throw UnimplementedError();
  }

  @override
  Future<Space> joinSpace(String address) {
    throw UnimplementedError();
  }

  @override
  ValueKey get key => throw UnimplementedError();

  @override
  Future<void> leaveRoom(Room room) {
    throw UnimplementedError();
  }

  @override
  Future<void> leaveSpace(Space space) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() {
    throw UnimplementedError();
  }

  @override
  Future<void> setAvatar(Uint8List bytes, String mimeType) {
    throw UnimplementedError();
  }

  @override
  Future<void> setDisplayName(String name) {
    throw UnimplementedError();
  }

  @override
  Future<(bool, List<LoginFlow>?)> setHomeserver(Uri uri) {
    throw UnimplementedError();
  }

  @override
  bool get supportsE2EE => throw UnimplementedError();
}
