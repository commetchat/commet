import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/user_presence/user_presence_component.dart';
import 'package:commet/client/member.dart';
import 'package:commet/ui/atoms/shimmer_loading.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/organisms/user_profile/user_profile.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class UserPanel extends material.StatefulWidget {
  const UserPanel(
      {super.key,
      required this.userId,
      required this.client,
      required this.contextRoom,
      this.initialMember,
      this.isDirectMessage = false,
      this.onTap});
  final String userId;
  final Client client;
  final Member? initialMember;
  final Room contextRoom;
  final bool isDirectMessage;
  final void Function()? onTap;

  @override
  State<UserPanel> createState() => _UserPanelState();
}

class _UserPanelState extends material.State<UserPanel> {
  late String displayName;
  late Color color;
  ImageProvider? avatar;
  String? detail;
  TextStyle? detailStringStyle;
  late UserPresence presence;

  StreamSubscription? sub;

  @override
  initState() {
    presence = UserPresence(UserPresenceStatus.unknown);

    super.initState();
    initPresence();
    getInfoFromMember();
  }

  void getInfoFromMember() {
    if (widget.isDirectMessage) {
      displayName = widget.contextRoom.displayName;
      color = widget.contextRoom.defaultColor;
      avatar = widget.contextRoom.avatar;
      return;
    }

    final member = widget.initialMember ??
        widget.contextRoom.getMemberOrFallback(widget.userId);
    displayName = member.displayName;
    color = member.defaultColor;
    avatar = member.avatar;
    detail = member.detail;
  }

  @override
  void didUpdateWidget(covariant UserPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    getInfoFromMember();
  }

  @override
  dispose() {
    super.dispose();
    sub?.cancel();
  }

  initPresence() async {
    final presenceComponent =
        widget.client.getComponent<UserPresenceComponent>();

    if (presenceComponent == null) {
      return;
    }

    sub = presenceComponent.onPresenceChanged
        .where((tuple) => tuple.$1 == widget.userId)
        .listen(onChanged);

    final p = await presenceComponent.getUserPresence(widget.userId);

    if (mounted) {
      setState(() {
        presence = p;
      });
    }
  }

  @override
  material.Widget build(material.BuildContext context) {
    TextStyle? style;

    var currentStyle = material.Theme.of(context).textTheme.bodyMedium;
    style = currentStyle?.copyWith(fontSize: 10);

    if (presence.message != null) {
      style = style?.copyWith(
        fontWeight: FontWeight.w500,
      );
    } else {
      style = style?.copyWith(
        color: Theme.of(context).colorScheme.secondary,
      );
    }

    return UserPanelView(
      displayName: displayName,
      avatar: avatar,
      detail: presence.message != null ? presence.message!.message : detail,
      detailStringStyle: style,
      color: color,
      avatarColor: color,
      nameColor: widget.isDirectMessage ? null : color,
      avatarSize: widget.isDirectMessage ? 20 : 15,
      detailIcon: presence.message != null ? Icons.chat_bubble : null,
      presenceStatus: presence.status,
      onClicked: widget.onTap ?? onUserPanelClicked,
    );
  }

  void onUserPanelClicked() {
    AdaptiveDialog.show(context,
        builder: (_) => UserProfile(
              userId: widget.userId,
              client: widget.client,
              dismiss: () => Navigator.pop(context),
            ),
        title: "User");
  }

  void onChanged((String, UserPresence) event) {
    if (mounted) {
      setState(() {
        presence = event.$2;
      });
    }
  }
}

class UserPanelView extends material.StatelessWidget {
  const UserPanelView(
      {super.key,
      this.avatar,
      required this.displayName,
      this.color,
      this.avatarColor,
      this.nameColor,
      this.detail,
      this.padding,
      this.shimmer = false,
      this.random = 0,
      this.detailStringStyle,
      this.detailIcon,
      this.presenceStatus,
      this.avatarSize = 15,
      this.onClicked});
  final ImageProvider? avatar;
  final String displayName;
  final double avatarSize;
  final Color? color;
  final Color? avatarColor;
  final Color? nameColor;
  final String? detail;
  final EdgeInsets? padding;
  final UserPresenceStatus? presenceStatus;
  final bool shimmer;
  final TextStyle? detailStringStyle;
  final double random;
  final IconData? detailIcon;
  final void Function()? onClicked;

  @override
  Widget build(BuildContext context) {
    var shimmerColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    var widget = ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: material.Material(
        color: material.Colors.transparent,
        child: material.InkWell(
          splashColor: material.Theme.of(context).highlightColor,
          onTap: onClicked,
          child: Padding(
            padding: padding ?? const EdgeInsets.fromLTRB(4, 2, 4, 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                material.Stack(
                  alignment: AlignmentGeometry.bottomRight,
                  children: [
                    Avatar(
                      radius: avatarSize,
                      image: shimmer ? null : avatar,
                      placeholderText: shimmer ? " " : displayName,
                      placeholderColor: shimmer ? shimmerColor : avatarColor,
                    ),
                    if (presenceStatus != null) createPresenceIcon(context),
                  ],
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisSize: material.MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (shimmer)
                            Container(
                              height: 10,
                              width: (random * 50) + 50,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: shimmerColor),
                            ),
                          if (shimmer)
                            material.Padding(
                              padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                              child: Container(
                                height: 8,
                                width: (random * 20) + 20,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: shimmerColor),
                              ),
                            ),
                          if (!shimmer)
                            tiamat.Text.name(
                              displayName,
                              color: nameColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (detail != null)
                            material.Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (detailIcon != null)
                                  material.Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 0, 4, 0),
                                    child: Icon(
                                      detailIcon,
                                      size: 10,
                                    ),
                                  ),
                                Flexible(
                                  child: material.Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 0, 0, 2),
                                    child: buildDetailString(),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );

    if (shimmer) {
      return ShimmerLoading(isLoading: true, child: widget);
    }

    return widget;
  }

  material.DecoratedBox createPresenceIcon(BuildContext context) {
    var scheme = Theme.of(context).colorScheme;

    var backgroundColor = scheme.surfaceContainer;

    var color = switch (presenceStatus!) {
      UserPresenceStatus.offline => Colors.grey,
      UserPresenceStatus.online => Colors.lightGreen,
      UserPresenceStatus.unavailable => Colors.amber,
      UserPresenceStatus.unknown => Colors.grey,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
            width: 2,
            strokeAlign: BorderSide.strokeAlignOutside,
            color: backgroundColor),
      ),
      child: SizedBox(
        width: 8,
        height: 8,
      ),
    );
  }

  Widget buildDetailString() {
    if (detailStringStyle == null) {
      return tiamat.Text.labelLow(detail!);
    }

    return material.Text(
      detail!,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: detailStringStyle,
    );
  }
}
