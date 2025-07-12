import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:commet/client/attachment.dart';
import 'package:commet/client/components/photo_album_room/photo_album_room_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/background_tasks/background_task_manager.dart';
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'package:image/image.dart' as img;

class MatrixUploadPhotosTask implements BackgroundTaskWithIntegerProgress {
  List<PickedPhoto> files;

  MatrixRoom room;
  bool extractMetadata;
  bool sendOriginal;

  BackgroundTaskStatus status = BackgroundTaskStatus.running;

  StreamController<int> progressStream = StreamController.broadcast();
  StreamController controller = StreamController.broadcast();

  MatrixUploadPhotosTask(this.files, this.room,
      {this.extractMetadata = true, this.sendOriginal = false}) {
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
      var file = files[i];

      var name = file.name;
      print("Loading bytes");
      var imageData = await file.getBytes();
      print("Loaded bytes");
      Map<String, dynamic> extraInfo = {};

      if (extractMetadata) {
        Map<String, dynamic> exifInfo = {};

        print("Loading exif data");
        var exif = await readExifFromBytes(imageData);
        print("Finished loading exif");

        for (var key in [
          "EXIF DateTimeOriginal",
          "EXIF DateTimeDigitized",
          "Image DateTime",
        ]) {
          if (exif.containsKey(key)) {
            var exifData = exif[key];
            if (exifData == null) continue;

            if (exifData.tagType == "ASCII") {
              exifInfo[key] = {};

              exifInfo[key]["tag_type"] = exifData.tagType;
              exifInfo[key]["value"] = exifData.printable;
            }
          }
        }

        if (exifInfo.isNotEmpty) {
          extraInfo["chat.commet.exif"] = exifInfo;
        }
      }

      if (!sendOriginal) {
        imageData = await compute((bytes) {
          print("Decoding image");
          var decoder = img.findDecoderForData(bytes);
          var image = decoder!.decode(bytes)!;
          image.exif.clear();
          Uint8List? processedData;
          print("Reencoding image");
          return img.encodeJpg(image, quality: 90);
        }, imageData);
        print("Finished encoding image");

        var rawName = p.basenameWithoutExtension(name);
        name = "$rawName.jpeg";
      }

      var processed = await room.processAttachment(
          PendingFileAttachment(name: name, data: imageData));

      var event = await room.sendMessage(
          processedAttachments: [processed!], fileExtraContent: extraInfo);
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
