import 'dart:io';

import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_transport.dart';
import 'package:commet/client/matrix/extensions/matrix_client_extensions.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/matrix_api_lite/utils/try_get_map_extension.dart';

class MatrixCapabilityDownloadFile implements MatrixWidgetCapability {
  @override
  MatrixWidgetRunner runner;

  MatrixCapabilityDownloadFile(this.runner);

  @override
  String toString() {
    return "Download File";
  }

  static const String name = "org.matrix.msc4039.download_file";

  static MatrixWidgetCapabilityConstructorEntry entry = MapEntry(
      name, (runner, type, key) => MatrixCapabilityDownloadFile(runner));

  @override
  Future<MatrixWidgetMessage> handleRequest(MatrixWidgetMessage message) async {
    Log.i("Handling download file: ${message.data}");

    var url = message.data.tryGet<String>("content_uri");
    if (url == null) {
      return message.createResponseError(message: "Invalid request");
    }

    var uri = Uri.parse(url);
    if (uri.scheme != "mxc") {
      return message.createResponseError(message: "Invalid request");
    }

    Uint8List? bytes;

    if (!kIsWeb) {
      var cached = await fileCache?.getFile(uri.toString());

      if (cached != null) {
        bytes = await File.fromUri(cached).readAsBytes();
      }
    }

    if (bytes == null) {
      var response = await runner.client.matrixClient.getContentFromUri(uri);
      bytes = response.data;
    }

    return message
        .createResponseObject(response: {"file": MatrixWidgetBlob(bytes)});
  }

  @override
  bool canHandleRequest(MatrixWidgetMessage message) {
    return message.action == "org.matrix.msc4039.download_file";
  }

  @override
  void dispose() {}
}
