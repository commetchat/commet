import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:commet/client/attachment.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/background_tasks/background_task_manager.dart';
import 'package:path/path.dart' as p;

class MatrixUploadPhotosTask implements BackgroundTaskWithIntegerProgress {
  List<Uri> files;

  MatrixRoom room;

  BackgroundTaskStatus status = BackgroundTaskStatus.running;

  StreamController<int> progressStream = StreamController.broadcast();
  StreamController controller = StreamController.broadcast();

  MatrixUploadPhotosTask(this.files, this.room) {
    total = files.length;
  }

  @override
  void Function()? action;

  @override
  bool get canCallAction => false;

  @override
  int current = 0;

  @override
  void dispose() {}

  @override
  String get label => "Uploading Photos";

  @override
  Stream<int> get onProgress => progressStream.stream;

  @override
  bool shouldRemoveTask = false;

  @override
  Stream<void> get statusChanged => controller.stream;

  @override
  late int total;

  Future<void> uploadImages() async {
    for (var i = 0; i < files.length; i++) {
      var uri = files[i];
      var path = uri.toFilePath();
      var name = p.basename(path);
      var data = await File(path).readAsBytes();
      var processed = await room.processAttachment(
          PendingFileAttachment(path: path, name: name, data: data));

      var event = await room.sendMessage(processedAttachments: [processed!]);
      current += 1;
      progressStream.add(current);
    }

    status = BackgroundTaskStatus.completed;
    controller.add(null);

    Timer(const Duration(seconds: 5), () {
      shouldRemoveTask = true;
      controller.add(null);
    });
  }
}
