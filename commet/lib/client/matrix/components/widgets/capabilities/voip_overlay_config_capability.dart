import 'dart:async';

import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/debounce.dart';

class MatrixCapabilityVoipOverlayConfiguration
    implements MatrixWidgetCapability {
  @override
  MatrixWidgetRunner runner;

  MatrixCapabilityVoipOverlayConfiguration({required this.runner}) {
    subs = [
      preferences.voipOverlayXOffset.onChanged.listen(
        (_) => onConfigurationChanged(),
      ),
      preferences.voipOverlayYOffset.onChanged.listen(
        (_) => onConfigurationChanged(),
      ),
    ];

    onConfigurationChanged();
  }

  List<StreamSubscription> subs = List.empty(growable: true);

  static String name = "chat.commet.voip_overlay.changed_configuration";

  static MatrixWidgetCapabilityConstructorEntry entry = MapEntry(
    name,
    (runner, type, key) =>
        MatrixCapabilityVoipOverlayConfiguration(runner: runner),
  );

  @override
  String toString() {
    return "Voip Overlay Changed Configuration";
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

  Debouncer debouncer = Debouncer(delay: Duration(milliseconds: 20));

  String? lastState;

  void onConfigurationChanged() {
    runner.messageTransport.send(
      runner.eventHandler.generateToWidgetEvent(
        action: name,
        data: {
          "offset_x": preferences.voipOverlayXOffset.value,
          "offset_y": preferences.voipOverlayYOffset.value,
        },
      ),
    );
  }
}
