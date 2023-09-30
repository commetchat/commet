import 'dart:async';

import 'package:commet/ui/atoms/notification_badge.dart';
import 'package:commet/ui/organisms/side_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';

class SpaceIcon extends StatefulWidget {
  const SpaceIcon(
      {super.key,
      this.width = 44,
      this.onTap,
      this.showUser = false,
      this.onUpdate,
      this.avatar,
      this.placeholderColor,
      this.notificationCount = 0,
      this.highlightedNotificationCount = 0,
      required this.displayName,
      this.userAvatar});
  final double width;
  final void Function()? onTap;
  final bool showUser;
  final Stream<void>? onUpdate;
  final String displayName;
  final Color? placeholderColor;
  final int notificationCount;
  final int highlightedNotificationCount;
  final ImageProvider? avatar;
  final ImageProvider? userAvatar;

  @override
  State<SpaceIcon> createState() => _SpaceIconState();
}

class _SpaceIconState extends State<SpaceIcon> {
  StreamSubscription? subscription;

  @override
  void initState() {
    subscription = widget.onUpdate?.listen((event) {
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      SideNavigationBar.tooltip(
          widget.displayName,
          ImageButton(
            image: widget.avatar,
            onTap: widget.onTap,
            size: widget.width,
            placeholderColor: widget.placeholderColor,
            placeholderText: widget.displayName,
          ),
          context),
      if (widget.showUser && widget.userAvatar != null) avatarOverlay(),
      if (widget.highlightedNotificationCount > 0) notificationOverlay(),
    ]);
  }

  Positioned avatarOverlay() {
    return Positioned(
      right: 0,
      bottom: 0,
      child: SizedBox(
        width: 20,
        height: 20,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 4)],
            image: DecorationImage(
                image: widget.userAvatar!, fit: BoxFit.fitHeight),
            //border: Border.all(color: Colors.white, width: 1)),
          ),
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
