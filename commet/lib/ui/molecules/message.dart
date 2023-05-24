import 'package:commet/config/build_config.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:flutter/material.dart' as material;

import '../../generated/l10n.dart';

class Message extends StatefulWidget {
  const Message(
      {super.key,
      required this.senderName,
      required this.senderColor,
      required this.sentTimeStamp,
      required this.body,
      this.senderAvatar,
      this.replyBody,
      this.replySenderColor,
      this.replySenderName,
      this.menuBuilder,
      this.edited = false,
      this.onDoubleTap,
      this.onLongPress,
      this.showSender = true});
  final double avatarSize = 48;

  final bool showSender;
  final String senderName;
  final Color? senderColor;

  final String? replyBody;
  final String? replySenderName;
  final Color? replySenderColor;

  final ImageProvider? senderAvatar;
  final DateTime sentTimeStamp;

  final bool edited;

  final Widget body;

  final Function()? onLongPress;
  final Function()? onDoubleTap;

  final Widget Function(BuildContext context)? menuBuilder;

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> {
  bool hovered = false;
  bool overlayHovered = false;
  OverlayEntry? entry;
  final layerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: layerLink,
      child: material.Material(
        color: material.Colors.transparent,
        child: BuildConfig.MOBILE
            ? material.InkWell(
                onLongPress: widget.onLongPress,
                onDoubleTap: widget.onDoubleTap,
                child: buildContent(),
              )
            : MouseRegion(
                child: GestureDetector(
                    onLongPress: widget.onLongPress,
                    //onDoubleTap: widget.onDoubleTap,
                    child: buildContent()),
                onEnter: (_) {
                  if (entry == null) {
                    _showOverlay();
                  }
                  setState(() {
                    hovered = true;
                  });
                },
                onExit: (_) {
                  setState(() {
                    hovered = false;
                  });

                  handleHideOverlay();
                },
              ),
      ),
    );
  }

  void handleHideOverlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (hovered == false && overlayHovered == false) _removeOverlay();
      }
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _showOverlay() {
    if (widget.menuBuilder == null) return;

    var overlay = Overlay.of(context);
    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
            height: 40,
            child: CompositedTransformFollower(
              targetAnchor: Alignment.topRight,
              followerAnchor: Alignment.topRight,
              showWhenUnlinked: false,
              offset: const Offset(-20, -35),
              link: layerLink,
              child: MouseRegion(
                onEnter: (event) {
                  setState(() {
                    overlayHovered = true;
                  });
                },
                onExit: (event) {
                  setState(() {
                    overlayHovered = false;
                  });
                  handleHideOverlay();
                },
                child: widget.menuBuilder?.call(context),
              ),
            ));
      },
    );

    overlay.insert(entry!);
  }

  void _removeOverlay() {
    entry?.remove();
    entry = null;
  }

  Widget buildContent() {
    return AnimatedContainer(
      color: hovered || overlayHovered
          ? material.Theme.of(context).hoverColor
          : material.Colors.transparent,
      duration: const Duration(milliseconds: 100),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.replySenderName != null) replyText(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatar(),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.showSender)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
                            child: Row(
                              children: [
                                senderName(),
                                timeStamp(),
                              ],
                            ),
                          ),
                        body(),
                        if (widget.edited) edited()
                      ],
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget avatar() {
    return SizedBox(
      width: widget.avatarSize,
      height: widget.showSender ? widget.avatarSize : 0,
      child: widget.showSender
          ? Avatar(
              radius: widget.avatarSize / 2,
              placeholderText: widget.senderName,
              image: widget.senderAvatar,
            )
          : null,
    );
  }

  Widget senderName() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
      child: SizedBox(
        child: tiamat.Text.name(
          widget.senderName,
          color: widget.senderColor,
        ),
      ),
    );
  }

  Widget replyText() {
    return SizedBox(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: widget.avatarSize,
          ),
          const Icon(material.Icons.keyboard_arrow_right_rounded),
          tiamat.Text.name(
            widget.replySenderName!,
            color: widget.replySenderColor,
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
              child: tiamat.Text(
                widget.replyBody ?? "Unknown",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                color: material.Theme.of(context).colorScheme.secondary,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget timeStamp() {
    return AnimatedOpacity(
      opacity: hovered ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
        child: SizedBox(
          child: tiamat.Text.labelLow(
              TextUtils.timestampToLocalizedTime(widget.sentTimeStamp)),
        ),
      ),
    );
  }

  Widget body() {
    return widget.body;
  }

  Widget edited() {
    return tiamat.Text.labelLow(T.current.messageEditedMarker);
  }

  Widget reactions() {
    return const Placeholder(
      fallbackHeight: 30,
    );
  }
}
