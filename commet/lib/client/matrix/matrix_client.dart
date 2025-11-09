import 'dart:async';
import 'package:commet/client/alert.dart';
import 'package:commet/client/auth.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/component_registry.dart';
import 'package:commet/client/error_profile.dart';
import 'package:commet/client/matrix/auth/matrix_sso_login_flow.dart';
import 'package:commet/client/matrix/auth/matrix_username_password_login_flow.dart';
import 'package:commet/client/matrix/components/matrix_sync_listener.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_voip_room_component.dart';
import 'package:commet/client/matrix/database/matrix_database.dart';
import 'package:commet/client/matrix/extensions/matrix_client_extensions.dart';
import 'package:commet/client/matrix/matrix_native_implementations.dart';
import 'package:commet/client/matrix/matrix_profile.dart';
import 'package:commet/client/profile.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/experiments.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/diagnostic/diagnostics.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/pages/matrix/authentication/matrix_uia_request.dart';
import 'package:commet/utils/list_extension.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:commet/utils/stored_stream_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:commet/client/client.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:matrix/encryption.dart';
import 'package:flutter_vodozemac/flutter_vodozemac.dart' as vodozemac;

import '../../ui/atoms/code_block.dart';
import '../../ui/pages/matrix/verification/matrix_verification_page.dart';
import 'matrix_room.dart';
import 'matrix_space.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

class MatrixClient extends Client {
  late matrix.Client _matrixClient;
  late final List<Component<MatrixClient>> componentsInternal;

  Future? firstSync;

  bool firstSyncComplete = false;

  matrix.MediaConfig? config;

  matrix.Client get matrixClient => _matrixClient;

  late String _id;

  final NotifyingList<Room> _rooms = NotifyingList.empty(
    growable: true,
  );
  final NotifyingList<Space> _spaces = NotifyingList.empty(
    growable: true,
  );

  final NotifyingList<Peer> _peers = NotifyingList.empty(
    growable: true,
  );

  final Map<String, Peer> _peersMap = {};

  final StreamController _onSync = StreamController.broadcast();

  matrix.NativeImplementations get nativeImplentations => BuildConfig.WEB
      ? const matrix.NativeImplementationsDummy()
      : NativeImplementationsCustom(compute);

  MatrixClient(
      {required String identifier, required matrix.DatabaseApi database}) {
    if (preferences.developerMode) {
      matrix.Logs().level = matrix.Level.verbose;
    } else {
      matrix.Logs().level = matrix.Level.warning;
    }

    _id = identifier;
    _matrixClient = _createMatrixClient(identifier, database);

    _matrixClient.onSync.stream.listen(onMatrixClientSync);
    componentsInternal = ComponentRegistry.getMatrixComponents(this);
  }

  static Future<MatrixClient> create(String identifier) async {
    final database = await getMatrixDatabase(identifier);
    return MatrixClient(identifier: identifier, database: database);
  }

  static String hash(String name) {
    var bytes = utf8.encode(name);
    var hash = sha256.convert(bytes);
    return hash.toString();
  }

  @override
  bool get supportsE2EE => true;

  @override
  int? get maxFileSize => config?.mUploadSize;

  @override
  String get identifier => _id;

  @override
  Stream<int> get onPeerAdded => _peers.onAdd;

  @override
  Stream<int> get onRoomAdded => _rooms.onAdd;

  @override
  Stream<int> get onSpaceAdded => _spaces.onAdd;

  @override
  Stream<int> get onRoomRemoved => _rooms.onRemove;

  @override
  Stream<int> get onSpaceRemoved => _spaces.onRemove;

  @override
  Stream<void> get onSync => _onSync.stream;

  @override
  List<Peer> get peers => _peers;

  @override
  List<Room> get rooms => _rooms;

  @override
  List<Room> get singleRooms => throw UnimplementedError();

  @override
  List<Space> get spaces => _spaces;

