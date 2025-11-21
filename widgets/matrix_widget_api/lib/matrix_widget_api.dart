export 'matrix_widget_api_stub.dart'
    if (dart.library.html) 'matrix_widget_api_web.dart';

abstract class MatrixWidgetApi {
  String get userId;

  Future<void> requestCapabilities(List<String> capabilities);

  void start();

  void stop();

  Stream<void> get onReady;

  Future<Map<String, dynamic>> sendAction(
    String fromWidgetAction,
    Map<String, dynamic> data,
  );

  void onAction(
    String toWidgetAction,
    Map<String, dynamic>? Function(Map<String, dynamic> data) callback, {
    preventDefaultHandler = false,
  });
}
