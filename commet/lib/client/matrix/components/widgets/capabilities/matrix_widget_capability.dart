import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';

abstract class MatrixWidgetCapability {
  MatrixWidgetRunner get runner;

  Future<MatrixWidgetMessage> handleRequest(MatrixWidgetMessage message);

  bool canHandleRequest(MatrixWidgetMessage message);
}

extension MatrixWidgetCapabilitiesExtension on MatrixWidgetCapability {
  MatrixWidgetCapabilitiesManager get capabilities =>
      runner.capabilities as MatrixWidgetCapabilitiesManager;
}
