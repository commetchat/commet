import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/ui/atoms/dot_indicator.dart';

import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';
import '../atoms/space_icon.dart';

class SpaceSelector extends StatefulWidget {
  const SpaceSelector(this.spaces,
      {super.key,
      this.onSelected,
      this.onSpaceInsert,
      this.onSpaceRemoved,
      this.clearSelection,
      required this.width,
      this.showSpaceOwnerAvatar = false,
      this.header,
      this.footer});
  final Stream<int>? onSpaceInsert;
  final Stream<int>? onSpaceRemoved;
  final List<Space> spaces;
  final bool showSpaceOwnerAvatar;
  final double width;
  final Widget? header;
  final Widget? footer;
  final void Function(int index)? onSelected;
  final void Function()? clearSelection;

  static EdgeInsets get padding => const EdgeInsets.fromLTRB(7, 0, 7, 0);

  @override
  State<SpaceSelector> createState() => _SpaceSelectorState();
}

class _SpaceSelectorState extends State<SpaceSelector> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  int _count = 0;

  StreamSubscription<int>? onInsertListener;
  StreamSubscription<int>? onRemovedListener;

  @override
  void initState() {
    onInsertListener = widget.onSpaceInsert?.listen((index) {
      _listKey.currentState?.insertItem(index);
      _count++;
    });

    onRemovedListener = widget.onSpaceRemoved?.listen((index) {
      var space = widget.spaces[index];
      var name = space.displayName;
      var avatar = space.avatar;
      setState(() {
        _listKey.currentState?.removeItem(
            index,
            (context, animation) => buildSpaceIcon(
                  animation,
                  displayName: name,
                  avatar: avatar,
                ));
      });
    });

    _count = widget.spaces.length;
    super.initState();
  }

  @override
  void dispose() {
    onInsertListener?.cancel();
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
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
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
                    AnimatedList(
                        key: _listKey,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        initialItemCount: _count,
                        itemBuilder: (context, i, animation) => buildSpaceIcon(
                              animation,
                              displayName: widget.spaces[i].displayName,
                              onUpdate: widget.spaces[i].onUpdate,
                              avatar: widget.spaces[i].avatar,
                              notificationCount:
                                  widget.spaces[i].displayNotificationCount,
                              highlightedNotificationCount: widget.spaces[i]
                                  .displayHighlightedNotificationCount,
                              userAvatar: widget.spaces[i].client.self!.avatar,
                              index: i,
                            )),
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

  Widget buildSpaceIcon(Animation<double> animation,
      {required String displayName,
      Stream<void>? onUpdate,
      ImageProvider? avatar,
      ImageProvider? userAvatar,
      int highlightedNotificationCount = 0,
      int notificationCount = 0,
      int? index}) {
    return ScaleTransition(
      scale: animation,
      child: Stack(
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
                highlightedNotificationCount: highlightedNotificationCount,
                notificationCount: notificationCount,
                width: widget.width,
                onTap: () {
                  if (index != null) {
                    widget.onSelected?.call(index);
                  }
                },
                showUser: widget.showSpaceOwnerAvatar,
              ),
            ),
          ),
          if (notificationCount > 0) messageOverlay()
        ],
      ),
    );
  }

  Widget messageOverlay() {
    return const Positioned(left: -6, child: DotIndicator());
  }
}
