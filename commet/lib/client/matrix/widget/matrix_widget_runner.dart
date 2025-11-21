import 'dart:async';

import 'package:commet/debug/log.dart';
import 'package:matrix_widget_api/capabilities.dart';
import 'package:matrix_widget_api/matrix_widget_api.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:matrix_widget_api/types.dart';

/// This widget runner is only partially implemented, based on the needs of commet as it develops
/// currently it does *not* check any permissions, and should not be used for user-configured widgets
/// commet doesn't support these anyway, so its fine, but when we do start to support that, this should be rewritten
class MatrixWidgetRunner implements MatrixWidgetApi {
  matrix.Client client;
  matrix.Room room;

  bool started = false;

  MatrixWidgetRunner(this.client, this.room);

  List<String> grantedCapabilities = List.empty(growable: true);

  Map<String, Function(Map<String, dynamic> data)> actionListeners = {};

  StreamSubscription? syncStreamSub;

  @override
  void onAction(
    String toWidgetAction,
    Map<String, dynamic>? Function(Map<String, dynamic> data) callback, {
    preventDefaultHandler = false,
  }) {
    actionListeners[toWidgetAction] = callback;
  }

  @override
  Future<void> requestCapabilities(List<String> capabilities) async {
    Log.i("Widget requested capabilities: ${capabilities}");

    for (var capability in capabilities) {
      if (grantedCapabilities.contains(capability)) {
        continue;
      }

      grantedCapabilities.add(capability);
      onCapabilityGranted(capability);
    }
  }

  void onCapabilityGranted(String capability) {
    Log.i("Granted capability: $capability");

    if (capability.startsWith("org.matrix.msc2762.receive.state_event:")) {
      var state = capability.replaceFirst(
        "org.matrix.msc2762.receive.state_event:",
        "",
      );
      Log.i("Sending state events: $state");
      sendExistingStateEvents(state);
    }
  }

  void sendExistingStateEvents(String stateType) {
    var states = room.states[stateType];
    Log.i("Found states: $stateType  = $states");
    if (states == null) {
      return;
    }

    var result = {
      "data": {"state": states.values.map((i) => i.toJson())},
    };

    Function(Map<String, dynamic>)? callback = actionListeners["update_state"];

    callback?.call(result);
  }

  @override
  Future<Map<String, dynamic>> sendAction(
    String fromWidgetAction,
    Map<String, dynamic> data,
  ) async {
    Log.i("[${room.id}] Action requested: $fromWidgetAction");

    if (fromWidgetAction == FromWidgetAction.sendEvent) {
      return handleSendEvent(data);
    }

    throw UnimplementedError();
  }

  @override
  void start() {
    if (started) {
      return;
    }

    Log.i("Starting Widget Runner: ${room.id}");
    syncStreamSub = client.onSync.stream.listen(onSync);
    started = true;
    _onReady.add(());
  }

  @override
  void stop() {
    syncStreamSub?.cancel();
    actionListeners.clear();
  }

  @override
  String get userId => client.userID!;

  Future<Map<String, dynamic>> handleSendEvent(
    Map<String, dynamic> data,
  ) async {
    var type = data["type"];
    var state_key = data["state_key"];
    var content = data["content"];

    await client.setRoomStateWithKey(room.id, type, state_key, content);
    return {};
  }

  void onSync(matrix.SyncUpdate event) {
    var thisRoom = event.rooms?.join?[room.id];
    if (thisRoom == null) {
      return;
    }
    Log.i("[${room.id}] Received Sync");

    var events = thisRoom.timeline?.events;
    if (events == null) {
      return;
    }

    var readableEvents = events
        .where((i) => i.stateKey != null && canWidgetReadStateEventType(i.type))
        .toList();

    if (readableEvents.isEmpty) {
      Log.i("[${room.id}] No events to send");
      return;
    }

    Log.i("[${room.id}] Sending ${readableEvents.length} events");

    var result = {
      "data": {"state": readableEvents.map((i) => i.toJson())},
    };

    Function(Map<String, dynamic>)? callback = actionListeners["update_state"];
    callback?.call(result);
  }

  bool canWidgetReadStateEventType(String type) {
    return grantedCapabilities.contains(MatrixCapability.getRoomState(type));
  }

  StreamController _onReady = StreamController.broadcast();

  @override
  Stream<void> get onReady => _onReady.stream;
}
