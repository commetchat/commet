import 'package:commet/cache/file_image.dart';
import 'package:commet/client/attachment.dart';
import 'package:commet/ui/atoms/lightbox.dart';
import 'package:commet/ui/atoms/video_player.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/image_button.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import '../../config/app_config.dart';

class MessageAttachment extends StatefulWidget {
  const MessageAttachment(this.attachment, {super.key});
  final Attachment attachment;

  static const displayableTypes = {"image/jpeg", "image/png"};
  static const imageTypes = {"image/jpeg", "image/png"};
  static const videoTypes = {"video/mp4", "image/png"};

  @override
  State<MessageAttachment> createState() => _MessageAttachmentState();
}

class _MessageAttachmentState extends State<MessageAttachment> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (MessageAttachment.imageTypes.contains(widget.attachment.mimeType)) return buildImage(context);
    if (MessageAttachment.videoTypes.contains(widget.attachment.mimeType)) return buildVideo(context);
    return SizedBox();
  }

  Widget buildVideo(BuildContext context) {
    return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 300),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(
            aspectRatio: widget.attachment.aspectRatio != null ? widget.attachment.aspectRatio! : 16 / 9,
            child: VideoPlayer(
              widget.attachment.fileProvider,
              thumbnail: widget.attachment.thumbnail != null ? FileImageProvider(widget.attachment.thumbnail!) : null,
            ),
          ),
        ));
  }

  Widget buildImage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Material(
        child: SizedBox(
          height: 200,
          child: ClipRRect(
            child: AspectRatio(
              aspectRatio: widget.attachment.aspectRatio!,
              child: Ink.image(
                image: FileImageProvider(widget.attachment.fileProvider),
                child: InkWell(
                  onTap: () {
                    Lightbox.show(context, image: FileImageProvider(widget.attachment.fileProvider));
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
