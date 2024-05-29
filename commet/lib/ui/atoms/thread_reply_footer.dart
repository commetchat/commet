import 'package:commet/ui/atoms/generic_room_event.dart';
import 'package:commet/ui/molecules/message.dart';
import 'package:flutter/material.dart';

class ThreadReplyFooter extends StatelessWidget {
  const ThreadReplyFooter(
      {required this.body,
      required this.senderName,
      this.senderAvatar,
      this.senderColor,
      this.onTap,
      super.key});
  final String body;
  final String senderName;
  final Color? senderColor;
  final ImageProvider? senderAvatar;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 0, 0),
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox(
                    width: 30,
                    child: SizedBox.expand(
                      child: CustomPaint(
                        painter: ThreadLinePainter(
                            pathColor: Theme.of(context).colorScheme.secondary),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 0, 4, 0),
                    child: Icon(
                      Icons.message_rounded,
                      size: 15,
                    ),
                  ),
                  Flexible(
                    child: IntrinsicHeight(
                      child: GenericRoomEvent(
                        padding: const EdgeInsets.fromLTRB(4, 4, 0, 4),
                        leftPadding: 0,
                        body,
                        senderImage: senderAvatar,
                        senderName: senderName,
                        senderColor: senderColor,
                        maxLines: 3,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 0, 4, 0),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
