import 'package:commet/client/attachment.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/ui/atoms/lightbox.dart';
import 'package:commet/ui/molecules/audio_player/audio_player.dart';
import 'package:commet/ui/molecules/video_player/video_player.dart';
import 'package:commet/ui/molecules/video_player/video_player_controller.dart';
import 'package:commet/utils/background_tasks/background_task_manager.dart';
import 'package:commet/utils/download_utils.dart';
import 'package:commet/utils/mime.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class MessageAttachment extends StatefulWidget {
  const MessageAttachment(this.attachment,
      {super.key, this.ignorePointer = false, this.previewMedia = false});
  final Attachment attachment;
  final bool ignorePointer;
  final bool previewMedia;
  @override
  State<MessageAttachment> createState() => _MessageAttachmentState();
}

class _MessageAttachmentState extends State<MessageAttachment> {
  late Key videoPlayerKey;
  bool isFullscreen = false;
  var controller = VideoPlayerController();
  @override
  void initState() {
    videoPlayerKey = GlobalKey();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.previewMedia) {
      if (widget.attachment is ImageAttachment) return buildImage();
      if (widget.attachment is VideoAttachment) {
        if (BuildConfig.WEB) {
          return buildFile(Icons.video_file, widget.attachment.name, null);
        }
        return buildVideo();
      }
    }

    final attachment = widget.attachment;
    if (attachment is FileAttachment) {
      if (attachment.mimeType != null &&
          Mime.playableAudioTypes.contains(attachment.mimeType!)) {
        return buildAudio(attachment);
      }

      return buildFile(Mime.toIcon(attachment.mimeType), attachment.name,
          attachment.fileSize);
    }

    return const Placeholder();
  }

  Widget buildImage() {
    assert(widget.attachment is ImageAttachment);
    var attachment = widget.attachment as ImageAttachment;

    return IgnorePointer(
      ignoring: widget.ignorePointer,
      child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: 200, minHeight: 40, maxWidth: 500, minWidth: 40),
                child: InkWell(
                  onTap: fullscreenAttachment,
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    child: SizedBox(
                      width: attachment.width ?? 500,
                      height: attachment.height ?? 500,
                      child: Image(
                        image: attachment.image,
                        filterQuality: FilterQuality.medium,
                        // if we know the height, its safe to fill as it wont appear stretched
                        fit: attachment.width != null &&
                                attachment.height != null
                            ? BoxFit.fill
                            : BoxFit.fitWidth,
                      ),
                    ),
                  ),
                ),
              ))),
    );
  }

  Widget buildVideo() {
    var attachment = widget.attachment as VideoAttachment;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 200 + 30,
        width: attachment.aspectRatio * 200,
        child: Panel(
            mainAxisSize: MainAxisSize.min,
            header:
                "${attachment.name} ${attachment.fileSize != null ? "- ${TextUtils.readableFileSize(attachment.fileSize!)}" : ""}",
            mode: TileType.surfaceContainerLow,
            padding: 0,
            child: SizedBox(
                height: 200,
                width: 500,
                child: AspectRatio(
                    aspectRatio: attachment.aspectRatio,
                    child: isFullscreen
                        ? null
                        : VideoPlayer(
                            attachment.file,
                            thumbnail: attachment.thumbnail,
                            fileName: attachment.name,
                            doThumbnail: true,
                            canGoFullscreen: true,
                            onFullscreen: fullscreenVideo,
                            controller: controller,
                            key: videoPlayerKey,
                          )))),
      ),
    );
  }

  void fullscreenAttachment() {
    if (widget.attachment is ImageAttachment) {
      final attachment = widget.attachment as ImageAttachment;
      Lightbox.show(context, image: attachment.image);
    }

    if (widget.attachment is VideoAttachment) {
      fullscreenVideo();
    }
  }

  void fullscreenVideo() {
    var attachment = (widget.attachment as VideoAttachment);
    setState(() {
      isFullscreen = true;
    });
    Lightbox.show(context,
            video: attachment.file,
            aspectRatio: attachment.aspectRatio,
            thumbnail: attachment.thumbnail,
            videoController: controller,
            key: videoPlayerKey)
        .then((value) {
      setState(() {
        isFullscreen = false;
      });
    });
  }

  Widget buildFile(IconData icon, String fileName, int? fileSize) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(icon),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        tiamat.Text.labelEmphasised(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (fileSize != null)
                          tiamat.Text.labelLow(
                              TextUtils.readableFileSize(fileSize))
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.attachment is ImageAttachment ||
                widget.attachment is VideoAttachment)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: tiamat.IconButton(
                  size: 20,
                  icon: Icons.visibility,
                  onPressed: fullscreenAttachment,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 4, 0),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: tiamat.IconButton(
                    size: 20,
                    icon: Icons.download,
                    onPressed: () async {
                      if (widget.attachment is FileAttachment) {
                        downloadAttachment(widget.attachment as FileAttachment);
                      }
                    },
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Future<void> downloadAttachment(FileAttachment attachment) async {
    return DownloadUtils.downloadAttachment(attachment);
  }

  Future<BackgroundTaskStatus> downloadTask(
      FileAttachment attachment, String path) async {
    await attachment.file.save(path);

    return BackgroundTaskStatus.completed;
  }

  Widget buildAudio(FileAttachment attachment) {
    return AudioPlayer(
      file: attachment.file,
      fileName: attachment.name,
      fileSize: attachment.fileSize,
    );
  }
}