  @override
  StoredStreamController<ClientConnectionStatusUpdate> connectionStatusChanged =
      StoredStreamController<ClientConnectionStatusUpdate>();

  static String get matrixClientOlmMissingMessage => Intl.message(
        "libolm is not installed or was not found. End to End Encryption will not be available until this is resolved",
        name: "matrixClientOlmMissingMessage",
        desc:
            "Text that explains to the user that libolm dependency is not found",
      );

  static String get matrixClientVodozemacMissingMessage => Intl.message(
        "vodozemac is not installed or was not found. End to End Encryption will not be available until this is resolved",
        name: "matrixClientVodozemacMissingMessage",
        desc:
            "Text that explains to the user that vodozemac dependency is not found",
      );

  static String get matrixClientEncryptionWarningTitle => Intl.message(
        "Encryption Warning",
        name: "matrixClientEncryptionWarningTitle",
        desc: "Title of a warning about encryption",
      );

  static Future<void> loadFromDB(ClientManager manager,
      {bool isBackgroundService = false}) async {
    await Diagnostics.general.timeAsync("loadFromDB", () async {
      var clients = preferences.getRegisteredMatrixClients();

      List<Future> futures = List.empty(growable: true);

      futures.add(_checkSystem(manager));

      if (clients != null) {
        for (var clientName in clients) {
          var client = await MatrixClient.create(clientName);
          manager.addClient(client);
          futures.add(Diagnostics.general
              .timeAsync("Initializing client $clientName", () async {
            try {
              await client.init(true, isBackgroundService: isBackgroundService);
            } catch (error, trace) {
              Log.onError(error, trace,
                  content: "Unable to load client $clientName from database");

              client.self = ErrorProfile();
              manager.alertManager.addAlert(Alert(AlertType.warning,
                  messageGetter: () =>
                      "One of the registered accounts (${clientName.substring(0, 8)}...) was unable to load correctly, please check the logs for more details",
                  titleGetter: () => "Unable to load account"));
            }
          }));
        }
      }

      await Future.wait(futures);
    });
  }

  static Future<void> _checkSystem(ClientManager clientManager) async {
    try {
      await vod.init(wasmPath: './assets/assets/vodozemac/');
      if (!vod.isInitialized()) {
        throw Exception("Vodozemac failed to initialize!");
      }
    } catch (exception, trace) {
      Log.onError(exception, trace, content: "Failed to initialize vodozemac");
      clientManager.alertManager.addAlert(Alert(
        AlertType.warning,
        titleGetter: () => matrixClientEncryptionWarningTitle,
        messageGetter: () => matrixClientVodozemacMissingMessage,
      ));
    }
  }

  static matrix.NativeImplementations get nativeImplementations =>
      BuildConfig.WEB
          ? const matrix.NativeImplementationsDummy()
          : matrix.NativeImplementationsIsolate(compute,
              vodozemacInit: vodozemac.init);
  @override
  Future<void> init(bool loadingFromCache,
      {bool isBackgroundService = false}) async {
    if (!_matrixClient.isLogged()) {
      await Diagnostics.general.timeAsync("Matrix client init", () async {
        await _matrixClient.init(
            waitForFirstSync: !loadingFromCache,
            waitUntilLoadCompletedLoaded: true,
            startSyncLoop: !isBackgroundService,
            onMigration: () => Log.w("Matrix Database is migrating"));
      });

      await _updateOwnProfile();

      if (!isBackgroundService) {
        firstSync = _matrixClient.oneShotSync().then((_) {
          firstSyncComplete = true;
        });
      }
    }

    _matrixClient.getConfig().then((value) {
      config = value;
    });

    _updateRoomslist();
    _updateSpacesList();

    _matrixClient.onKeyVerificationRequest.stream.listen((event) {
      AdaptiveDialog.show(navigator.currentContext!,
          builder: (_) => MatrixVerificationPage(request: event),
          title: "Verification Request");
    });

    _matrixClient.onUiaRequest.stream.listen((event) {
      if (event.state == matrix.UiaRequestState.waitForUser) {
        AdaptiveDialog.show(navigator.currentContext!,
            builder: (_) => MatrixUIARequest(event, this),
            title: "Authentication Request");
      }
    });
  }

