import 'package:matrix_widget_api/matrix_widget_api.dart';

class MatrixWidgetApiWeb implements MatrixWidgetApi {
  @override
  String userId;

  MatrixWidgetApiWeb(
    String widgetId, {
    required this.userId,
    String supportedOrigins = "*",
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> requestCapabilities(List<String> capabilities) async {}

  void on(
    String event,
    Map<String, dynamic>? Function(Map<String, dynamic> data) callback, {
    preventDefaultHandler = false,
  }) {
    throw UnimplementedError();
  }

  @override
  void onAction(
    String toWidgetAction,
    Map<String, dynamic>? Function(Map<String, dynamic> data) callback, {
    preventDefaultHandler = false,
  }) {
    throw UnimplementedError();
  }

  @override
  void start() {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> sendAction(
    String fromWidgetAction,
    Map<String, dynamic> data,
  ) async {
    throw UnimplementedError();
  }

  @override
  void stop() {
    throw UnimplementedError();
  }
}
