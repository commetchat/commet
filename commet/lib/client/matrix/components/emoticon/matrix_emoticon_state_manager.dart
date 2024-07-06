import 'dart:async';

import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:matrix/matrix.dart' as matrix;

abstract class MatrixEmoticonStateManager {
  Map<String, dynamic> getState(String packKey);

  Map<String, dynamic> getAllStates();

  Future<void> setState(String packKey, Map<String, dynamic> content);

  Stream<void> get onStateChanged;
}

class MatrixEmoticonPersonalStateManager implements MatrixEmoticonStateManager {
  MatrixClient client;

  StreamController<void> onStateChangedController =
      StreamController.broadcast();

  MatrixEmoticonPersonalStateManager(this.client) {
    var mx = client.getMatrixClient();

    mx.onLoginStateChanged.stream
        .where((event) => event == matrix.LoginState.loggedIn)
        .listen((event) async {
      if (mx.accountDataLoading != null) {
        await mx.accountDataLoading;
      }

      onStateChangedController.add(null);
    });

    mx.onAccountData.stream.listen((event) {
      onStateChangedController.add(null);
    });
  }

  @override
  Stream<void> get onStateChanged => onStateChangedController.stream;

  @override
  Map<String, dynamic> getAllStates() {
    var state = getState("personal");
    if (state.isEmpty) return {};
    return {"personal": state};
  }

  @override
  Future<void> setState(String packKey, Map<String, dynamic> content) {
    return client.getMatrixClient().setAccountData(
        client.getMatrixClient().userID!, "im.ponies.user_emotes", content);
  }

  @override
  Map<String, dynamic> getState(String packKey) {
    return client
            .getMatrixClient()
            .accountData['im.ponies.user_emotes']
            ?.content ??
        {};
  }
}

class MatrixEmoticonRoomStateManager implements MatrixEmoticonStateManager {
  matrix.Room room;

  StreamController<void> onStateChangedController =
      StreamController.broadcast();

  MatrixEmoticonRoomStateManager(this.room) {
    var mx = room.client;

    mx.onRoomState.stream
        .where((event) =>
            event.roomId == room.id &&
            event.type == MatrixEmoticonComponent.roomEmotesStateKey)
        .listen((event) {
      onStateChangedController.add(null);
    });

    onStateChangedController.add(null);
  }

  @override
  Map<String, dynamic> getAllStates() {
    if (!room.states.containsKey(MatrixEmoticonComponent.roomEmotesStateKey))
      return {};

    var state = (room.states[MatrixEmoticonComponent.roomEmotesStateKey]
        as Map<String, matrix.Event>);

    var result = <String, dynamic>{};

    for (var key in state.keys) {
      result[key] = state[key]!.content;
    }

    return result;
  }

  @override
  Map<String, dynamic> getState(String packKey) {
    var states = getAllStates();
    var data = states[packKey];
    return data;
  }

  @override
  Future<void> setState(String packKey, Map<String, dynamic> content) async {
    var event = await room.client.setRoomStateWithKey(
        room.id, MatrixEmoticonComponent.roomEmotesStateKey, packKey, content);

    var result = await room.getEventById(event);
    room.states[MatrixEmoticonComponent.roomEmotesStateKey]![packKey] = result!;
  }

  @override
  Stream<void> get onStateChanged => onStateChangedController.stream;
}
