import 'package:commet/client/timeline.dart';
import 'package:commet/config/build_config.dart';

import 'package:commet/ui/atoms/message_attachment.dart';

import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';
import '../../generated/l10n.dart';

import 'package:flutter/material.dart' as material;

class Message extends StatefulWidget {
  const Message(this.event,
      {super.key, this.showSender = true, this.onDelete, this.relatedEvent});

  final TimelineEvent event;
  final TimelineEvent? relatedEvent;
  final bool showSender;
  final Function? onDelete;

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> {
  bool hovered = false;

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
    return material.Material(
      color: material.Colors.transparent,
      child: BuildConfig.MOBILE
          ? material.InkWell(
              child: buildContent(context),
              onLongPress: () {},
            )
          : MouseRegion(
              child: buildContent(context),
              onEnter: (_) {
                setState(() {
                  hovered = true;
                });
              },
              onExit: (_) {
                setState(() {
                  hovered = false;
                });
              },
            ),
    );
  }

  Widget buildContent(BuildContext context) {
    return Container(
      color: hovered
          ? material.Theme.of(context).hoverColor
          : material.Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(15, widget.showSender ? 10 : 4, 8, 4),
        child: Stack(
          children: [
            Opacity(
              opacity:
                  widget.event.status == TimelineEventStatus.sending ? 0.5 : 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: material.MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.event.relationshipType ==
                      EventRelationshipType.reply)
                    response(context),
                  Row(
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
                      messageBody(context, selectableText: !BuildConfig.MOBILE)
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget response(BuildContext context) {
    if (widget.relatedEvent == null) return responseLoading(context);
    return responseLoaded(context);
  }

  Widget responseLoaded(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(50, 0, 0, 0),
              child: Icon(material.Icons.keyboard_arrow_right_rounded),
            ),
            tiamat.Text.name(
              widget.relatedEvent!.sender.displayName,
              color: widget.relatedEvent!.sender.color,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                child: tiamat.Text(
                  widget.relatedEvent!.body ??
                      widget.relatedEvent!.attachments?.first.name ??
                      "Unknown",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  color: material.Theme.of(context).colorScheme.secondary,
                ),
              ),
            )
          ]),
    );
  }

  Widget responseLoading(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Padding(
              padding: EdgeInsets.fromLTRB(50, 0, 0, 0),
              child: Icon(material.Icons.keyboard_arrow_right_rounded),
            ),
            Opacity(
              opacity: 0.5,
              child: SizedBox(
                  height: 5,
                  width: 100,
                  child: material.LinearProgressIndicator()),
            ),
          ]),
    );
  }

  Widget messageBody(BuildContext context, {bool selectableText = true}) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showSender) senderName(context),
            if (widget.event.status == TimelineEventStatus.removed)
              tiamat.Text.error(T.of(context).messageDeleted)
            else if (widget.event.bodyFormat != null)
              selectableText
                  ? material.SelectionArea(
                      child: widget.event.formattedContent!)
                  : widget.event.formattedContent!
            else if (widget.event.body != null)
              selectableText
                  ? material.SelectionArea(
                      child: tiamat.Text.body(widget.event.body!))
                  : tiamat.Text.body(widget.event.body!),
            if (widget.event.attachments != null)
              Wrap(
                children: widget.event.attachments!
                    .map((e) => Padding(
                          padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
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
    );
  }

  Widget senderName(BuildContext context) {
    return tiamat.Text.name(
      widget.event.sender.displayName,
      color: widget.event.sender.color,
    );
  }

  Widget debugInfo() {
    var info = List.from(
        [widget.event.type.toString(), widget.event.status.toString()],
        growable: true);
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
                .map((e) => Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                    child: tiamat.Text.tiny(e)))
                .toList(),
          ),
        ],
      ),
    );
  }
}
