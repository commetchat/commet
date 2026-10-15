import 'dart:async';
import 'dart:math';

import 'package:commet/client/components/user_presence/user_presence_component.dart';
import 'package:commet/client/member.dart';
import 'package:commet/ui/atoms/dot_indicator.dart';
import 'package:commet/ui/atoms/notification_badge.dart';
import 'package:commet/ui/atoms/shimmer_loading.dart';
import 'package:commet/ui/molecules/typing_indicators_widget.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomPanelView extends StatefulWidget {
  const RoomPanelView(
      {required this.displayName,
      this.avatar,
      this.onPrimaryButtonPressed,
      this.primaryButtonLabel,
      this.onSecondaryButtonPressed,
      this.secondaryButtonLabel,
      this.userColor,
      this.onTap,
      this.color,
      this.body,
      this.recentEventSender,
      this.recentEventSenderColor,
      this.userAvatar,
      this.loading = false,
      this.directMessagePartner,
      this.random = 1,
      this.userDisplayName,
      this.userPresence,
      this.showUserAvatar = false,
      this.notificationCount = 0,
      this.highlightNotificationCount = 0,
      this.typingMembers,
      super.key});
  final ImageProvider? avatar;
  final ImageProvider? userAvatar;
  final Color? userColor;
  final String? userDisplayName;
  final String displayName;
  final Color? color;
  final String? body;
  final String? recentEventSender;
  final Color? recentEventSenderColor;
  final String? primaryButtonLabel;
  final Future<void> Function()? onPrimaryButtonPressed;
  final Function()? onTap;
  final String? secondaryButtonLabel;
  final Future<void> Function()? onSecondaryButtonPressed;
  final bool showUserAvatar;
  final List<Member>? typingMembers;
  final bool loading;
  final String? directMessagePartner;
  final double random;
  final int notificationCount;
  final int highlightNotificationCount;
  final UserPresence? userPresence;
  @override
  State<RoomPanelView> createState() => _RoomPanelViewState();
}

class _RoomPanelViewState extends State<RoomPanelView> {
  bool get showPrimaryButton =>
      widget.primaryButtonLabel != null &&
      widget.onPrimaryButtonPressed != null;

  bool get showSecondaryButton =>
      widget.secondaryButtonLabel != null &&
      widget.onSecondaryButtonPressed != null;

  bool get showOnlyPrimaryButton => showPrimaryButton && !showSecondaryButton;

  bool get showAnyButton => showPrimaryButton || showSecondaryButton;

  bool primaryButtonLoading = false;
  bool secondaryButtonLoading = false;

  @override
  void initState() {
    if (widget.typingMembers?.isNotEmpty == true) {
      startTimer();
    }

    super.initState();
  }

