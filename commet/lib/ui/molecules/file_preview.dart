import 'dart:convert' show utf8;
import 'dart:io';

import 'package:commet/ui/atoms/code_block.dart';
import 'package:commet/utils/mime.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FilePreview extends StatefulWidget {
  const FilePreview({required this.mimeType, this.path, this.data, super.key});
  final String? mimeType;
  final String? path;
  final Uint8List? data;

  @override
  State<FilePreview> createState() => _FilePreviewState();
}

class _FilePreviewState extends State<FilePreview> {
  ImageProvider? image;
  String? text;

  @override
  void initState() {
    if (widget.mimeType != null) {
      if (Mime.displayableImageTypes.contains(widget.mimeType)) {
        if (widget.data != null) {
          image = Image.memory(widget.data!).image;
        } else {
          image = Image.file(File(widget.path!)).image;
        }
      } else if (Mime.isText(widget.mimeType!) && widget.data != null) {
        text = utf8.decode(widget.data!);
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (image != null) {
      return Image(
        image: image!,
        filterQuality: FilterQuality.medium,
        fit: BoxFit.contain,
      );
    }
    if (text != null) {
      return Codeblock(text: text!);
    }
    return const SizedBox(
      height: 0,
    );
  }
}
