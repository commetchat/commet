import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/ui/atoms/dot_indicator.dart';
import 'package:commet/utils/scaled_app.dart';

import 'package:flutter/material.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import 'package:tiamat/tiamat.dart';
import '../atoms/space_icon.dart';

class SpaceSelector extends StatefulWidget {
  const SpaceSelector(this.spaces,
      {super.key,
      this.onSelected,
      this.clearSelection,
      required this.width,
      this.shouldShowAvatarForSpace,
      this.header,
      this.footer});
  final List<Space> spaces;
  final double width;
  final Widget? header;
  final Widget? footer;
  final void Function(Space space)? onSelected;
  final void Function()? clearSelection;
  final bool Function(Space space)? shouldShowAvatarForSpace;

  static EdgeInsets get padding => const EdgeInsets.fromLTRB(7, 0, 7, 0);

  @override
  State<SpaceSelector> createState() => _SpaceSelectorState();
}

class _SpaceSelectorState extends State<SpaceSelector> {
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
    return Column(
      children: [
        Flexible(
          child: ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    0, 0, 0, MediaQuery.of(context).scale().padding.bottom),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.header != null)
                      Padding(
                        padding: SpaceSelector.padding,
                        child: widget.header!,
                      ),
                    if (widget.header != null) const Seperator(),
                    ImplicitlyAnimatedList(
                      itemData: widget.spaces,
                      shrinkWrap: true,
                      initialAnimation: false,
                      padding: const EdgeInsets.all(0),
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, data) {
                        return buildSpaceIcon(
                          space: data,
                          displayName: data.displayName,
                          onUpdate: data.onUpdate,
                          avatar: data.avatar,
                          notificationCount: data.displayNotificationCount,
                          highlightedNotificationCount:
                              data.displayHighlightedNotificationCount,
                          userAvatar: data.client.self!.avatar,
                          userColor: data.client.self!.defaultColor,
                          userDisplayName: data.client.self!.displayName,
                          placeholderColor: data.color,
                        );
                      },
                    ),
                    if (widget.footer != null) const Seperator(),
                    if (widget.footer != null)
                      Padding(
                        padding: SpaceSelector.padding,
                        child: widget.footer!,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSpaceIcon(
      {required String displayName,
      Stream<void>? onUpdate,
      ImageProvider? avatar,
      ImageProvider? userAvatar,
      Color? userColor,
      String? userDisplayName,
      Color? placeholderColor,
      int highlightedNotificationCount = 0,
      int notificationCount = 0,
      required Space space}) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Padding(
          padding: SpaceSelector.padding,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
            child: SpaceIcon(
              displayName: displayName,
              onUpdate: onUpdate,
              avatar: avatar,
              userAvatar: userAvatar,
              userColor: userColor,
              userDisplayName: userDisplayName,
              highlightedNotificationCount: highlightedNotificationCount,
              notificationCount: notificationCount,
              width: widget.width,
              placeholderColor: placeholderColor,
              onTap: () {
                widget.onSelected?.call(space);
              },
              showUser: widget.shouldShowAvatarForSpace?.call(space) ?? false,
            ),
          ),
        ),
        if (notificationCount > 0) messageOverlay()
      ],
    );
  }

  Widget messageOverlay() {
    return const Positioned(left: -6, child: DotIndicator());
  }
}
