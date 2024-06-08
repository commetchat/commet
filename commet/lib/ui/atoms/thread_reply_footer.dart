import 'package:commet/config/layout_config.dart';
import 'package:commet/ui/molecules/message.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

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
            padding: const EdgeInsets.fromLTRB(14, 0, 0, 0),
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
                    padding: EdgeInsets.all(8),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(4, 0, 4, 0),
                      child: Icon(
                        Icons.message_rounded,
                        size: 15,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
                      child: Row(
                        children: [
                          tiamat.Avatar(
                            image: senderAvatar,
                            placeholderColor: senderColor,
                            placeholderText: senderName,
                            radius: 10,
                          ),
                          if (Layout.desktop)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
                              child: tiamat.Text(
                                senderName,
                                color: senderColor,
                                maxLines: 1,
                                autoAdjustBrightness: true,
                              ),
                            ),
                          Flexible(
                            child: tiamat.Text.labelLow(
                              body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
