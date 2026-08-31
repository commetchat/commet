import 'dart:io';

import 'package:commet/client/attachment.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/ui/molecules/file_preview.dart';
import 'package:commet/ui/molecules/video_player/video_player_controller.dart';
import 'package:commet/utils/mime.dart';
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:tiamat/tiamat.dart' as tiamat;

class AttachmentProcessor extends StatefulWidget {
  const AttachmentProcessor({required this.attachment, super.key});
  final PendingFileAttachment attachment;

  @override
  State<AttachmentProcessor> createState() => _AttachmentProcessorState();
}

class _AttachmentProcessorState extends State<AttachmentProcessor> {
  String get promptAttachmentProcessingSendOriginal => Intl.message("Send Original",
      name: "promptAttachmentProcessingSendOriginal",
      desc:
          "Prompt text for the option to send a file in its original state, without any further processing such as removing metadata");

  String get labelImageContainsLocationInfo => Intl.message("Warning: This image contains location metadata",
      name: "labelImageContainsLocationInfo",
      desc:
          "Prompt text for the option to send a file in its original state, without any further processing such as removing metadata");

  Map<String, IfdTag>? exifData;
  late IconData icon;
  VideoPlayerController? videoController;

  bool canProcessData = false;
  bool containsGpsData = false;
  bool sendOriginalFile = false;

