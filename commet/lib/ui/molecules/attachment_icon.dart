import 'package:commet/client/attachment.dart';
import 'package:commet/utils/mime.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart';

class AttachmentIcon extends StatefulWidget {
  const AttachmentIcon(this.attachment, {super.key, this.removeAttachment});
  final PendingFileAttachment attachment;
  final Function()? removeAttachment;

  @override
  State<AttachmentIcon> createState() => _AttachmentIconState();
}

class _AttachmentIconState extends State<AttachmentIcon> {
  bool hovered = false;

  ImageProvider? image;

  @override
  void initState() {
    if (Mime.imageTypes.contains(widget.attachment.mimeType) &&
        widget.attachment.data != null) {
      image = Image.memory(widget.attachment.data!).image;
    }

    if (widget.attachment.thumbnailFile != null) {
      image = Image.memory(widget.attachment.thumbnailFile!).image;
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ImageButton(
      size: 20,
      image: image,
      icon: Mime.toIcon(widget.attachment.mimeType),
      onTap: widget.removeAttachment,
      iconSize: 20,
    );
  }
}
