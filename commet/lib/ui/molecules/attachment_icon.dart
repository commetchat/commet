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

  @override
  Widget build(BuildContext context) {
    Image? image;

    if (Mime.imageTypes.contains(widget.attachment.mimeType) &&
        widget.attachment.data != null) {
      image = Image.memory(widget.attachment.data!,
          filterQuality: FilterQuality.medium, fit: BoxFit.cover);
    }

    return ImageButton(
      size: 20,
      image: image?.image,
      icon: Mime.toIcon(widget.attachment.mimeType),
      onTap: widget.removeAttachment,
      iconSize: 20,
    );
  }
}
