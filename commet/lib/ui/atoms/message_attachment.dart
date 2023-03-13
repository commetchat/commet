import 'package:commet/client/attachment.dart';
import 'package:flutter/material.dart';

import '../../config/app_config.dart';

class MessageAttachment extends StatefulWidget {
  const MessageAttachment(this.attachment, {super.key});
  final Attachment attachment;

  @override
  State<MessageAttachment> createState() => _MessageAttachmentState();
}

class _MessageAttachmentState extends State<MessageAttachment> {
  @override
  Widget build(BuildContext context) {
    return buildImage(context);
  }

  Widget buildImage(BuildContext context) {
    return SizedBox(
      height: s(200),
      child: const Image(image: AssetImage("assets/images/placeholder/generic/checker_red.png")),
    );
  }
}
