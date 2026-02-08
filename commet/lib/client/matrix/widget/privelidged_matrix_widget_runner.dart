import 'dart:async';
import 'dart:convert';

import 'package:commet/debug/log.dart';
import 'package:matrix_widget_api/capabilities.dart';
import 'package:matrix_widget_api/matrix_widget_api.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:matrix_widget_api/types.dart';

/// This widget runner is only partially implemented, based on the needs of commet as it develops
/// currently it does *not* check any permissions, and should not be used for user-configured widgets
/// commet doesn't support these anyway, so its fine, but when we do start to support that, this should be rewritten
class PrivelidgedMatrixWidgetRunner implements MatrixWidgetApi {
  matrix.Client client;
  matrix.Room room;

  bool running = false;

  PrivelidgedMatrixWidgetRunner(this.client, this.room);

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

  void sendExistingStateEvents(String stateType) async {
    await room.postLoad();

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

    if (fromWidgetAction == FromWidgetAction.readRelations) {
      return handleReadRelations(data);
    }

    throw UnimplementedError();
  }

  @override
  void start() {
    if (running) {
      return;
    }

    Log.i("Starting Widget Runner: ${room.id}");
    syncStreamSub = client.onSync.stream.listen(onSync);
    client.onTimelineEvent.stream
        .where((event) => event.roomId == room.id)
        .listen(onEvent);
    running = true;
    _onReady.add(());
  }

  @override
  void stop() {
    Log.i("Stopping Widget Runner: ${room.id}");
    syncStreamSub?.cancel();
    actionListeners.clear();
    running = false;
  }

  @override
  String get userId => client.userID!;

  Future<Map<String, dynamic>> handleSendEvent(
    Map<String, dynamic> data,
  ) async {
    Log.i("Handling send event");
    var type = data["type"];

    var state_key = data["state_key"];
    var content = jsonDecode(jsonEncode(data["content"]));

    String? eventId;
    Log.i(data);
    if (state_key != null) {
      eventId = await client.setRoomStateWithKey(
        room.id,
        type,
        state_key,
        content,
      );

      Log.i("Sent event $eventId");

      var stateResult = {
        "data": {
          "state": [
            {
              "type": type,
              "content": content,
              "sender": client.userID!,
              "state_key": state_key,
              "event_id": eventId,
            }
          ]
        },
      };

      if (grantedCapabilities.contains(MatrixCapability.getRoomState(type))) {
        Function(Map<String, dynamic>)? callback =
            actionListeners[ToWidgetAction.updateState];

        try {
          callback?.call(stateResult);
        } catch (e) {}
      }
    } else {
      print("Sending event: $data");

      if (type == "m.room.redaction") {
        eventId = await room.redactEvent(content["redacts"]);
      } else {
        eventId = await room.sendEvent(content,
            type: type, txid: "fake_" + client.generateUniqueTransactionId());
        print(eventId);
      }

      var eventResult = {
        "data": {
          "type": type,
          "content": content,
          "sender": client.userID!,
          "state_key": state_key,
          "event_id": eventId,
        },
      };

      if (grantedCapabilities.contains(MatrixCapability.receiveEvent(type))) {
        Function(Map<String, dynamic>)? callback =
            actionListeners[ToWidgetAction.sendEvent];

        try {
          callback?.call(eventResult);
        } catch (e) {}
      }
    }

    Log.i("Handled send event");

    return {"room_id": room.id, "event_id": eventId};
  }

  void onSync(matrix.SyncUpdate event) {
    var thisRoom = event.rooms?.join?[room.id];
    if (thisRoom == null) {
      return;
    }

    var events = thisRoom.timeline?.events;
    if (events == null) {
      return;
    }

    var readableStateEvents = events
        .where((i) => i.stateKey != null && canWidgetReadStateEventType(i.type))
        .toList();

    var readableEvents = events
        .where((i) =>
            !i.eventId.startsWith("fake_") && canWidgetReceiveEventType(i.type))
        .toList();

    if (readableStateEvents.isNotEmpty) {
      Log.i("[${room.id}] Sending ${readableStateEvents.length} events");

      var currentStates = readableStateEvents
          .map((i) => room.getState(i.type, i.stateKey ?? ""))
          .nonNulls
          .toList();

      var result = {
        "data": {"state": currentStates.map((i) => i.toJson()).toList()},
      };

      Function(Map<String, dynamic>)? callback =
          actionListeners["update_state"];

      callback?.call(result);
    }

    if (readableEvents.isNotEmpty) {
      Log.i("Sending readable events: ${readableEvents}");

      for (var event in readableEvents) {
        var eventResult = {
          "data": {
            "type": event.type,
            "content": event.content,
            "sender": event.senderId,
            "event_id": event.eventId,
          },
        };

        Function(Map<String, dynamic>)? callback =
            actionListeners[ToWidgetAction.sendEvent];

        try {
          callback?.call(eventResult);
        } catch (e) {}
      }
    }
  }

  void onEvent(matrix.Event event) {
    if (event.status != matrix.EventStatus.synced) return;

    var eventResult = {
      "data": {
        "type": event.type,
        "content": event.content,
        "sender": event.senderId,
        "event_id": event.eventId,
      },
    };

    if (grantedCapabilities
        .contains(MatrixCapability.receiveEvent(event.type))) {
      Function(Map<String, dynamic>)? callback =
          actionListeners[ToWidgetAction.sendEvent];

      try {
        callback?.call(eventResult);
      } catch (e) {}
    }
  }

  bool canWidgetReadStateEventType(String type) {
    return grantedCapabilities.contains(MatrixCapability.getRoomState(type));
  }

  bool canWidgetReceiveEventType(String type) {
    return grantedCapabilities.contains(MatrixCapability.receiveEvent(type));
  }

  StreamController _onReady = StreamController.broadcast();

  @override
  Stream<void> get onReady => _onReady.stream;

  Future<Map<String, dynamic>> handleReadRelations(
      Map<String, dynamic> data) async {
    Log.i("Handling read relations");
    print(data);

    var eventId = data["event_id"];
    var eventType = data["event_type"];
    var limit = data["limit"];
    var relType = data["rel_type"];
    var from = data["from"];

    List<matrix.MatrixEvent>? chunk;
    String? nextBatch;

    if (room.encrypted) {
      var related = await client.getRelatingEventsWithRelType(
          room.id, eventId, relType,
          from: from, limit: limit);
      nextBatch = related.nextBatch;

      var decrypted = await Future.wait<matrix.Event?>(
          [for (var event in related.chunk) tryDecryptEvent(event)]);

      print(decrypted);

      if (eventType != null) decrypted.removeWhere((i) => i?.type != eventType);

      return {
        "chunk": decrypted.nonNulls.map((i) => i.toJson()).toList(),
        if (nextBatch != null) "next_batch": nextBatch
      };
    }

    if (relType != null && eventType != null) {
      var relatedEvents = await client.getRelatingEventsWithRelTypeAndEventType(
          room.id, eventId, relType, eventType,
          from: from, limit: limit);

      chunk = relatedEvents.chunk;
      nextBatch = relatedEvents.nextBatch;
    } else {
      throw UnimplementedError();
    }

    return {
      "chunk": chunk.map((i) => i.toJson()).toList(),
      if (nextBatch != null) "next_batch": nextBatch
    };
  }

  Future<matrix.Event?> tryDecryptEvent(matrix.MatrixEvent event) async {
    try {
      return client.encryption!
          .decryptRoomEvent(matrix.Event.fromMatrixEvent(event, room));
    } catch (e, _) {
      return null;
    }
  }
}
