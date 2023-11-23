import 'dart:async';
import 'package:commet/client/alert.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/component_registry.dart';
import 'package:commet/client/invitation.dart';
import 'package:commet/client/matrix/extensions/matrix_client_extensions.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/config/app_config.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/pages/matrix/authentication/matrix_uia_request.dart';
import 'package:commet/utils/list_extension.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:flutter/foundation.dart';

import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:matrix/encryption.dart';

import '../../ui/atoms/code_block.dart';
import '../../ui/pages/matrix/verification/matrix_verification_page.dart';
import 'matrix_room.dart';
import 'matrix_space.dart';
import 'package:olm/olm.dart' as olm;

class MatrixClient extends Client {
  late matrix.Client _matrixClient;
  late final List<Component<MatrixClient>> _components;

  Future? firstSync;

  matrix.ServerConfig? config;

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
      : matrix.NativeImplementationsIsolate(compute);

  MatrixClient({required String identifier}) {
    _id = identifier;
    _matrixClient = _createMatrixClient(identifier);
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

  final Map<String, Invitation> _invitations = {};
  @override
  List<Invitation> get invitations => _invitations.values.toList();

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

  static String get matrixClientOlmMissingMessage => Intl.message(
        "libolm is not installed or was not found. End to End Encryption will not be available until this is resolved",
        name: "matrixClientOlmMissingMessage",
        desc:
            "Text that explains to the user that libolm dependency is not found",
      );

  static String get matrixClientEncryptionWarningTitle => Intl.message(
        "Encryption Warning",
        name: "matrixClientEncryptionWarningTitle",
        desc: "Title of a warning about encryption",
      );

  static Future<void> loadFromDB(ClientManager manager) async {
    await diagnostics.timeAsync("loadFromDB", () async {
      var clients = preferences.getRegisteredMatrixClients();

      List<Future> futures = List.empty(growable: true);

      futures.add(_checkSystem(manager));

      if (clients != null) {
        for (var clientName in clients) {
          var client = MatrixClient(identifier: clientName);
          try {
            manager.addClient(client);
            futures.add(diagnostics.timeAsync("Initializing client $clientName",
                () async {
              await client.init(true);
            }));
          } catch (_) {
            manager.removeClient(client);
            preferences.removeRegisteredMatrixClient(clientName);
          }
        }
      }

      await Future.wait(futures);
    });
  }

  static Future<void> _checkSystem(ClientManager clientManager) async {
    try {
      await olm.init();
      olm.get_library_version();
    } catch (exception) {
      clientManager.alertManager.addAlert(Alert(
        AlertType.warning,
        titleGetter: () => matrixClientEncryptionWarningTitle,
        messageGetter: () => matrixClientOlmMissingMessage,
      ));
    }
  }

  static matrix.NativeImplementations get nativeImplementations =>
      BuildConfig.WEB
          ? const matrix.NativeImplementationsDummy()
          : matrix.NativeImplementationsIsolate(compute);
  @override
  Future<void> init(bool loadingFromCache) async {
    if (!_matrixClient.isLogged()) {
      await diagnostics.timeAsync("Matrix client init", () async {
        await _matrixClient.init(
            waitForFirstSync: !loadingFromCache,
            waitUntilLoadCompletedLoaded: true);
      });
      self = MatrixPeer(this, _matrixClient, _matrixClient.userID!);
      peers.add(self!);

      firstSync = _matrixClient.oneShotSync();
    }

    _matrixClient.getConfig().then((value) {
      config = value;
    });

    _matrixClient.onSync.stream.listen(onMatrixClientSync);

    _updateRoomslist();
    _updateSpacesList();
    _updateInviteList();

    _components = ComponentRegistry.getMatrixComponents(this);

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
    _onSync.add(null);
    _updateRoomslist();
    _updateSpacesList();
    _updateInviteList();
  }

  @override
  bool isLoggedIn() => _matrixClient.isLogged();

  matrix.Client _createMatrixClient(String name) {
    return matrix.Client(
      name,
      verificationMethods: {
        KeyVerificationMethod.emoji,
        KeyVerificationMethod.numbers
      },
      importantStateEvents: {"im.ponies.room_emotes", "m.room.power_levels"},
      supportedLoginTypes: {matrix.AuthenticationTypes.password},
      nativeImplementations: nativeImplementations,
      logLevel:
          BuildConfig.RELEASE ? matrix.Level.warning : matrix.Level.verbose,
      databaseBuilder: (client) async {
        final db = matrix.HiveCollectionsDatabase(
            client.clientName, await AppConfig.getDatabasePath());
        await db.open();
        return db;
      },
    );
  }

  matrix.Client getMatrixClient() {
    return _matrixClient;
  }

  @override
  Future<LoginResult> login(
      LoginType type, String userIdentifier, String server,
      {String? password, String? token}) async {
    LoginResult loginResult = LoginResult.error;

    String name =
        hash("matrix_client-${DateTime.now().millisecondsSinceEpoch}");

    switch (type) {
      case LoginType.loginPassword:
        var uri = Uri.https(server);
        if (server == "localhost") uri = Uri.http(server);

        _matrixClient = _createMatrixClient(name);

        await _matrixClient.checkHomeserver(uri);

        try {
          var result = await _matrixClient.login(
              matrix.LoginType.mLoginPassword,
              initialDeviceDisplayName: BuildConfig.appName,
              password: password,
              identifier:
                  matrix.AuthenticationUserIdentifier(user: userIdentifier));
          if (result.accessToken.isNotEmpty) {
            loginResult = LoginResult.success;
          } else {
            loginResult = LoginResult.failed;
          }
        } catch (_) {
          loginResult = LoginResult.failed;
        }

        break;
      case LoginType.token:
        break;
    }

    if (loginResult == LoginResult.success) {
      preferences.addRegisteredMatrixClient(name);
      _postLoginSuccess();
    } else {
      _matrixClient.clearArchivesFromCache();
      _matrixClient.clear();
      _matrixClient.database?.close();
      _matrixClient.database?.clear();
    }

    return loginResult;
  }

  @override
  Future<void> logout() {
    preferences.removeRegisteredMatrixClient(_matrixClient.clientName);
    return _matrixClient.logout();
  }

  void _postLoginSuccess() {
    if (_matrixClient.userID != null) {
      self = MatrixPeer(this, _matrixClient, _matrixClient.userID!);
    }
  }

  void _updateInviteList() {
    var allRooms = _matrixClient.rooms.where((element) => !element.isSpace);
    var invitedRooms = allRooms.where((element) => element.membership.isInvite);

    for (var invite in invitedRooms) {
      var state =
          invite.states[matrix.EventTypes.RoomMember]![_matrixClient.userID!]!;
      var sender = state.senderId;

      var inviteId = state.eventId;
      if (_invitations.containsKey(inviteId)) continue;

      var avatar = invite.avatar != null
          ? MatrixMxcImage(invite.avatar!, _matrixClient)
          : null;
      var entry = Invitation(
          senderId: sender,
          invitedToId: invite.id,
          invitationId: state.eventId,
          avatar: avatar,
          color: MatrixPeer.hashColor(sender),
          displayName: invite.getLocalizedDisplayname());

      _invitations[inviteId] = entry;
    }
  }

  void _updateRoomslist() {
    var joinedRooms = _matrixClient.rooms
        .where((element) => !element.isSpace && element.membership.isJoin);

    for (var room in joinedRooms) {
      if (hasRoom(room.id)) continue;
      rooms.add(MatrixRoom(this, room, _matrixClient));
    }
  }

  void _updateSpacesList() {
    var allSpaces = _matrixClient.rooms.where((element) => element.isSpace);

    for (var space in allSpaces) {
      if (hasSpace(space.id)) continue;
      spaces.add(MatrixSpace(this, space, _matrixClient));
    }
  }

  @override
  Future<Room> createRoom(String name, RoomVisibility visibility,
      {bool enableE2EE = true}) async {
    var id = await _matrixClient.createRoom(
        name: name,
        visibility: visibility == RoomVisibility.private
            ? matrix.Visibility.private
            : matrix.Visibility.public);
    var matrixRoom = _matrixClient.getRoomById(id)!;
    if (enableE2EE) {
      await matrixRoom.enableEncryption();
    }

    if (hasRoom(id)) return getRoom(id)!;
    var room = MatrixRoom(this, matrixRoom, _matrixClient);
    rooms.add(room);
    return room;
  }

  @override
  Future<Space> createSpace(String name, RoomVisibility visibility) async {
    var id = await _matrixClient.createSpace(
        name: name,
        waitForSync: true,
        visibility: visibility == RoomVisibility.private
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
    await (self as MatrixPeer).refreshAvatar();
  }

  @override
  Future<void> setDisplayName(String name) async {
    await _matrixClient.setDisplayName(_matrixClient.userID!, name);
    self!.displayName = name;
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
  Future<Room?> createDirectMessage(String userId) async {
    var roomId = await _matrixClient.startDirectChat(userId);
    if (hasRoom(roomId)) return getRoom(roomId);

    var matrixRoom = _matrixClient.getRoomById(roomId);
    if (matrixRoom == null) return null;

    MatrixRoom room = MatrixRoom(this, matrixRoom, _matrixClient);
    rooms.add(room);
    return room;
  }

  @override
  Future<void> acceptInvitation(Invitation invitation) async {
    if (!invitations.contains(invitation)) {
      throw Exception(
          "Tried to accept an invitation that does not belong to this client");
    }

    _invitations.remove(invitation.invitationId);
    await joinRoom(invitation.invitedToId);
    _updateInviteList();
  }

  @override
  Future<void> rejectInvitation(Invitation invitation) async {
    if (!invitations.contains(invitation)) {
      throw Exception(
          "Tried to reject an invitation that does not belong to this client");
    }

    _invitations.remove(invitation.invitationId);
    await _matrixClient.leaveRoom(invitation.invitedToId);
  }

  @override
  List<Room> get directMessages => throw UnimplementedError();

  @override
  Peer getPeer(String identifier) {
    var result = _peersMap[identifier];
    if (result != null) return result;

    var peer = MatrixPeer(this, _matrixClient, identifier);
    _peersMap[identifier] = peer;
    _peers.add(peer);
    return peer;
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
    for (var component in _components) {
      if (component is T) return component as T;
    }

    return null;
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
}