  void onMatrixClientSync(matrix.SyncUpdate update) {
    _handleComponentSync(update);

    _onSync.add(null);
    _updateRoomslist();
    _updateSpacesList();
  }

  void _handleComponentSync(matrix.SyncUpdate update) {
    var roomUpdates = update.rooms?.join;
    if (roomUpdates != null) {
      for (var key in roomUpdates.keys) {
        var room = getRoom(key);
        if (room != null) {
          var components = room.getAllComponents();
          for (var comp in components) {
            if (comp is MatrixRoomSyncListener) {
              (comp as MatrixRoomSyncListener).onSync(roomUpdates[key]!);
            }
          }
        }
      }
    }
  }

  @override
  bool isLoggedIn() => _matrixClient.isLogged();

  matrix.Client _createMatrixClient(String name, matrix.DatabaseApi database) {
    var client = matrix.Client(
      name,
      verificationMethods: {
        KeyVerificationMethod.emoji,
        KeyVerificationMethod.numbers
      },
      importantStateEvents: {
        "im.ponies.room_emotes",
        "m.room.power_levels",
        "m.room.join_rules",
        MatrixVoipRoomComponent.callMemberStateEvent,
      },
      supportedLoginTypes: {
        matrix.AuthenticationTypes.password,
        matrix.AuthenticationTypes.sso
      },
      nativeImplementations: nativeImplementations,
      database: database,
      logLevel: matrix.Level.verbose,
    );

    client.onSyncStatus.stream.listen(onSyncStatusChanged);

    return client;
  }

  matrix.Client getMatrixClient() {
    return _matrixClient;
  }

  @override
  Future<void> logout() {
    preferences.removeRegisteredMatrixClient(_matrixClient.clientName);
    return _matrixClient.logout();
  }

  Future<void> _postLoginSuccess() async {
    await _updateOwnProfile();
    for (var component in getAllComponents()!) {
      if (component is NeedsPostLoginInit) {
        (component as NeedsPostLoginInit).postLoginInit();
      }
    }
  }

  Future<void> _updateOwnProfile() async {
    final id = _matrixClient.userID;
    if (id != null) {
      var data = await _matrixClient.database.getUserProfile(id);
      if (data != null) {
        self = MatrixProfile(
            _matrixClient,
            matrix.Profile(
              userId: id,
              displayName: data.displayname,
              avatarUrl: data.avatarUrl,
            ));

        // Update own profile, but lets not wait for it before continuing
        _matrixClient.getProfileFromUserId(id).then((profile) {
          self = MatrixProfile(_matrixClient, profile);
        });
      } else {
        self = MatrixProfile(_matrixClient,
            await _matrixClient.getProfileFromUserId(_matrixClient.userID!));
      }
    }
  }

  void _updateRoomslist() {
    var joinedRooms = _matrixClient.rooms
        .where((element) => !element.isSpace && element.membership.isJoin);

    for (var room in joinedRooms) {
      if (hasRoom(room.id)) continue;
      rooms.add(MatrixRoom(this, room, _matrixClient));
    }

    rooms.removeWhere((e) => !joinedRooms.any((r) => r.id == e.identifier));
  }

  void _updateSpacesList() {
    var allSpaces = _matrixClient.rooms.where((element) =>
        element.isSpace && element.membership == matrix.Membership.join);

    bool didChange = false;
    for (var space in allSpaces) {
      if (hasSpace(space.id)) continue;
      spaces.add(MatrixSpace(this, space, _matrixClient));
      didChange = true;
    }

    if (didChange) {
      for (var space in spaces) {
        (space as MatrixSpace).updateRoomsList();
      }
    }
  }

