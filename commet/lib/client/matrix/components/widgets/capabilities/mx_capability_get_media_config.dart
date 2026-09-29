import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_download_file.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_upload_file.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/client/matrix/matrix_client.dart';

class MatrixCapabilityGetMediaConfig implements MatrixWidgetCapability {
  @override
  MatrixWidgetRunner runner;

  MatrixCapabilityGetMediaConfig(this.runner);

  @override
  String toString() {
    return "Download File";
  }

  static const String name = "org.matrix.msc4039.get_media_config";

  static MatrixWidgetCapabilityConstructorEntry entry = MapEntry(
      name, (runner, type, key) => MatrixCapabilityGetMediaConfig(runner));

  @override
  Future<MatrixWidgetMessage> handleRequest(MatrixWidgetMessage message) async {
    var config = (runner.room!.client as MatrixClient).config;

    if (config == null) {
      config = await runner.room!.matrixRoom.client.getConfig();
    }

    return message.createResponseObject(response: config.toJson());
  }

  @override
  bool canHandleRequest(MatrixWidgetMessage message) {
    if (!capabilities.grantedCapabilities
        .containsKey(MatrixCapabilityDownloadFile.name)) return false;

    if (!capabilities.grantedCapabilities
        .containsKey(MatrixCapabilityUploadFile.name)) return false;

    return message.action == name;
  }

  @override
  void dispose() {}
}
