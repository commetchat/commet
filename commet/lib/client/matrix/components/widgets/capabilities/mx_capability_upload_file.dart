import 'dart:typed_data';

import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/debug/log.dart';
import 'package:matrix/matrix_api_lite/utils/try_get_map_extension.dart';

class MatrixCapabilityUploadFile implements MatrixWidgetCapability {
  @override
  MatrixWidgetRunner runner;

  MatrixCapabilityUploadFile(this.runner);

  @override
  String toString() {
    return "Upload File";
  }

  static const String name = "org.matrix.msc4039.upload_file";

  static MatrixWidgetCapabilityConstructorEntry entry =
      MapEntry(name, (runner, type, key) => MatrixCapabilityUploadFile(runner));

  @override
  Future<MatrixWidgetMessage> handleRequest(MatrixWidgetMessage message) async {
    Log.d("Handling upload file!");
    var file = message.data.tryGet<Uint8List>("file");

    if (file != null) {
      Log.d("Uploading file for widget");
      var result = await runner.client.matrixClient.uploadContent(file);

      Log.d("Upload finished!");

      return message.createResponseObject(
          data: {}, response: {"content_uri": result.toString()});
    } else {
      return message.createResponseError(message: "Invalid message");
    }
  }

  @override
  bool canHandleRequest(MatrixWidgetMessage message) {
    return message.action == "org.matrix.msc4039.upload_file";
  }
  
  @override
  void dispose() {
  }
}