  @override
  Future<Room> createRoom(CreateRoomArgs args) async {
    var creationContent = null;

    if (Experiments.photoAlbumRooms) {
      if (args.roomType == RoomType.photoAlbum) {
        creationContent = {"type": "chat.commet.photo_album"};
      }
    }

    if (Experiments.elementCall) {
      if (args.roomType == RoomType.voipRoom) {
        creationContent = {"type": "org.matrix.msc3417.call"};
      }
    }

    var id = await _matrixClient.createRoom(
        creationContent: creationContent,
        name: args.name,
        visibility: args.visibility == RoomVisibility.private
            ? matrix.Visibility.private
            : matrix.Visibility.public);
    var matrixRoom = _matrixClient.getRoomById(id)!;
    if (args.enableE2EE) {
      await matrixRoom.enableEncryption();
    }

    if (hasRoom(id)) return getRoom(id)!;
    var room = MatrixRoom(this, matrixRoom, _matrixClient);
    rooms.add(room);
    return room;
  }

  @override
  Future<Space> createSpace(CreateRoomArgs args) async {
    var id = await _matrixClient.createSpace(
        name: args.name,
        waitForSync: true,
        visibility: args.visibility == RoomVisibility.private
            ? matrix.Visibility.private
            : matrix.Visibility.public);

    if (hasSpace(id)) return getSpace(id)!;
    var space =
        MatrixSpace(this, _matrixClient.getRoomById(id)!, _matrixClient);
    spaces.add(space);
    return space;
  }

  @override
  Future<Space> joinSpace(String address) async {
    var id = await _matrixClient.joinRoom(address);
    await _matrixClient.waitForRoomInSync(id);
    if (hasSpace(id)) return getSpace(id)!;

    var space =
        MatrixSpace(this, _matrixClient.getRoomById(id)!, _matrixClient);
    spaces.add(space);
    return space;
  }

  @override
  Future<Room> joinRoom(String address) async {
    var id = await _matrixClient.joinRoom(address);
    await _matrixClient.waitForRoomInSync(id);
    if (hasRoom(id)) return getRoom(id)!;

    var room = MatrixRoom(this, _matrixClient.getRoomById(id)!, _matrixClient);
    rooms.add(room);
    return room;
  }

  @override
  Future<void> close() async {
    await _matrixClient.dispose();
  }

  @override
  Future<void> setAvatar(Uint8List bytes, String mimeType) async {
    await _matrixClient.setAvatar(matrix.MatrixImageFile(
        bytes: bytes, name: "avatar", mimeType: mimeType));
    // TODO: Handle refresh avatar
    // await (self as MatrixPeer).refreshAvatar();
  }

  @override
  Future<void> setDisplayName(String name) async {
    await _matrixClient.setDisplayName(_matrixClient.userID!, name);
    // TODO: Handle display name update
    // self!.displayName = name;
  }

  @override
  Iterable<Room> getEligibleRoomsForSpace(Space space) {
    return rooms.where((room) => !space.containsRoom(room.identifier));
  }

  @override
  Widget buildDebugInfo() {
    var data = _matrixClient.accountData.copy();

    return SelectionArea(
      child: Codeblock(
        language: "json",
        text: const JsonEncoder.withIndent('  ').convert(data),
      ),
    );
  }

  @override
  Future<Profile?> getProfile(String identifier) async {
    var profile = await _matrixClient.getProfileFromUserId(identifier);
    return MatrixProfile(_matrixClient, profile);
  }

  @override
  Room? getRoom(String identifier) {
    return _rooms.tryFirstWhere((element) => element.identifier == identifier);
  }

  @override
  Space? getSpace(String identifier) {
    return _spaces.tryFirstWhere((element) => element.identifier == identifier);
  }

  @override
  bool hasPeer(String identifier) {
    return _peersMap.containsKey(identifier);
  }

