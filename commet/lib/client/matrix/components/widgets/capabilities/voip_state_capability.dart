import 'dart:async';
import 'dart:convert';

import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/debounce.dart';

class MatrixCapabilityVoipState implements MatrixWidgetCapability {
  @override
  MatrixWidgetRunner runner;

  MatrixCapabilityVoipState({required this.runner}) {
    for (var session in clientManager!.callManager.currentSessions) {
      onSessionStarted(session);
    }

    clientManager!.callManager.currentSessions.onAdd.listen(onSessionStarted);
  }

  List<StreamSubscription> subs = List.empty(growable: true);

  static String name = "chat.commet.voip_overlay.voip_state";

  static MatrixWidgetCapabilityConstructorEntry entry = MapEntry(
      name, (runner, type, key) => MatrixCapabilityVoipState(runner: runner));

  @override
  String toString() {
    return "Voip State";
  }

  @override
  bool canHandleRequest(MatrixWidgetMessage message) {
    return false;
  }

  @override
  Future<MatrixWidgetMessage> handleRequest(MatrixWidgetMessage message) async {
    return message.createResponseError(message: "Unimplemented");
  }

  @override
  void dispose() {}

  void onSessionStarted(VoipSession session) {
    subs.addAll([
      session.onStateChanged.listen((_) => onSessionStateChanged(session)),
      session.onUpdateVolumeVisualizers
          .listen((_) => onSessionStateChanged(session))
    ]);

    sendCurrentState();
  }

  Debouncer debouncer = Debouncer(delay: Duration(milliseconds: 20));

  void onSessionStateChanged(VoipSession session) {
    debouncer.run(sendCurrentState);
  }

  String? lastState;

  void sendCurrentState() {
    var state = {};

    for (var session in clientManager!.callManager.currentSessions) {
      var room = session.client.getRoom(session.roomId)!;

      for (var stream in session.streams) {
        if (stream.type == VoipStreamType.audio) {
          var user = room.getMemberOrFallback(stream.streamUserId);

          state[stream.streamUserId] = {
            "display_name": user.displayName,
            if (user.avatarId != null) "avatar_url": user.avatarId,
            "muted": stream.isMuted,
            "talking": stream.audiolevel > 0.5,
          };
        }
      }
    }

    var str = jsonEncode(state);

    if (str != lastState) {
      Log.i(
        "Current voip state: ${state}",
      );

      runner.messageTransport.send(runner.eventHandler.generateToWidgetEvent(
          action: "chat.commet.voip_overlay.voip_state",
          data: {
            "state": state,
          }));

      lastState = str;
    } else {
      Log.i("State did not change");
    }
  }
}
