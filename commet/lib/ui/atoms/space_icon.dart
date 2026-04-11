import 'dart:async';

import 'package:commet/client/space.dart';
import 'package:commet/ui/atoms/notification_badge.dart';
import 'package:commet/ui/organisms/side_navigation_bar/side_navigation_bar.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';

class SpaceIcon extends StatefulWidget {
  const SpaceIcon(
      {super.key,
      this.width = 44,
      this.onTap,
      this.showUser = false,
      this.onUpdate,
      required this.spaceId,
      this.avatar,
      this.placeholderColor,
      this.notificationCount = 0,
      this.highlightedNotificationCount = 0,
      required this.displayName,
      this.userAvatar,
      this.userDisplayName,
      this.userColor});
  final double width;
  final void Function()? onTap;
  final bool showUser;
  final String spaceId;
  final Stream<void>? onUpdate;
  final String displayName;
  final Color? placeholderColor;
  final int notificationCount;
  final int highlightedNotificationCount;
  final ImageProvider? avatar;
  final ImageProvider? userAvatar;
  final String? userDisplayName;
  final Color? userColor;

  @override
  State<SpaceIcon> createState() => _SpaceIconState();
}

class _SpaceIconState extends State<SpaceIcon> {
  StreamSubscription? subscription;
  StreamSubscription? spaceSelectionSub;
  @override
  void initState() {
    subscription = widget.onUpdate?.listen((event) {
      setState(() {});
    });

    spaceSelectionSub =
        EventBus.onSelectedSpaceChanged.stream.listen(onSelectedSpaceChanged);

    super.initState();
  }

  bool selected = false;

  void onSelectedSpaceChanged(Space? event) {
    setState(() {
      selected = event?.identifier == widget.spaceId;
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    spaceSelectionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      SideNavigationBar.tooltip(
          widget.displayName,
          ImageButton(
            border: selected
                ? Border.all(
                    color: ColorScheme.of(context).inverseSurface,
                    width: 3,
                    strokeAlign: 0.5)
                : null,
            image: widget.avatar,
            onTap: widget.onTap,
            size: widget.width,
            placeholderColor: widget.placeholderColor,
            placeholderText: widget.displayName,
          ),
          context),
      if (widget.showUser) avatarOverlay(),
      if (widget.highlightedNotificationCount > 0) notificationOverlay(),
    ]);
  }

  Positioned avatarOverlay() {
    return Positioned(
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: SizedBox(
          width: 20,
          height: 20,
          child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black, blurRadius: 4)
                ],
              ),
              child: Avatar(
                radius: 10,
                image: widget.userAvatar,
                placeholderColor: widget.userColor,
                placeholderText: widget.userDisplayName,
              )),
        ),
      ),
    );
  }

  Positioned notificationOverlay() {
    return Positioned(
      right: 0,
      top: 0,
      child: SizedBox(
        width: 20,
        height: 20,
        child: NotificationBadge(widget.highlightedNotificationCount),
      ),
    );
  }

  Positioned messageOverlay() {
    return Positioned(
      left: 0,
      child: SizedBox(
        width: 8,
        height: 8,
        child: DecoratedBox(
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface,
              borderRadius: BorderRadius.circular(5)),
        ),
      ),
    );
  }
}
