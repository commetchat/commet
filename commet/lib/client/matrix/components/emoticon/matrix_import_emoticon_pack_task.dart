import 'dart:async';
import 'dart:typed_data';

import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/background_tasks/background_task_manager.dart';

class MatrixImportEmoticonPackTask
    implements BackgroundTaskWithIntegerProgress {
  @override
  late int total;

  @override
  int current = 0;

  @override
  String label = "Uploading stickers";

  @override
  BackgroundTaskStatus status = BackgroundTaskStatus.running;

  StreamController<int> progressStream = StreamController.broadcast();
  StreamController controller = StreamController.broadcast();

  @override
  void Function()? action;

  @override
  bool get canCallAction => false;

  @override
  void dispose() {}

  @override
  Stream<int> get onProgress => progressStream.stream;

  @override
  bool shouldRemoveTask = false;

  @override
  Stream<void> get statusChanged => controller.stream;

  List<Uint8List> images;
  MatrixClient client;

  MatrixImportEmoticonPackTask(this.images, this.client) {
    total = images.length;
  }

  Future<List<Uri?>> uploadImages() async {
    var results = List<Uri?>.generate(images.length, (index) => null);
    var mx = client.getMatrixClient();

    for (var i = 0; i < images.length; i++) {
      var data = images[i];
      var uri = await mx.uploadContent(data);
      fileCache?.putFile(MatrixMxcImage.getIdentifier(uri), data);
      results[i] = uri;

      current += 1;
      Log.i("Uploaded sticker: $uri ($current/$total)");
      label = "Uploading stickers: ($current/$total)";
      progressStream.add(current);
    }

    return results;
  }

  void complete() {
    status = BackgroundTaskStatus.completed;
    controller.add(null);

    Timer(const Duration(seconds: 5), () {
      shouldRemoveTask = true;
      controller.add(null);
    });
  }
}