  @override
  void didUpdateWidget(covariant RoomPanelView oldWidget) {
    if (widget.typingMembers?.isNotEmpty == true) {
      startTimer();
    } else {
      timer?.cancel();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    var shimmerColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    bool shimmer = widget.loading;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Shimmer(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            child: Container(
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  ShimmerLoading(
                                    isLoading: widget.loading,
                                    child: Stack(
                                      alignment: AlignmentGeometry.bottomRight,
                                      children: [
                                        Padding(
                                          padding: EdgeInsetsGeometry.all(3),
                                          child: Avatar(
                                            radius: 17,
                                            image: widget.avatar,
                                            placeholderText: shimmer
                                                ? " "
                                                : widget.displayName,
                                            placeholderColor: shimmer
                                                ? shimmerColor
                                                : widget.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  typingIndicators(),
                                  if (widget.showUserAvatar)
                                    Avatar(
                                      radius: 10,
                                      image: widget.userAvatar,
                                      placeholderText: widget.userDisplayName,
                                      placeholderColor: widget.userColor,
                                    ),
                                ],
                              ),
                              Flexible(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(4, 0, 8, 0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (shimmer)
                                        ShimmerLoading(
                                          isLoading: shimmer,
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                0, 4, 0, 0),
                                            child: Container(
                                              height: 16,
                                              width: (widget.random * 80) + 20,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  color: shimmerColor),
                                            ),
                                          ),
                                        ),
                                      if (shimmer)
                                        ShimmerLoading(
                                          isLoading: shimmer,
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                0, 4, 0, 0),
                                            child: Container(
                                              height: 12,
                                              width: (widget.random * 200) + 20,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  color: shimmerColor),
                                            ),
                                          ),
                                        ),
                                      if (!shimmer)
                                        tiamat.Text.labelEmphasised(
                                          widget.displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      if (widget.body != null)
                                        SizedBox(
                                            height: 16, child: recentEvent()),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.notificationCount > 0 &&
                            widget.highlightNotificationCount == 0)
                          const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: DotIndicator(),
                          ),
                        if (widget.highlightNotificationCount > 0)
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: NotificationBadge(
                                widget.highlightNotificationCount),
                          ),
                        if (showAnyButton) actionButtons(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  late List<GlobalKey> blobKeys = [
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
  ];

  Timer? timer;

  int prevIndex = 0;
  void startTimer() {
    onTimer();
    timer?.cancel();
    timer = Timer.periodic(const Duration(milliseconds: 250), (_) => onTimer());
  }

  void onTimer() {
    var r = Random().nextInt(3);

    if (r == prevIndex) {
      r += 1;
      r = r % blobKeys.length;
    }

    prevIndex = r;

    var key = blobKeys[r];

    if (key.currentState == null) {
      return;
    }

    var state = key.currentState! as SingleTypingIndicatorBlobState;
    state.controller.forward(from: 0);
  }

  Widget typingIndicators() {
    var color = widget.userPresence?.status.getColor();
    var border = null;
    var expanded = widget.typingMembers?.isNotEmpty == true;
    var backgroundColor = ColorScheme.of(context).surfaceContainer;
    if (!expanded && color == null) {
      color = Colors.transparent;
      backgroundColor = Colors.transparent;
    }

    var duration =
        expanded ? Duration(seconds: 1) : Duration(milliseconds: 300);
    var curve = expanded ? Curves.elasticOut : Curves.easeInOutCubic;

    var offset = expanded ? 7.0 : 0.0;
    var rightPad = 2.0;
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      width: (expanded ? 23 : 10) + rightPad,
      decoration: BoxDecoration(
          color: backgroundColor, borderRadius: BorderRadius.circular(5)),
      height: 12,
      child: Stack(
        alignment: AlignmentGeometry.center,
        children: [
          AnimatedPositioned(
              duration: duration,
              right: rightPad,
              curve: curve,
              child: SingleTypingIndicatorBlob(
                key: blobKeys[0],
                border: border,
                color: color,
                playing: expanded,
              )),
          AnimatedPositioned(
              duration: duration,
              right: rightPad + offset,
              curve: curve,
              child: SingleTypingIndicatorBlob(
                key: blobKeys[1],
                border: border,
                color: color,
                playing: expanded,
              )),
          AnimatedPositioned(
              duration: duration,
              right: rightPad + (offset * 2),
              curve: curve,
              child: SingleTypingIndicatorBlob(
                key: blobKeys[2],
                border: border,
                color: color,
                playing: expanded,
              )),
        ],
      ),
    );
  }

  Widget recentEvent() {
    var color = widget.recentEventSenderColor != null
        ? tiamat.Text.adjustColor(context, widget.recentEventSenderColor!)
        : null;

    var style = TextTheme.of(context)
        .labelMedium
        ?.copyWith(fontSize: 12, letterSpacing: 0);
    return SizedBox(
      child: RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(children: [
            if (widget.recentEventSender != null)
              TextSpan(
                text: widget.recentEventSender! + ":",
                style: style?.copyWith(color: color),
              ),
            if (widget.recentEventSender != null)
              WidgetSpan(
                  child: SizedBox(
                width: 4,
              )),
            TextSpan(
                text: widget.body,
                style:
                    style?.copyWith(color: ColorScheme.of(context).secondary))
          ])),
    );
  }

  Widget actionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showPrimaryButton)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
            child: Button(
              text: widget.primaryButtonLabel!,
              isLoading: primaryButtonLoading,
              onTap: () async {
                setState(() {
                  primaryButtonLoading = true;
                });
                await widget.onPrimaryButtonPressed?.call();

                if (mounted) {
                  setState(() {
                    primaryButtonLoading = false;
                  });
                }
              },
            ),
          ),
        if (showSecondaryButton)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
            child: Button.secondary(
              text: widget.secondaryButtonLabel!,
              isLoading: secondaryButtonLoading,
              onTap: () async {
                setState(() {
                  secondaryButtonLoading = true;
                });

                await widget.onSecondaryButtonPressed?.call();
                if (mounted) {
                  setState(() {
                    secondaryButtonLoading = false;
                  });
                }
              },
            ),
          ),
      ],
    );
  }
}
