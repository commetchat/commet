import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/config/app_config.dart';

import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';
import '../atoms/space_icon.dart';

class SpaceSelector extends StatefulWidget {
  SpaceSelector(this.spaces,
      {super.key,
      this.onSelected,
      this.onSpaceInsert,
      required this.width,
      this.showSpaceOwnerAvatar = false,
      this.header,
      this.footer});
  Stream<int>? onSpaceInsert;
  List<Space> spaces;
  bool showSpaceOwnerAvatar;
  double width;
  @override
  State<SpaceSelector> createState() => _SpaceSelectorState();
  Widget? header;
  Widget? footer;
  void Function(int index)? onSelected;
}

class _SpaceSelectorState extends State<SpaceSelector> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  int _count = 0;

  late StreamSubscription<int>? onInsertListener;

  @override
  void initState() {
    onInsertListener = widget.onSpaceInsert?.listen((index) {
      _listKey.currentState?.insertItem(index);
      _count++;
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
    return Tile.low4(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(s(7), 0, s(7), 0),
          child: Column(
            children: [
              Flexible(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, s(8), 0, s(8)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.header != null) widget.header!,
                          if (widget.header != null) Seperator(),
                          AnimatedList(
                            key: _listKey,
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            initialItemCount: _count,
                            itemBuilder: (context, i, animation) => ScaleTransition(
                              scale: animation,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
                                child: SpaceIcon(
                                  widget.spaces[i],
                                  width: widget.width,
                                  onTap: () => widget.onSelected?.call(i),
                                  showUser: widget.showSpaceOwnerAvatar,
                                ),
                              ),
                            ),
                          ),
                          if (widget.footer != null) Seperator(),
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
      ),
    );
  }
}
