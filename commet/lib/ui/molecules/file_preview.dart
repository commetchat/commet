import 'dart:convert' show utf8;
import 'dart:io';

import 'package:commet/cache/file_provider.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/ui/atoms/code_block.dart';
import 'package:commet/ui/molecules/video_player/video_player.dart';
import 'package:commet/ui/molecules/video_player/video_player_controller.dart';
import 'package:commet/utils/mime.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FilePreview extends StatefulWidget {
  const FilePreview(
      {required this.mimeType,
      this.path,
      this.data,
      this.videoController,
      super.key});
  final String? mimeType;
  final String? path;
  final Uint8List? data;
  final VideoPlayerController? videoController;

  @override
  State<FilePreview> createState() => _FilePreviewState();
}

class _FilePreviewState extends State<FilePreview> {
  ImageProvider? image;
  String? text;
  FileProvider? videoFile;
  GlobalKey videoPlayerKey = GlobalKey();

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

    if (PlatformUtils.isWeb == false) {
      if (Mime.videoTypes.contains(widget.mimeType) && widget.path != null) {
        videoFile = SystemFileProvider(File(widget.path!));
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
    if (videoFile != null) {
      return VideoPlayer(
        videoFile!,
        decodeFirstFrame: true,
        doThumbnail: false,
        key: videoPlayerKey,
        controller: widget.videoController,
      );
    }
    return const SizedBox(
      height: 0,
    );
  }
}
