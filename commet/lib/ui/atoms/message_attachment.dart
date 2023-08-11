import 'package:commet/client/attachment.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/ui/atoms/lightbox.dart';
import 'package:commet/ui/molecules/video_player/video_player.dart';
import 'package:commet/utils/mime.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class MessageAttachment extends StatefulWidget {
  const MessageAttachment(this.attachment,
      {super.key, this.ignorePointer = false});
  final Attachment attachment;
  final bool ignorePointer;

  @override
  State<MessageAttachment> createState() => _MessageAttachmentState();
}

class _MessageAttachmentState extends State<MessageAttachment> {
  late Key videoPlayerKey;
  @override
  void initState() {
    videoPlayerKey = UniqueKey();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attachment is ImageAttachment) return buildImage();
    if (widget.attachment is VideoAttachment) {
      if (BuildConfig.WEB) {
        return buildFile(Icons.video_file, widget.attachment.name, null);
      }
      return buildVideo();
    }
    if (widget.attachment is FileAttachment) {
      var attachment = widget.attachment as FileAttachment;
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
              child: SizedBox(
                height: 200,
                child: AspectRatio(
                  aspectRatio: attachment.aspectRatio,
                  child: InkWell(
                    onTap: () {
                      Lightbox.show(context, image: attachment.image);
                    },
                    child: Image(
                      image: attachment.image,
                      filterQuality: FilterQuality.medium,
                      fit: BoxFit.cover,
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
            header: attachment.name,
            mode: TileType.surfaceLow2,
            padding: 0,
            child: SizedBox(
                height: 200,
                width: 500,
                child: AspectRatio(
                    aspectRatio: attachment.aspectRatio,
                    child: VideoPlayer(
                      attachment.videoFile,
                      thumbnail: attachment.thumbnail,
                      fileName: attachment.name,
                      canGoFullscreen: true,
                      onFullscreen: fullscreenVideo,
                    )))),
      ),
    );
  }

  void fullscreenVideo() {
    var attachment = (widget.attachment as VideoAttachment);
    Lightbox.show(
      context,
      video: attachment.videoFile,
      aspectRatio: attachment.aspectRatio,
      thumbnail: attachment.thumbnail,
    );
  }

  Widget buildFile(IconData icon, String fileName, int? fileSize) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).extension<ExtraColors>()!.surfaceLow1,
          border: Border.all(
              color: Theme.of(context).extension<ExtraColors>()!.outline)),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(
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
                    tiamat.Text.labelEmphasised(fileName),
                    if (fileSize != null)
                      tiamat.Text.labelLow(TextUtils.readableFileSize(fileSize))
                  ],
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
