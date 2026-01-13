import 'dart:typed_data';
import 'dart:ui';

import 'package:commet/config/layout_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:commet/utils/image_utils.dart';
import 'package:crop_image/crop_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

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

  static Future<Uint8List?> pickImageAndCrop(BuildContext context,
      {double? aspectRatio}) async {
    var image = await pickImage();
    if (image == null) return null;

    var bytes = await image.readAsBytes();

    final controller = CropController(
      aspectRatio: aspectRatio,
      defaultCrop: Rect.fromLTRB(0.05, 0.05, 0.95, 0.95),
    );

    var imageProvider = Image.memory(bytes).image;

    var uiImage = await ImageUtils.imageProviderToImage(imageProvider);
    var ratio = uiImage.width.toDouble() / uiImage.height.toDouble();

    var result = await tiamat.PopupDialog.show<Uint8List>(context,
        content: ImageCropView(
          bytes,
          controller,
          ratio,
          onImageSubmitted: (data) => Navigator.of(context).pop(data),
        ));

    return result;
  }
}

class ImageCropView extends StatelessWidget {
  const ImageCropView(this.imageBytes, this.controller, this.imageAspectRatio,
      {this.onImageSubmitted, super.key});

  final CropController controller;
  final Uint8List imageBytes;

  final double imageAspectRatio;

  final Function(Uint8List data)? onImageSubmitted;

  final double width = 1000;

  @override
  Widget build(BuildContext context) {
    var buttons = [
      Expanded(
        flex: Layout.desktop ? 1 : 0,
        child: tiamat.Button.secondary(
          text: "Use Original Image",
          onTap: () async {
            onImageSubmitted?.call(imageBytes);
          },
        ),
      ),
      Expanded(
        flex: Layout.desktop ? 1 : 0,
        child: tiamat.Button(
          text: CommonStrings.promptSubmit,
          onTap: () async {
            print("Hello!");
            var image = await controller.croppedBitmap();

            var data = await image.toByteData(format: ImageByteFormat.png);
            if (data == null) return;

            var bytes = Uint8List.sublistView(data);
            onImageSubmitted?.call(bytes);
          },
        ),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SizedBox(
            width: 1000,
            child: AspectRatio(
                aspectRatio: imageAspectRatio,
                child: Container(
                  child: CropImage(
                    image: Image.memory(imageBytes),
                    controller: controller,
                  ),
                )),
          ),
        ),
        SizedBox(
          height: 20,
        ),
        if (Layout.desktop)
          Row(spacing: 8, mainAxisSize: MainAxisSize.max, children: buttons),
        if (Layout.mobile)
          Column(
            spacing: 8,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: buttons,
          )
      ],
    );
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
