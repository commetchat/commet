import 'package:commet/client/attachment.dart';
import 'package:commet/ui/atoms/lightbox.dart';
import 'package:commet/ui/molecules/video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';

class MessageAttachment extends StatefulWidget {
  const MessageAttachment(this.attachment, {super.key});
  final Attachment attachment;

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
    if (widget.attachment is VideoAttachment) return buildVideo();

    return const Placeholder();
  }

  Widget buildImage() {
    assert(widget.attachment is ImageAttachment);
    var attachment = widget.attachment as ImageAttachment;

    return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Material(
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
        )));
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
}
