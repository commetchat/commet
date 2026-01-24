import 'dart:async'; // For StreamSubscription

import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/components/user_presence/user_presence_component.dart';
import 'package:commet/main.dart'; // For preferences
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../client/client.dart';

class RoomHeader extends StatefulWidget {
  const RoomHeader(this.room, {super.key, this.onTap, this.menu});
  final Room room;
  final Widget? menu;
  final Function()? onTap;

  @override
  State<RoomHeader> createState() => _RoomHeaderState();
}

class _RoomHeaderState extends State<RoomHeader> {
  late List<StreamSubscription> _subs;
  UserPresenceStatus? status;
  String? directMessagePartner;

  UserPresenceComponent? presence;

  @override
  void initState() {
    super.initState();

    final comp = widget.room.client.getComponent<DirectMessagesComponent>();
    bool isDm = comp?.isRoomDirectMessage(widget.room) == true;

    if (isDm) {
      status = UserPresenceStatus.unknown;
      presence = widget.room.client.getComponent<UserPresenceComponent>();
      directMessagePartner = comp!.getDirectMessagePartnerId(widget.room);
    }

    if (presence != null && directMessagePartner != null) {
      presence!.getUserPresence(directMessagePartner!).then((presence) {
        if (mounted) {
          setState(() {
            status = presence.status;
          });
        }
      });
    }

    _subs = [
      preferences.onSettingChanged.listen((_) {
        if (mounted) {
          setState(() {});
        }
      }),
      if (presence != null)
        presence!.onPresenceChanged.listen(onUserPresenceChanged),
    ];
  }

  @override
  void dispose() {
    for (var sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }

  void onUserPresenceChanged((String, UserPresence) event) {
    if (event.$1 == directMessagePartner) {
      setState(() {
        status = event.$2.status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool showRoomIcons = preferences.showRoomAvatars;
    bool useGenericIcons = preferences.usePlaceholderRoomAvatars;

    bool shouldShowDefaultIcon = (!showRoomIcons && !useGenericIcons) ||
        (showRoomIcons && !useGenericIcons && widget.room.avatar == null);
    IconData defaultIcon = widget.room.icon;

    Widget iconWidget;
    if (shouldShowDefaultIcon) {
      iconWidget = m.Icon(
        defaultIcon,
        size: 25,
      );
    } else {
      iconWidget = tiamat.Avatar(
        radius: 15,
        image: showRoomIcons && widget.room.avatar != null
            ? widget.room.avatar
            : null,
        placeholderText:
            (showRoomIcons && useGenericIcons && widget.room.avatar == null) ||
                    (!showRoomIcons && useGenericIcons)
                ? widget.room.displayName
                : "",
        placeholderColor:
            (showRoomIcons && useGenericIcons && widget.room.avatar == null) ||
                    (!showRoomIcons && useGenericIcons)
                ? widget.room.defaultColor
                : m.Colors.grey,
      );
    }

    return m.Material(
      color: m.Colors.transparent,
      child: m.InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      child: Stack(
                        alignment: AlignmentGeometry.bottomRight,
                        children: [
                          iconWidget,
                          if (status != null)
                            UserPanelView.createPresenceIcon(context, status!),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Flexible(
                      child: ClipRect(
                        child: Row(
                          textBaseline: TextBaseline.alphabetic,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          children: [
                            m.Text(
                              widget.room.displayName,
                              style: m.Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                      color: IconTheme.of(context).color),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.room.topic != null &&
                                widget.room.topic!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                                child: tiamat.Text.labelLow("—"),
                              ),
                            if (widget.room.topic != null &&
                                widget.room.topic!.isNotEmpty)
                              Flexible(
                                child: tiamat.Text.labelLow(
                                  widget.room.topic!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              if (widget.menu != null) widget.menu!
            ],
          ),
        ),
      ),
    );
  }
}