  bool processing = false;

  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    icon = Mime.toIcon(widget.attachment.mimeType);
    if (Mime.imageTypes.contains(widget.attachment.mimeType)) {
      loadExif();
      canProcessData = true;

      if (widget.attachment.mimeType == "image/gif") {
        canProcessData = false;
      }
    } else if (Mime.videoTypes.contains(widget.attachment.mimeType)) {
      videoController = VideoPlayerController();
      canProcessData = true;
    }
    super.initState();
  }

  @override
  void dispose() {
    videoController?.pause();
    super.dispose();
  }

  void loadExif() async {
    late Map<String, IfdTag> data;
    if (widget.attachment.data != null) {
      data = await readExifFromBytes(widget.attachment.data!);
    } else {
      data = await readExifFromFile(File(widget.attachment.path!));
    }

    setState(() {
      if (data.keys.any((e) => e.toLowerCase().contains("gps"))) {
        containsGpsData = true;
      }

      exifData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaledSafeArea(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: processing ? 0.5 : 1,
            child: IgnorePointer(
              ignoring: processing,
              child: KeyboardListener(
                focusNode: focusNode,
                autofocus: true,
                onKeyEvent: (value) {
                  if (processing) return;

                  if (value.logicalKey == LogicalKeyboardKey.enter) {
                    submit();
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.attachment.name != null)
                      Row(
                        children: [
                          Icon(icon),
                          Flexible(
                            child: tiamat.Text.labelLow(
                              widget.attachment.name!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ConstrainedBox(
                          constraints: BoxConstraints.loose(const Size(500, 500)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FilePreview(
                              mimeType: widget.attachment.mimeType,
                              path: widget.attachment.path,
                              data: widget.attachment.data,
                              videoController: videoController,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (canProcessData)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: buildFileProcessingSwitch(),
                      ),
                    if (sendOriginalFile || !canProcessData) buildMetadataDisplay(),
                    buildConfirmButton(),
                  ],
                ),
              ),
            ),
          ),
          if (processing) const CircularProgressIndicator()
        ],
      ),
    );
  }

  Widget buildFileProcessingSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        tiamat.Text.label(promptAttachmentProcessingSendOriginal),
        tiamat.Switch(
          state: sendOriginalFile,
          onChanged: (value) => setState(() {
            sendOriginalFile = value;
          }),
        ),
      ],
    );
  }

  Widget buildMetadataDisplay() {
    return Column(
      children: [
        if (containsGpsData)
          tiamat.Text.error(
            labelImageContainsLocationInfo,
          )
      ],
    );
  }

  Widget buildConfirmButton() {
    return tiamat.Button(
      text: "Add File",
      onTap: submit,
    );
  }

  void submit() async {
    if (canProcessData == false || sendOriginalFile) {
      Navigator.of(context).pop(widget.attachment);
    } else {
      setState(() {
        processing = true;
      });
      var file = await processFile();
      if (mounted) {
        Navigator.of(context).pop(file);
      }
    }
  }

  /// Helper to resolve MIME type using dynamic magic-number stream reads
  static Future<String> _resolveMimeType(PendingFileAttachment attachment) async {
    var mimeType = attachment.mimeType?.toLowerCase();
    if ((mimeType == null || mimeType.isEmpty) && attachment.path != null) {
      try {
        final file = File(attachment.path!);
        if (await file.exists()) {
          final stream = file.openRead(0, Mime.magicNumbersMaxLength);
          final headerBytes = await stream.first;
          mimeType = Mime.lookupType(
            attachment.path!,
            data: Uint8List.fromList(headerBytes),
          )?.toLowerCase();
        }
      } catch (_) {
        mimeType = Mime.lookupType(attachment.path!)?.toLowerCase();
      }
    }
    return mimeType ?? "";
  }

  Future<PendingFileAttachment> processFile() async {
    final mimeType = await _resolveMimeType(widget.attachment);

    if (Mime.imageTypes.contains(mimeType)) {
      return await processImage();
    } else if (Mime.videoTypes.contains(mimeType)) {
      return await processVideo();
    }

    return widget.attachment;
  }

  Future<PendingFileAttachment> processImage() async {
    var mimeType = await _resolveMimeType(widget.attachment);

    final bool supportsNativeCompress = !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

    CompressFormat? format;
    if (mimeType.contains("jpeg") || mimeType.contains("jpg")) {
      format = CompressFormat.jpeg;
    } else if (mimeType.contains("png")) {
      format = CompressFormat.png;
    } else if (mimeType.contains("webp")) {
      format = CompressFormat.webp;
    }

    if (!supportsNativeCompress || format == null) {
      return await compute(_fallbackProcessImage, widget.attachment);
    }

    try {
      Uint8List? processedData;

      if (widget.attachment.path != null) {
        processedData = await FlutterImageCompress.compressWithFile(
          widget.attachment.path!,
          keepExif: false,
          quality: 100,
          format: format,
        );
      } else if (widget.attachment.data != null) {
        processedData = await FlutterImageCompress.compressWithList(
          widget.attachment.data!,
          keepExif: false,
          quality: 100,
          format: format,
        );
      }

      if (processedData != null) {
        return PendingFileAttachment(
          name: widget.attachment.name,
          data: processedData,
          size: processedData.lengthInBytes,
          mimeType: mimeType,
        );
      }
    } catch (_) {}

    // Fallback if native compression returned null or threw an error
    return await compute(_fallbackProcessImage, widget.attachment);
  }

  /// Pure-Dart fallback isolate worker for Windows / Linux
  static Future<PendingFileAttachment> _fallbackProcessImage(PendingFileAttachment attachment) async {
    img.Image? image;

    // Stream directly from disk to avoid allocating raw file bytes in RAM
    if (attachment.path != null) {
      image = await img.decodeImageFile(attachment.path!);
    } else if (attachment.data != null) {
      image = img.decodeImage(attachment.data!);
    }

    if (image == null) throw Exception("Unable to decode image file.");

    image.exif.clear();

    var mime = await _resolveMimeType(attachment);
    if (mime.isEmpty) mime = "image/png";

    Uint8List? processedData;
    String? name = attachment.name;

    if (attachment.name != null) {
      processedData = img.encodeNamedImage(attachment.name!, image);
    }

    if (processedData == null) {
      processedData = img.encodePng(image);
      mime = "image/png";
      var fileName = attachment.name ?? "untitled.png";
      var rawName = path.basenameWithoutExtension(fileName);
      name = "$rawName.png";
    }

    return PendingFileAttachment(
      name: name,
      data: processedData,
      size: processedData.lengthInBytes,
      mimeType: mime,
    );
  }

  Future<PendingFileAttachment> processVideo() async {
    var file = widget.attachment;

    if (videoController != null) {
      file.thumbnailFile = await videoController!.screenshot();
      if (file.thumbnailFile != null) {
        file.thumbnailMime = Mime.lookupType("", data: file.thumbnailFile);
      }
    }

    file.length = await videoController!.getLength();
    file.dimensions = await videoController!.getSize();

    return file;
  }
}