  @override
  bool hasRoom(String identifier) {
    return _rooms.any((element) => element.identifier == identifier);
  }

  @override
  bool hasSpace(String identifier) {
    return _spaces.any((element) => element.identifier == identifier);
  }

  @override
  Future<RoomPreview?> getRoomPreview(String address) async {
    try {
      return await _matrixClient.getRoomPreview(address);
    } catch (exception) {
      return null;
    }
  }

  @override
  Future<RoomPreview?> getSpacePreview(String address) async {
    try {
      return await _matrixClient.getRoomPreview(address);
    } catch (exception) {
      return null;
    }
  }

  @override
  T? getComponent<T extends Component>() {
    for (var component in componentsInternal) {
      if (component is T) return component as T;
    }

    return null;
  }

  @override
  List<T>? getAllComponents<T extends Component<Client>>() {
    List<T> components = List.empty(growable: true);
    for (var component in componentsInternal) {
      if (component is T) {
        components.add(component as T);
      }
    }

    return components;
  }

  @override
  Future<void> leaveRoom(Room room) async {
    _rooms.remove(room);
    await room.close();
    return _matrixClient.leaveRoom(room.identifier);
  }

  @override
  Future<void> leaveSpace(Space space) async {
    _spaces.remove(space);
    space.close();
    return _matrixClient.leaveRoom(space.identifier);
  }

  void onSyncStatusChanged(matrix.SyncStatusUpdate event) {
    ClientConnectionStatus value = ClientConnectionStatus.unknown;

    var connected = _matrixClient.onSync.value != null &&
        event.status != matrix.SyncStatus.error &&
        _matrixClient.prevBatch != null;

    if (connected) {
      value = ClientConnectionStatus.connected;
    } else {
      value = switch (event.status) {
        matrix.SyncStatus.waitingForResponse =>
          ClientConnectionStatus.connecting,
        matrix.SyncStatus.processing => ClientConnectionStatus.connecting,
        matrix.SyncStatus.cleaningUp => ClientConnectionStatus.connecting,
        matrix.SyncStatus.finished => ClientConnectionStatus.connected,
        matrix.SyncStatus.error => ClientConnectionStatus.disconnected,
      };
    }

    var result = ClientConnectionStatusUpdate(value);
    result.progress = event.progress;

    connectionStatusChanged.add(result);
  }

  @override
  Future<
      (
        bool,
        List<LoginFlow>?,
      )> setHomeserver(Uri uri) async {
    try {
      var result = await _matrixClient.checkHomeserver(uri);

      var flows = result.$3;

      var resultFlows = List<LoginFlow>.empty(growable: true);

      if (flows.any((element) => element.type == "m.login.password")) {
        resultFlows.add(MatrixPasswordLoginFlow());
      }

      if (flows.any((element) => element.type == "m.login.sso")) {
        resultFlows.addAll(await _getSsoFlows());
      }

      return (
        true,
        resultFlows,
      );
    } catch (error, trace) {
      Log.onError(error, trace);
      return (false, null);
    }
  }

  Future<List<LoginFlow>> _getSsoFlows() async {
    List<LoginFlow> result = List.empty(growable: true);

    Map<String, dynamic> flows =
        await _matrixClient.request(matrix.RequestType.GET, "/client/v3/login");

    flows["flows"].where((element) => element['type'] == "m.login.sso").forEach(
      (element) {
        element["identity_providers"]?.forEach((provider) {
          result.add(MatrixSSOLoginFlow.fromJson(this, provider));
        });
      },
    );

    if (result.isEmpty) {
      result.add(MatrixSSOLoginFlow(name: "homeserver", id: null));
    }

    return result;
  }

  @override
  Future<LoginResult> executeLoginFlow(LoginFlow flow) async {
    var result = await flow.submit(this);

    if (result == LoginResult.success) {
      preferences.addRegisteredMatrixClient(identifier);
      await _postLoginSuccess();
    }

    return result;
  }
}
