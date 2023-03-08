import 'package:commet/client/attachment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import '../../config/app_config.dart';

class MessageAttachment extends StatefulWidget {
  MessageAttachment(this.attachment, {super.key});
  Attachment attachment;

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
      child: Image(image: AssetImage("assets/images/placeholder/generic/checker_red.png")),
    );
  }
}
