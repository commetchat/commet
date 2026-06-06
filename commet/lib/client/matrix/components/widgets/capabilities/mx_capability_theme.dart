import 'dart:async';

import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/utils/color_utils.dart';
import 'package:flutter/src/material/theme_data.dart';
import 'package:tiamat/config/style/theme_changer.dart';

class MatrixCapabilityTheme implements MatrixWidgetCapability {
  @override
  MatrixWidgetRunner runner;

  late StreamSubscription sub;
  MatrixCapabilityTheme({required this.runner}) {
    sub = ThemeChanger.onThemeChanged.stream.listen(onThemeChanged);
  }

  static const String name = "org.matrix.msc2873.client_theme";

  static MatrixWidgetCapabilityConstructorEntry entry = MapEntry(
      name, (runner, type, key) => MatrixCapabilityTheme(runner: runner));

  static String getNameForType(String eventType, String? key) =>
      key == null ? "$name:$eventType" : "$name:$eventType#$key";

  @override
  String toString() {
    return "Theme Change";
  }

  @override
  bool canHandleRequest(MatrixWidgetMessage message) {
    return false;
  }

  @override
  void dispose() {
    sub.cancel();
  }

  @override
  Future<MatrixWidgetMessage> handleRequest(MatrixWidgetMessage message) {
    throw UnimplementedError();
  }

  void onThemeChanged(ThemeData event) {
    runner.messageTransport.send(runner.eventHandler
        .generateToWidgetEvent(action: "theme_change", data: {
      "name": event.brightness == Brightness.light ? "light" : "dark",
      "chat.commet.color_scheme": event.colorScheme.toJson(),
    }));
  }
}
