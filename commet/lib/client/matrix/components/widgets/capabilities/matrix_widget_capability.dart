import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';

abstract class MatrixWidgetCapability {
  MatrixWidgetRunner get runner;

  void handleRequest(MatrixWidgetMessage message);

  bool canHandleRequest(MatrixWidgetMessage message);
}
