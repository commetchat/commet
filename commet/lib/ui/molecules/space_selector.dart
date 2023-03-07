import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/config/style/theme_extensions.dart';
import 'package:commet/ui/atoms/seperator.dart';
import 'package:commet/ui/atoms/side_panel_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:provider/provider.dart';

import '../atoms/space_icon.dart';

class SpaceSelector extends StatefulWidget {
  SpaceSelector(this.spaces,
      {super.key, this.onSelected, this.onSpaceInsert, this.showSpaceOwnerAvatar = false, this.header, this.footer});
  Stream<int>? onSpaceInsert;
  List<Space> spaces;
  bool showSpaceOwnerAvatar;
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
    return Container(
      color: Theme.of(context).extension<ExtraColors>()!.surfaceLow3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 0, 7, 0),
        child: Column(
          children: [
            Flexible(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
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
                            child: SpaceIcon(
                              widget.spaces[i],
                              onTap: () => widget.onSelected?.call(i),
                              showUser: widget.showSpaceOwnerAvatar,
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
    );
  }
}
