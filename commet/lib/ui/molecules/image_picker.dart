import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';
import '../../utils/mime.dart';
import '../atoms/tooltip.dart' as t;

class ImagePicker extends StatefulWidget {
  const ImagePicker(
      {super.key,
      this.currentImage,
      this.onImagePicked,
      this.onImageRead,
      this.size = 128,
      this.tooltip = "Pick Image",
      this.withData = false});
  final ImageProvider? currentImage;
  final bool withData;
  final String tooltip;
  final double size;
  final Function(String filepath)? onImagePicked;
  final Function(Uint8List bytes, String? mimeType)? onImageRead;

  @override
  State<ImagePicker> createState() => _ImagePickerState();
}

class _ImagePickerState extends State<ImagePicker> {
  ImageProvider? image;

  @override
  void initState() {
    image = widget.currentImage;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return t.Tooltip(
      text: widget.tooltip,
      preferredDirection: AxisDirection.down,
      child: ImageButton(
        size: 128,
        image: image,
        onTap: pickImage,
      ),
    );
  }

  void pickImage() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: widget.withData);
    if (result == null || result.count != 1) return;

    if (widget.withData) {
      var type = Mime.fromExtenstion(result.files.first.extension!);
      if (type == null || result.files.first.bytes == null) return;

      setState(() {
        image = Image.memory(result.files.first.bytes!).image;
      });

      widget.onImageRead?.call(result.files.first.bytes!, type);
    } else {
      widget.onImagePicked?.call(result.files.first.path!);
    }
  }
}
