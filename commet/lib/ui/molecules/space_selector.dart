import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/stale_info.dart';
import 'package:commet/config/app_config.dart';

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
  final Stream<StaleSpaceInfo>? onSpaceRemoved;
  final List<Space> spaces;
  final bool showSpaceOwnerAvatar;
  final double width;
  final Widget? header;
  final Widget? footer;
  final void Function(int index)? onSelected;
  final void Function()? clearSelection;

  @override
  State<SpaceSelector> createState() => _SpaceSelectorState();
}

class _SpaceSelectorState extends State<SpaceSelector> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  int _count = 0;
  int _selectedIndex = -1;

  late StreamSubscription<int>? onInsertListener;
  late StreamSubscription<StaleSpaceInfo>? onRemovedListener;

  @override
  void initState() {
    onInsertListener = widget.onSpaceInsert?.listen((index) {
      _listKey.currentState?.insertItem(index);
      _count++;
    });

    onRemovedListener = widget.onSpaceRemoved?.listen((info) {
      setState(() {
        if (info.index == _selectedIndex) widget.clearSelection?.call();
        _listKey.currentState?.removeItem(
            info.index,
            (context, animation) =>
                buildSpaceIcon(animation, displayName: info.name!, avatar: info.avatar, userAvatar: info.userAvatar));
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
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(s(7), 0, s(7), 0),
        child: Column(
          children: [
            Flexible(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(0, s(8), 0, s(8)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.header != null) widget.header!,
                        if (widget.header != null) const Seperator(),
                        AnimatedList(
                            key: _listKey,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            initialItemCount: _count,
                            itemBuilder: (context, i, animation) => buildSpaceIcon(
                                  animation,
                                  displayName: widget.spaces[i].displayName,
                                  onUpdate: widget.spaces[i].onUpdate.stream,
                                  avatar: widget.spaces[i].avatarThumbnail,
                                  userAvatar: widget.spaces[i].client.user!.avatar,
                                  index: i,
                                )),
                        if (widget.footer != null) const Seperator(),
                        if (widget.footer != null) widget.footer!,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSpaceIcon(Animation<double> animation,
      {required String displayName,
      Stream<void>? onUpdate,
      ImageProvider? avatar,
      ImageProvider? userAvatar,
      int? index}) {
    return ScaleTransition(
      scale: animation,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
        child: SpaceIcon(
          displayName: displayName,
          onUpdate: onUpdate,
          avatar: avatar,
          userAvatar: userAvatar,
          width: widget.width,
          onTap: () {
            if (index != null) {
              setState(() {
                _selectedIndex = index;
              });
              widget.onSelected?.call(index);
            }
          },
          showUser: widget.showSpaceOwnerAvatar,
        ),
      ),
    );
  }
}
