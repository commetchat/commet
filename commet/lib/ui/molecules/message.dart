import 'package:commet/client/timeline.dart';
import 'package:commet/config/app_config.dart';
import 'package:commet/config/build_config.dart';

import 'package:commet/ui/atoms/message_attachment.dart';

import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';
import '../../generated/l10n.dart';

import 'package:flutter/material.dart' as material;

class Message extends StatefulWidget {
  const Message(this.event, {super.key, this.showSender = true, this.onDelete});

  final TimelineEvent event;
  final bool showSender;
  final Function? onDelete;

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(s(15), widget.showSender ? s(20) : s(4), 8, 4),
      child: Stack(
        children: [
          Opacity(
            opacity: widget.event.status == TimelineEventStatus.sending ? 0.5 : 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showSender)
                  Avatar.medium(
                    image: widget.event.sender.avatar,
                  ),
                if (!widget.showSender)
                  const Avatar.medium(
                    image: null,
                    isPadding: true,
                  ),
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(s(16), 0, s(0), 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.showSender) senderName(context),
                        if (widget.event.status == TimelineEventStatus.removed)
                          tiamat.Text.error(T.of(context).messageDeleted)
                        else if (widget.event.bodyFormat != null)
                          formattedBody()
                        else if (widget.event.body != null)
                          tiamat.Text.body(
                            widget.event.body!,
                          ),
                        if (widget.event.attachments != null)
                          Wrap(
                            children: widget.event.attachments!
                                .map((e) => Padding(
                                      padding: EdgeInsets.fromLTRB(0, s(8), s(8), s(8)),
                                      child: MessageAttachment(e),
                                    ))
                                .toList(),
                          ),
                        if (widget.event.status == TimelineEventStatus.error)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                            child: tiamat.Text.error(T.of(context).messageFailedToSend),
                          ),
                        if (BuildConfig.DEBUG) debugInfo()
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget formattedBody() {
    return widget.event.formattedContent!;
  }

  Widget senderName(BuildContext context) {
    return tiamat.Text.name(
      widget.event.sender.displayName,
      color: widget.event.sender.color,
    );
  }

  Widget debugInfo() {
    var info = List.from([widget.event.type.toString(), widget.event.status.toString()], growable: true);
    if (widget.event.source != null) info.add(widget.event.source);
    return Opacity(
      opacity: 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Seperator(),
          Wrap(
            alignment: WrapAlignment.start,
            runAlignment: WrapAlignment.start,
            children: info
                .map((e) => Padding(padding: const EdgeInsets.fromLTRB(4, 0, 4, 0), child: tiamat.Text.tiny(e)))
                .toList(),
          ),
        ],
      ),
    );
  }
}
