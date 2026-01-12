import 'dart:typed_data';

import 'package:commet/config/platform_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class PickerUtils {
  static Future<PickerResult?> pickImage() async {
    if (PlatformUtils.isAndroid) {
      var picker = ImagePicker();
      final result = await picker.pickImage(source: ImageSource.gallery);
      if (result != null) {
        return PickerResultXFile(result);
      }
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['bmp', 'gif', 'jpg', 'jpeg', 'png', 'webp', 'apng'],
      );

      var file = result?.xFiles.firstOrNull;
      if (file != null) {
        return PickerResultXFile(file);
      }
    }

    return null;
  }
}

abstract class PickerResult {
  Future<Uint8List> readAsBytes();

  String get name;

  String? get mimeType;
}

class PickerResultXFile implements PickerResult {
  final XFile file;

  PickerResultXFile(this.file);

  @override
  Future<Uint8List> readAsBytes() {
    return file.readAsBytes();
  }

  @override
  String get name => file.name;

  @override
  String? get mimeType => file.mimeType;
}
