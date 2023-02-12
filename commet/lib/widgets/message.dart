import 'package:flutter/material.dart';
import '../client/client.dart';

class Message extends StatefulWidget {
  const Message(this.event, {super.key});
  final TimelineEvent event;

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> {
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.event.status.isSent ? 1 : 0.5,
      child: ListTile(
        leading: CircleAvatar(
          foregroundImage: widget.event.sender.avatar,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(widget.event.sender.displayName),
            ),
            Text(
              widget.event.originServerTs.toIso8601String(),
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
        subtitle: widget.event.body == null ? null : Text(widget.event.body!),
      ),
    );
  }
}
