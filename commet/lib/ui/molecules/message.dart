import 'package:commet/client/timeline.dart';
import 'package:commet/ui/atoms/avatar.dart';
import 'package:commet/ui/atoms/message_attachment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class Message extends StatefulWidget {
  const Message(this.event, {super.key, this.showSender = true});
  final TimelineEvent event;
  final bool showSender;

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.showSender ? EdgeInsets.fromLTRB(15, 20, 8, 4) : EdgeInsets.fromLTRB(15, 4, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showSender)
            Avatar.medium(
              image: widget.event.sender.avatar,
            ),
          if (!widget.showSender)
            Avatar.medium(
              image: null,
            ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 8, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showSender)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                      child: Text(
                        widget.event.sender.displayName,
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.red, fontSize: 17),
                      ),
                    ),
                  Text(
                    widget.event.body!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (widget.event.attachments != null)
                    Wrap(
                      children: widget.event.attachments!
                          .map((e) => Padding(
                                padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                                child: MessageAttachment(e),
                              ))
                          .toList(),
                    )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
